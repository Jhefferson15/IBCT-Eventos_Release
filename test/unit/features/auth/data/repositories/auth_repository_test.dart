import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ibct_eventos/core/utils/crashlytics_helper.dart';
import 'package:ibct_eventos/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ibct_eventos/features/auth/data/datasources/auth_remote_data_source.dart';

import 'package:mocktail/mocktail.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}
class MockAuthRemoteDataSource extends Mock implements IAuthRemoteDataSource {}
class MockCrashlyticsHelper extends Mock implements CrashlyticsHelper {}

void main() {
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late AuthRepositoryImpl repository;
  late MockCrashlyticsHelper mockCrashlytics;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockCrashlytics = MockCrashlyticsHelper();
    
    // Stub Crashlytics methods
    when(() => mockCrashlytics.setUserIdentifier(any())).thenAnswer((_) async {});
    when(() => mockCrashlytics.log(any())).thenAnswer((_) async {});
    when(() => mockCrashlytics.recordError(any(), any(), reason: any(named: 'reason'))).thenAnswer((_) async {});

    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
    );
  });

  group('AuthRepositoryImpl', () {
    test('signInWithEmailAndPassword should return AuthUser on success', () async {
      final mockUser = MockUser(uid: 'user_1', email: 'test@example.com');
      when(() => mockRemoteDataSource.signInWithEmailAndPassword(any(), any()))
          .thenAnswer((_) async => mockUser);

      final result = await repository.signInWithEmailAndPassword('test@example.com', 'password');

      expect(result.email, 'test@example.com');
      expect(result.uid, 'user_1');
    });

    test('signOut should call remote data source signOut', () async {
      when(() => mockRemoteDataSource.signOut()).thenAnswer((_) async {});
      await repository.signOut();
      verify(() => mockRemoteDataSource.signOut()).called(1);
    });

    test('authStateChanges should emit user updates', () async {
      final mockUser = MockUser(uid: 'user_1', email: 'test@example.com');
      when(() => mockRemoteDataSource.authStateChanges)
          .thenAnswer((_) => Stream.value(mockUser));
      
      expect(repository.authStateChanges, emits(isNotNull));
    });

    test('registerWithEmailAndPassword should return AuthUser on success', () async {
      final mockUser = MockUser(uid: 'user_2', email: 'new@example.com');
      when(() => mockRemoteDataSource.registerWithEmailAndPassword(any(), any()))
          .thenAnswer((_) async => mockUser);

      final result = await repository.registerWithEmailAndPassword('new@example.com', 'password');

      expect(result.email, 'new@example.com');
      expect(result.uid, 'user_2');
    });

    test('changePassword should call remote data source changePassword', () async {
      when(() => mockRemoteDataSource.changePassword(any())).thenAnswer((_) async {});
      await repository.changePassword('newPass');
      verify(() => mockRemoteDataSource.changePassword('newPass')).called(1);
    });
  });
}
