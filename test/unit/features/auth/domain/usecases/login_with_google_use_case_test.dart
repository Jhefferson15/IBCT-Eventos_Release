import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/features/auth/domain/entities/auth_user.dart';
import 'package:ibct_eventos/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:ibct_eventos/features/auth/domain/usecases/login_result.dart';
import 'package:ibct_eventos/features/auth/domain/usecases/login_with_google_use_case.dart';
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
  late LoginWithGoogleUseCase useCase;

  setUpAll(() {
    registerFallbackValue(ActivityActionType.login);
  });
  
  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUserRepository = MockUserRepository();
    mockLogActivityUseCase = MockLogActivityUseCase();
    useCase = LoginWithGoogleUseCase(
      mockAuthRepository,
      mockUserRepository,
      mockLogActivityUseCase,
    );

    // Default stub for logging
    when(() => mockLogActivityUseCase.call(
      userId: any(named: 'userId'),
      actionType: any(named: 'actionType'),
      targetId: any(named: 'targetId'),
      targetType: any(named: 'targetType'),
      details: any(named: 'details'),
    )).thenAnswer((_) async {});
  });

  const tUserId = 'user_123';
  final tAuthUser = AuthUser(uid: tUserId, email: 'test@example.com');
  final tAppUser = AppUser(
    id: tUserId,
    email: 'test@example.com',
    name: 'Test User',
    role: UserRole.participant,
    createdAt: DateTime.now(),
  );

  test('should return success when login succeeds and user is not first login', () async {
    // Arrange
    when(() => mockAuthRepository.signInWithGoogle())
        .thenAnswer((_) async => tAuthUser);
    when(() => mockUserRepository.getUser(tUserId))
        .thenAnswer((_) async => tAppUser.copyWith(isFirstLogin: false));

    // Act
    final result = await useCase();

    // Assert
    expect(result.status, LoginStatus.success);
    expect(result.userId, tUserId);
    
    verify(() => mockAuthRepository.signInWithGoogle()).called(1);
    verify(() => mockLogActivityUseCase.call(
      userId: tUserId,
      actionType: ActivityActionType.login,
      targetId: tUserId,
      targetType: 'user',
      details: {'method': 'google'},
    )).called(1);
  });

  test('should return firstLogin when user has isFirstLogin true', () async {
    // Arrange
    when(() => mockAuthRepository.signInWithGoogle())
        .thenAnswer((_) async => tAuthUser);
    when(() => mockUserRepository.getUser(tUserId))
        .thenAnswer((_) async => tAppUser.copyWith(isFirstLogin: true));

    // Act
    final result = await useCase();

    // Assert
    expect(result.status, LoginStatus.firstLogin);
    expect(result.userId, tUserId);
  });

  test('should return cancelled when auth returns null', () async {
    // Arrange
    when(() => mockAuthRepository.signInWithGoogle())
        .thenAnswer((_) async => null);

    // Act
    final result = await useCase();

    // Assert
    expect(result.status, LoginStatus.cancelled);
    verifyNever(() => mockLogActivityUseCase.call(
      userId: any(named: 'userId'),
      actionType: any(named: 'actionType'),
      targetId: any(named: 'targetId'),
      targetType: any(named: 'targetType'),
      details: any(named: 'details'),
    ));
  });

  test('should return error when repository throws exception', () async {
    // Arrange
    when(() => mockAuthRepository.signInWithGoogle())
        .thenThrow(Exception('Network Error'));

    // Act
    final result = await useCase();

    // Assert
    expect(result.status, LoginStatus.error);
    expect(result.errorMessage, contains('Network Error'));
  });
}
