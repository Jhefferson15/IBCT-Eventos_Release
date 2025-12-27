import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/features/auth/domain/entities/auth_user.dart';
import 'package:ibct_eventos/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:ibct_eventos/features/auth/presentation/providers/auth_providers.dart';
import 'package:ibct_eventos/features/auth/presentation/providers/login_controller.dart';
import 'package:ibct_eventos/features/users/domain/models/app_user.dart';
import 'package:ibct_eventos/features/users/domain/models/activity_log.dart';
import 'package:ibct_eventos/features/users/domain/repositories/user_repository.dart';
import 'package:ibct_eventos/features/users/presentation/providers/user_di.dart';
import 'package:ibct_eventos/features/users/domain/usecases/log_activity_use_case.dart';
import 'package:ibct_eventos/features/users/presentation/providers/activity_log_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../utils/test_utils.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}
class MockUserRepository extends Mock implements UserRepository {}
class MockLogActivityUseCase extends Mock implements LogActivityUseCase {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockUserRepository mockUserRepository;
  late MockLogActivityUseCase mockLogActivityUseCase;
 
  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUserRepository = MockUserRepository();
    mockLogActivityUseCase = MockLogActivityUseCase();
    registerFallbackValue(ActivityActionType.login);
 
    // Default stub for logActivity
    when(() => mockLogActivityUseCase.call(
      userId: any(named: 'userId'),
      actionType: any(named: 'actionType'),
      targetId: any(named: 'targetId'),
      targetType: any(named: 'targetType'),
      details: any(named: 'details'),
    )).thenAnswer((_) async => {});
  });

  test('signInWithGoogle success should set status to success', () async {
    final authUser = AuthUser(uid: 'user_1', email: 'test@test.com');
    final appUser = AppUser(
      id: 'user_1',
      email: 'test@test.com',
      name: 'Test',
      role: UserRole.participant,
      createdAt: DateTime.now(),
      isFirstLogin: false,
    );

    when(() => mockAuthRepository.signInWithGoogle()).thenAnswer((_) async => authUser);
    when(() => mockUserRepository.getUser('user_1')).thenAnswer((_) async => appUser);

    final container = createContainer(overrides: [
      authRepositoryProvider.overrideWithValue(mockAuthRepository),
      userRepositoryProvider.overrideWithValue(mockUserRepository),
      logActivityUseCaseProvider.overrideWithValue(mockLogActivityUseCase),
    ]);

    await container.read(loginControllerProvider.notifier).signInWithGoogle();

    expect(
      container.read(loginControllerProvider),
      isA<LoginState>().having((s) => s.status, 'status', LoginUIStatus.success),
    );
  });

  test('signInWithGoogle first login should set status to firstLogin', () async {
    final authUser = AuthUser(uid: 'user_1', email: 'test@test.com');
    final appUser = AppUser(
      id: 'user_1',
      email: 'test@test.com',
      name: 'Test',
      role: UserRole.participant,
      createdAt: DateTime.now(),
      isFirstLogin: true,
    );

    when(() => mockAuthRepository.signInWithGoogle()).thenAnswer((_) async => authUser);
    when(() => mockUserRepository.getUser('user_1')).thenAnswer((_) async => appUser);

    final container = createContainer(overrides: [
      authRepositoryProvider.overrideWithValue(mockAuthRepository),
      userRepositoryProvider.overrideWithValue(mockUserRepository),
      logActivityUseCaseProvider.overrideWithValue(mockLogActivityUseCase),
    ]);

    await container.read(loginControllerProvider.notifier).signInWithGoogle();

    expect(
      container.read(loginControllerProvider),
      isA<LoginState>().having((s) => s.status, 'status', LoginUIStatus.firstLogin),
    );
  });
}
