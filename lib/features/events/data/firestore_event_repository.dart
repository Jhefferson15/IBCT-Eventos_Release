
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/interfaces/database_repository.dart';
import '../../../../core/utils/crashlytics_helper.dart';
import '../domain/models/event_model.dart';
import 'models/event_dto.dart'; // Import DTO

class FirestoreEventRepository implements DatabaseRepository<Event> {
  final FirebaseFirestore _firestore;
  final CrashlyticsHelper _crashlytics;
  final String _collection = 'events';

  FirestoreEventRepository([FirebaseFirestore? firestore, CrashlyticsHelper? crashlytics])
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _crashlytics = crashlytics ?? CrashlyticsHelper();

  @override
  @override
  Future<List<Event>> getItems() async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return EventDto.fromMap(doc.data(), doc.id);
    }).toList();
  }

  @override
  Future<Event?> getItem(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists && doc.data() != null) {
      return EventDto.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  @override
  Future<String> createItem(Event item) async {
    try {
      final dto = EventDto.fromDomain(item);
      final ref = await _firestore.collection(_collection).add(dto.toMap());
      await _crashlytics.log("Event created locally (and syncing): ${item.title}");
      return ref.id;
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack, reason: 'Error creating event');
      rethrow;
    }
  }

  @override
  Future<void> updateItem(Event item) async {
    try {
      if (item.id == null) throw Exception("Event ID is null");
      final dto = EventDto.fromDomain(item);
      await _firestore.collection(_collection).doc(item.id).update(dto.toMap());
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack, reason: 'Error updating event');
      rethrow;
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack, reason: 'Error deleting event');
      rethrow;
    }
  }

  @override
  Stream<List<Event>> watchItems() {
    return _firestore
        .collection(_collection)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EventDto.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}

