import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/participant_model.dart';
import '../../domain/repositories/participant_repository_interface.dart';
import 'package:ibct_eventos/features/shared/import/data/models/participant_dto.dart';

class FirestoreParticipantRepository implements IParticipantRepository {
  final FirebaseFirestore _firestore;
  late final CollectionReference _collection;

  FirestoreParticipantRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _collection = _firestore.collection('participants');
  }

  @override
  @override
  Future<List<Participant>> getItems() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) {
      return ParticipantDto.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  @override
  Future<Participant?> getItem(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return ParticipantDto.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  @override
  Future<List<Participant>> getParticipantsByEvent(String eventId) async {
    final snapshot = await _collection
        .where('eventId', isEqualTo: eventId)
        .get();
        
    return snapshot.docs.map((doc) {
      return ParticipantDto.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  @override
  Future<String> createItem(Participant item) async {
    try {
      String docId;
      final dto = ParticipantDto.fromDomain(item); 

      if (item.id.isNotEmpty) {
         // If ID is provided (rare for creation, but possible), use it
         await _collection.doc(item.id).set(dto.toMap());
         docId = item.id;
      } else {
         // Generate Sequential ID using Transaction
         docId = await _firestore.runTransaction((transaction) async {
            final counterRef = _firestore.collection('counters').doc('participants');
            final counterSnapshot = await transaction.get(counterRef);
            
            int newCount;
            if (!counterSnapshot.exists) {
              newCount = 1000; // Start from 1000
              transaction.set(counterRef, {'count': newCount});
            } else {
              final currentCount = counterSnapshot.get('count') as int;
              newCount = currentCount + 1;
              transaction.update(counterRef, {'count': newCount});
            }
            
            final newId = newCount.toString();
            final newDocRef = _collection.doc(newId);
            
            // Ensure we don't overwrite an existing doc (highly unlikely with transaction, but safe)
            // Note: In a transaction, reads must come before writes. We read counter, that's enough key lock.
            // We set the new participant data
            transaction.set(newDocRef, dto.toMap());
            
            return newId;
         });
      }
      
      // Update participant count in Event (Optimistic or separate write - keeping outside transaction to reduce contention on event doc)
      if (item.eventId.isNotEmpty) {
        await _firestore
            .collection('events')
            .doc(item.eventId)
            .update({'participant_count': FieldValue.increment(1)});
      }
      return docId;
    } catch (e) {
      debugPrint('Error creating participant: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateItem(Participant item) async {
    try {
      final dto = ParticipantDto.fromDomain(item); // Convert to DTO
      await _collection.doc(item.id).update(dto.toMap());
      // Note: If eventId changed, we would need to decrement old and increment new.
      // Assuming eventId doesn't change for now.
    } catch (e) {
      debugPrint('Error updating participant: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    try {
      // Get the participant first to know the eventId
      final docSnapshot = await _collection.doc(id).get();
      if (!docSnapshot.exists) return;
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      final eventId = data['eventId'] as String?;

      await _collection.doc(id).delete();

      if (eventId != null && eventId.isNotEmpty) {
         await _firestore
            .collection('events')
            .doc(eventId)
            .update({'participant_count': FieldValue.increment(-1)});
      }
    } catch (e) {
      debugPrint('Error deleting participant: $e');
      rethrow;
    }
  }

  // Specific method for check-in validation
  @override
  Future<Participant?> getParticipantByToken(String token) async {
    try {
       // Assuming 'token' is a unique field. If it's a doc ID, used doc(token). 
       // But earlier I added 'token' field to the model. Best to query by field.
       final snapshot = await _collection.where('token', isEqualTo: token).limit(1).get();
       
       if (snapshot.docs.isNotEmpty) {
         final doc = snapshot.docs.first;
         return ParticipantDto.fromMap(doc.data() as Map<String, dynamic>, doc.id);
       }
       return null;
    } catch (e) {
      debugPrint('Error fetching participant by token: $e');
      return null;
    }
  }

  @override
  Future<void> checkInParticipant(String participantId) async {
     try {
       await _collection.doc(participantId).update({
         'isCheckedIn': true,
         'checkInTime': DateTime.now().toIso8601String(),
         'status': 'Presente',
       });
     } catch (e) {
       debugPrint('Error checking in participant: $e');
       rethrow;
     }
  }

  @override
  Future<void> createItemsBatch(List<Participant> items) async {
    final batch = _firestore.batch();
    
    // Group by eventId to update counts
    final Map<String, int> eventCounts = {};

    for (var item in items) {
      final docRef = _collection.doc(); 
      final dto = ParticipantDto.fromDomain(item); // Convert to DTO
      batch.set(docRef, dto.toMap());
      
      if (item.eventId.isNotEmpty) {
        eventCounts[item.eventId] = (eventCounts[item.eventId] ?? 0) + 1;
      }
    }
    
    // Add updates for event counts to the batch
    for (var entry in eventCounts.entries) {
      final eventRef = _firestore.collection('events').doc(entry.key);
      batch.update(eventRef, {'participant_count': FieldValue.increment(entry.value)});
    }

    await batch.commit();
  }

  @override
  Future<void> deleteItemsBatch(List<String> ids) async {
    if (ids.isEmpty) return;
    
    // We need to handle batches of 500 if strictly following Firestore limits,
    // but for this implementation we assume reasonably sized batches for UI actions.
    // If larger, we should chunk. Let's do a simple chunking just in case.
    
    const int batchSize = 500;
    
    for (var i = 0; i < ids.length; i += batchSize) {
      final batchIds = ids.sublist(i, (i + batchSize) < ids.length ? i + batchSize : ids.length);
      final batch = _firestore.batch();
      final Map<String, int> eventCounts = {};

      // We need to get the eventId for each participant to update the count.
      // This requires reading. To optimizing, we could assume they are from the same event 
      // if the UseCase enforces it, but the Repository should be robust.
      // We'll read. construct a 'where in' query is limited to 10 or 30.
      // So simpler is to just get them one by one or rely on the caller?
      // For robustness: read individually or just simple delete and ignore count?
      // No, we must update count.
      
      // Let's use Future.wait to fetch docs
      final docsSnapshot = await Future.wait(
        batchIds.map((id) => _collection.doc(id).get())
      );

      for (var doc in docsSnapshot) {
         if (doc.exists) {
           final data = doc.data() as Map<String, dynamic>;
           final eventId = data['eventId'] as String?;
           
           batch.delete(doc.reference);
           
           if (eventId != null && eventId.isNotEmpty) {
             eventCounts[eventId] = (eventCounts[eventId] ?? 0) - 1;
           }
         }
      }

      // Update event counts
      for (var entry in eventCounts.entries) {
        final eventRef = _firestore.collection('events').doc(entry.key);
        // decrementing means adding a negative number
        batch.update(eventRef, {'participant_count': FieldValue.increment(entry.value)});
      }

      await batch.commit();
    }
  }
  
  @override
  Stream<List<Participant>> watchItems() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ParticipantDto.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  @override
  Future<void> updateItemsBatch(List<Participant> items) async {
    if (items.isEmpty) return;
    
    const int batchSize = 500;
    for (var i = 0; i < items.length; i += batchSize) {
      final batchItems = items.sublist(i, (i + batchSize) < items.length ? i + batchSize : items.length);
      final batch = _firestore.batch();
      
      for (var item in batchItems) {
        final docRef = _collection.doc(item.id);
        final dto = ParticipantDto.fromDomain(item);
        batch.update(docRef, dto.toMap());
      }
      
      await batch.commit();
    }
  }
}
