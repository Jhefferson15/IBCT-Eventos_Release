import '../models/activity_log.dart';

abstract class IActivityLogRepository {
  Future<void> logActivity(ActivityLog log);
  Future<List<ActivityLog>> getLogs({String? userId, int limit = 50});
}

