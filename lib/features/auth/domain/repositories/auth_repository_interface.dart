import '../entities/auth_user.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

abstract class IAuthRepository {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;
  Future<AuthUser?> signInWithGoogle();
  Future<AuthUser> signInWithEmailAndPassword(String email, String password);
  Future<AuthUser> registerWithEmailAndPassword(String email, String password);
  Future<void> changePassword(String newPassword);
  Future<void> signOut();
  Future<AuthClient?> requestFormsAccess();
  /// Creates a new user without signing out the current one. Returns the new User UID.
  Future<String> createSecondaryUser(String email, String password);
}
