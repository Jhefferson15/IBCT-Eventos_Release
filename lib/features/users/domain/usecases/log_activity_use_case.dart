import 'package:uuid/uuid.dart';
import '../models/activity_log.dart';
import '../repositories/activity_log_repository_interface.dart';

class LogActivityUseCase {
  final IActivityLogRepository _repository;
  final _uuid = const Uuid();

  LogActivityUseCase(this._repository);

  Future<void> call({
    required String userId,
    required ActivityActionType actionType,
    required String targetId,
    required String targetType,
    required Map<String, dynamic> details,
  }) async {
    if (userId.isEmpty) return;

    final log = ActivityLog(
      id: _uuid.v4(),
      userId: userId,
      actionType: actionType,
      targetId: targetId,
      targetType: targetType,
      details: details,
      timestamp: DateTime.now(),
    );

    await _repository.logActivity(log);
  }
}
