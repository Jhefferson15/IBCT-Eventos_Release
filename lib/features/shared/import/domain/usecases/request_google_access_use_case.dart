import 'package:googleapis_auth/googleapis_auth.dart';
import '../../../../auth/domain/repositories/auth_repository_interface.dart';

class RequestGoogleAccessUseCase {
  final IAuthRepository _authRepository;

  RequestGoogleAccessUseCase(this._authRepository);

  Future<AuthClient?> execute() async {
    return _authRepository.requestFormsAccess();
  }
}
