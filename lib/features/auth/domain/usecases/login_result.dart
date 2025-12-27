
enum LoginStatus {
  success,
  firstLogin,
  cancelled,
  error,
}

class LoginResult {
  final LoginStatus status;
  final String? errorMessage;
  final String? userId;

  const LoginResult({
    required this.status,
    this.errorMessage,
    this.userId,
  });

  factory LoginResult.success(String userId) => 
      LoginResult(status: LoginStatus.success, userId: userId);
      
  factory LoginResult.firstLogin(String userId) => 
      LoginResult(status: LoginStatus.firstLogin, userId: userId);
      
  factory LoginResult.cancelled() => 
      const LoginResult(status: LoginStatus.cancelled);
      
  factory LoginResult.error(String message) => 
      LoginResult(status: LoginStatus.error, errorMessage: message);
}
