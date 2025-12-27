import 'package:ibct_eventos/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:ibct_eventos/features/users/domain/repositories/user_repository.dart';
import 'package:ibct_eventos/features/users/domain/models/activity_log.dart';
import 'package:ibct_eventos/features/users/domain/usecases/log_activity_use_case.dart';
import 'login_result.dart';

class LoginWithGoogleUseCase {
  final IAuthRepository _authRepository;
  final UserRepository _userRepository;
  final LogActivityUseCase _logActivityUseCase;

  LoginWithGoogleUseCase(
    this._authRepository,
    this._userRepository,
    this._logActivityUseCase,
  );

  Future<LoginResult> call() async {
    try {
      final authUser = await _authRepository.signInWithGoogle();
      
      if (authUser == null) {
        return LoginResult.cancelled();
      }

      // Log Login Activity
      await _logActivityUseCase.call(
        userId: authUser.uid,
        actionType: ActivityActionType.login,
        targetId: authUser.uid,
        targetType: 'user',
        details: {'method': 'google'},
      );

      // Check if first login
      final userProfile = await _userRepository.getUser(authUser.uid);
      
      if (userProfile != null && userProfile.isFirstLogin) {
        return LoginResult.firstLogin(authUser.uid);
      } else {
        return LoginResult.success(authUser.uid);
      }
    } catch (e) {
      return LoginResult.error(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
