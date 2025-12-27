import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibct_eventos/features/auth/domain/usecases/login_with_google_use_case.dart';
import 'package:ibct_eventos/features/auth/domain/usecases/login_with_email_use_case.dart';
import 'package:ibct_eventos/features/auth/domain/usecases/login_result.dart' as domain;
import 'auth_providers.dart';


// Simple state to communicate result to UI
// LoginUIStatus enum ensures compatibility with existing UI
enum LoginUIStatus { initial, loading, success, firstLogin, error }

class LoginState {
  final LoginUIStatus status;
  final String? errorMessage;
  
  const LoginState({this.status = LoginUIStatus.initial, this.errorMessage});
}

class LoginController extends Notifier<LoginState> {
  late LoginWithGoogleUseCase _loginWithGoogleUseCase;
  late LoginWithEmailUseCase _loginWithEmailUseCase;

  @override
  LoginState build() {
    _loginWithGoogleUseCase = ref.watch(loginWithGoogleUseCaseProvider);
    _loginWithEmailUseCase = ref.watch(loginWithEmailUseCaseProvider);
    return const LoginState();
  }

  Future<void> signInWithGoogle() async {
    state = const LoginState(status: LoginUIStatus.loading);
    
    final result = await _loginWithGoogleUseCase.call();
    _handleResult(result);
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const LoginState(status: LoginUIStatus.loading);
    
    final result = await _loginWithEmailUseCase.call(email, password);
    _handleResult(result);
  }

  void _handleResult(domain.LoginResult result) {
    switch (result.status) {
      case domain.LoginStatus.success:
        state = const LoginState(status: LoginUIStatus.success);
        break;
      case domain.LoginStatus.firstLogin:
        state = const LoginState(status: LoginUIStatus.firstLogin);
        break;
      case domain.LoginStatus.cancelled:
        state = const LoginState(status: LoginUIStatus.initial);
        break;
      case domain.LoginStatus.error:
        state = LoginState(status: LoginUIStatus.error, errorMessage: result.errorMessage);
        break;
    }
  }
}

final loginControllerProvider = NotifierProvider<LoginController, LoginState>(LoginController.new);
