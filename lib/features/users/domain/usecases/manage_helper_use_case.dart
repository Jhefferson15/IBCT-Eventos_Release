import '../models/app_user.dart';
import '../repositories/user_repository.dart';
import '../models/activity_log.dart';
import 'log_activity_use_case.dart';

class ManageHelperUseCase {
  final UserRepository _repository;
  final LogActivityUseCase _logActivityUseCase;

  ManageHelperUseCase(this._repository, this._logActivityUseCase);

  Future<void> updateUser(AppUser user, String adminId) async {
    await _repository.updateUser(user);
    await _logActivityUseCase.call(
      userId: adminId,
      actionType: ActivityActionType.profileUpdate,
      targetId: user.id,
      targetType: 'user',
      details: {'email': user.email, 'name': user.name},
    );
  }

  Future<void> deleteUser(AppUser user, String adminId) async {
    await _repository.deleteUser(user.id);
    await _logActivityUseCase.call(
      userId: adminId,
      actionType: ActivityActionType.removeHelper,
      targetId: user.id,
      targetType: 'user',
      details: {'email': user.email, 'name': user.name},
    );
  }
}
