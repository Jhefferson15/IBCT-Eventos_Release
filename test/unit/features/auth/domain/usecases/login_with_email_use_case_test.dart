import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/features/auth/domain/entities/auth_user.dart';
import 'package:ibct_eventos/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:ibct_eventos/features/auth/domain/usecases/login_result.dart';
import 'package:ibct_eventos/features/auth/domain/usecases/login_with_email_use_case.dart';
import 'package:ibct_eventos/features/users/domain/models/activity_log.dart';
import 'package:ibct_eventos/features/users/domain/models/app_user.dart';
import 'package:ibct_eventos/features/users/domain/repositories/user_repository.dart';
import 'package:ibct_eventos/features/users/domain/usecases/log_activity_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}
class MockUserRepository extends Mock implements UserRepository {}
class MockLogActivityUseCase extends Mock implements LogActivityUseCase {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockUserRepository mockUserRepository;
  late MockLogActivityUseCase mockLogActivityUseCase;
  late LoginWithEmailUseCase useCase;

  setUpAll(() {
    registerFallbackValue(ActivityActionType.login);
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUserRepository = MockUserRepository();
    mockLogActivityUseCase = MockLogActivityUseCase();
    useCase = LoginWithEmailUseCase(
      mockAuthRepository,
      mockUserRepository,
      mockLogActivityUseCase,
    );

    when(() => mockLogActivityUseCase.call(
      userId: any(named: 'userId'),
      actionType: any(named: 'actionType'),
      targetId: any(named: 'targetId'),
      targetType: any(named: 'targetType'),
      details: any(named: 'details'),
    )).thenAnswer((_) async {});
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tUserId = 'user_123';
  final tAuthUser = AuthUser(uid: tUserId, email: tEmail);
  final tAppUser = AppUser(
    id: tUserId,
    email: tEmail,
    name: 'Test User',
    role: UserRole.participant,
    createdAt: DateTime.now(),
  );

  test('should return success when login succeeds', () async {
    // Arrange
    when(() => mockAuthRepository.signInWithEmailAndPassword(tEmail, tPassword))
        .thenAnswer((_) async => tAuthUser);
    when(() => mockUserRepository.getUser(tUserId))
        .thenAnswer((_) async => tAppUser.copyWith(isFirstLogin: false));

    // Act
    final result = await useCase(tEmail, tPassword);

    // Assert
    expect(result.status, LoginStatus.success);
    
    verify(() => mockAuthRepository.signInWithEmailAndPassword(tEmail, tPassword)).called(1);
    verify(() => mockLogActivityUseCase.call(
      userId: tUserId,
      actionType: ActivityActionType.login,
      targetId: tUserId,
      targetType: 'user',
      details: {'method': 'email'},
    )).called(1);
  });

  test('should return error when login fails', () async {
    // Arrange
    when(() => mockAuthRepository.signInWithEmailAndPassword(tEmail, tPassword))
        .thenThrow(Exception('Invalid credentials'));

    // Act
    final result = await useCase(tEmail, tPassword);

    // Assert
    expect(result.status, LoginStatus.error);
    expect(result.errorMessage, contains('Invalid credentials'));
  });
}
