import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/activity_log.dart';

class ActivityLogDto extends ActivityLog {
  ActivityLogDto({
    required super.id,
    required super.userId,
    required super.actionType,
    required super.targetId,
    required super.targetType,
    required super.details,
    required super.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'actionType': actionType.name,
      'targetId': targetId,
      'targetType': targetType,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ActivityLogDto.fromMap(Map<String, dynamic> map, String id) {
    return ActivityLogDto(
      id: id,
      userId: map['userId'] ?? map['adminId'] ?? '', // Fallback for old data
      actionType: ActivityActionType.values.firstWhere(
        (e) => e.name == map['actionType'],
        orElse: () => ActivityActionType.unknown,
      ),
      targetId: map['targetId'] ?? '',
      targetType: map['targetType'] ?? 'unknown',
      details: Map<String, dynamic>.from(map['details'] ?? {}),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  factory ActivityLogDto.fromDomain(ActivityLog log) {
    return ActivityLogDto(
      id: log.id,
      userId: log.userId,
      actionType: log.actionType,
      targetId: log.targetId,
      targetType: log.targetType,
      details: log.details,
      timestamp: log.timestamp,
    );
  }
}
