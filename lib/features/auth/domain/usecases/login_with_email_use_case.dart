import 'package:ibct_eventos/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:ibct_eventos/features/users/domain/repositories/user_repository.dart';
import 'package:ibct_eventos/features/users/domain/models/activity_log.dart';
import 'package:ibct_eventos/features/users/domain/usecases/log_activity_use_case.dart';
import 'login_result.dart';

class LoginWithEmailUseCase {
  final IAuthRepository _authRepository;
  final UserRepository _userRepository;
  final LogActivityUseCase _logActivityUseCase;

  LoginWithEmailUseCase(
    this._authRepository,
    this._userRepository,
    this._logActivityUseCase,
  );

  Future<LoginResult> call(String email, String password) async {
    try {
      final authUser = await _authRepository.signInWithEmailAndPassword(email, password);
      
      // Log Login Activity
      await _logActivityUseCase.call(
        userId: authUser.uid,
        actionType: ActivityActionType.login,
        targetId: authUser.uid,
        targetType: 'user',
        details: {'method': 'email'},
      );

      final userProfile = await _userRepository.getUser(authUser.uid);
      
      if (userProfile != null && userProfile.isFirstLogin) {
        return LoginResult.firstLogin(authUser.uid);
      } else {
        return LoginResult.success(authUser.uid);
      }
    } catch (e) {
      // In a real app, map specific exceptions (e.g., FirebaseAuthException) to user-friendly messages here
      // For now, we clean up the message string slightly if needed
      return LoginResult.error(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
