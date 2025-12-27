import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository_interface.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final IAuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({
    required IAuthRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  AuthUser? _mapFirebaseUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }

  @override
  AuthUser? get currentUser => _mapFirebaseUser(_remoteDataSource.currentUser);

  @override
  Stream<AuthUser?> get authStateChanges =>
      _remoteDataSource.authStateChanges.map(_mapFirebaseUser);

  @override
  Future<AuthUser?> signInWithGoogle() async {
    final user = await _remoteDataSource.signInWithGoogle();
    return _mapFirebaseUser(user);
  }

  @override
  Future<AuthUser> signInWithEmailAndPassword(String email, String password) async {
    final user = await _remoteDataSource.signInWithEmailAndPassword(email, password);
    return _mapFirebaseUser(user)!;
  }

  @override
  Future<AuthUser> registerWithEmailAndPassword(String email, String password) async {
    final user = await _remoteDataSource.registerWithEmailAndPassword(email, password);
    return _mapFirebaseUser(user)!;
  }

  @override
  Future<void> changePassword(String newPassword) async {
    await _remoteDataSource.changePassword(newPassword);
  }

  @override
  Future<void> signOut() async {
    await _remoteDataSource.signOut();
  }

  @override
  Future<AuthClient?> requestFormsAccess() async {
    return await _remoteDataSource.requestFormsAccess();
  }

  @override
  Future<String> createSecondaryUser(String email, String password) async {
    return await _remoteDataSource.createSecondaryUser(email, password);
  }
}
