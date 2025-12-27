
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/activity_log.dart';
import 'models/activity_log_dto.dart'; // Import DTO

import '../domain/repositories/activity_log_repository_interface.dart';

class FirestoreActivityLogRepository implements IActivityLogRepository {
  final FirebaseFirestore _firestore;

  FirestoreActivityLogRepository(this._firestore);

  CollectionReference get _logsCollection => _firestore.collection('activity_logs');

  @override
  Future<void> logActivity(ActivityLog log) async {
    try {
      final dto = ActivityLogDto.fromDomain(log);
      await _logsCollection.doc(log.id).set(dto.toMap());
    } catch (e) {
      debugPrint("Error logging activity: $e");
      // Fail silently for logs to not disrupt main flow, but print error
    }
  }

  @override
  Future<List<ActivityLog>> getLogs({String? userId, int limit = 50}) async {
    try {
      Query query = _logsCollection.orderBy('timestamp', descending: true);

      if (userId != null) {
        // Query for both new 'userId' field and old 'adminId' field
        // Note: Firestore doesn't support OR queries across different fields easily without composite indices/extra work.
        // For simplicity during migration, we'll just check userId.
        query = query.where('userId', isEqualTo: userId);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map((doc) {
        return ActivityLogDto.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      debugPrint("Error fetching logs: $e");
      return [];
    }
  }
}
