import '../models/activity_log.dart';
import '../repositories/activity_log_repository_interface.dart';

class GetActivityLogsUseCase {
  final IActivityLogRepository _repository;

  GetActivityLogsUseCase(this._repository);

  Future<List<ActivityLog>> call({String? userId, int limit = 50}) {
    return _repository.getLogs(userId: userId, limit: limit);
  }
}
