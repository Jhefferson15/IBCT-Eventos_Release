import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/features/checkin/presentation/providers/checkin_controller.dart';
import 'package:ibct_eventos/features/editor/domain/models/participant_model.dart';
import 'package:ibct_eventos/features/editor/domain/repositories/participant_repository_interface.dart';
import 'package:ibct_eventos/features/editor/presentation/providers/participant_providers.dart';
import 'package:ibct_eventos/features/users/domain/usecases/log_activity_use_case.dart';
import 'package:ibct_eventos/features/users/presentation/providers/activity_log_provider.dart';
import 'package:ibct_eventos/features/users/presentation/providers/user_providers.dart';
import 'package:ibct_eventos/features/users/domain/models/app_user.dart';
import 'package:ibct_eventos/features/users/domain/models/activity_log.dart';
import 'package:mocktail/mocktail.dart';

class MockParticipantRepository extends Mock implements IParticipantRepository {}
class MockLogActivityUseCase extends Mock implements LogActivityUseCase {}
class FakeParticipant extends Fake implements Participant {}

void main() {
  late MockParticipantRepository mockRepository;
  late MockLogActivityUseCase mockLogUseCase;
  late Participant tParticipant;

  setUpAll(() {
    registerFallbackValue(FakeParticipant());
    registerFallbackValue(ActivityActionType.checkInParticipant);
  });

  setUp(() {
    mockRepository = MockParticipantRepository();
    mockLogUseCase = MockLogActivityUseCase();
    tParticipant = Participant(
      id: 'p1',
      eventId: 'e1',
      name: 'John',
      email: 'john@test.com',
      phone: '123456',
      ticketType: 'VIP',
      status: 'pending',
      token: 'valid_token',
      customFields: {},
    );
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        participantRepositoryProvider.overrideWithValue(mockRepository),
        logActivityUseCaseProvider.overrideWithValue(mockLogUseCase),
        currentUserProvider.overrideWithValue(const AsyncData(null)), // Default no user, override in test if needed
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('CheckinController', () {
    test('initial state should be CheckinIdle', () {
      final container = makeContainer();
      expect(container.read(checkinControllerProvider), isA<CheckinIdle>());
    });

    test('validateAndCheckIn should succeed for valid not-checked-in participant', () async {
      when(() => mockRepository.getParticipantByToken('valid_token'))
          .thenAnswer((_) async => tParticipant);
      when(() => mockRepository.checkInParticipant('p1'))
          .thenAnswer((_) async {});

      final container = makeContainer();
      final controller = container.read(checkinControllerProvider.notifier);

      await controller.validateAndCheckIn('valid_token');

      verify(() => mockRepository.getParticipantByToken('valid_token')).called(1);
      verify(() => mockRepository.checkInParticipant('p1')).called(1);

      final state = container.read(checkinControllerProvider);
      expect(state, isA<CheckinSuccess>());
      expect((state as CheckinSuccess).alreadyCheckedIn, false);
      expect(state.participant.isCheckedIn, true);
    });

    test('validateAndCheckIn should succeed (already checked in) for checked-in participant', () async {
      final checkedInParticipant = tParticipant.copyWith(isCheckedIn: true);
      when(() => mockRepository.getParticipantByToken('valid_token'))
          .thenAnswer((_) async => checkedInParticipant);

      final container = makeContainer();
      final controller = container.read(checkinControllerProvider.notifier);

      await controller.validateAndCheckIn('valid_token');

      verify(() => mockRepository.getParticipantByToken('valid_token')).called(1);
      verifyNever(() => mockRepository.checkInParticipant(any()));

      final state = container.read(checkinControllerProvider);
      expect(state, isA<CheckinSuccess>());
      expect((state as CheckinSuccess).alreadyCheckedIn, true);
    });

    test('validateAndCheckIn should set CheckinError for invalid token', () async {
      when(() => mockRepository.getParticipantByToken('invalid_token'))
          .thenAnswer((_) async => null);

      final container = makeContainer();
      final controller = container.read(checkinControllerProvider.notifier);

      await controller.validateAndCheckIn('invalid_token');

      verify(() => mockRepository.getParticipantByToken('invalid_token')).called(1);
      verifyNever(() => mockRepository.checkInParticipant(any()));

      final state = container.read(checkinControllerProvider);
      expect(state, isA<CheckinError>());
      expect((state as CheckinError).message, 'Código Inválido');
    });

    test('validateAndCheckIn should set CheckinError on repository failure', () async {
      when(() => mockRepository.getParticipantByToken('valid_token'))
          .thenThrow(Exception('Database down'));

      final container = makeContainer();
      final controller = container.read(checkinControllerProvider.notifier);

      await controller.validateAndCheckIn('valid_token');

      final state = container.read(checkinControllerProvider);
      expect(state, isA<CheckinError>());
      expect((state as CheckinError).message, contains('Erro ao validar ticket'));
    });

    test('validateAndCheckIn should log activity when user is logged in', () async {
       when(() => mockRepository.getParticipantByToken('valid_token'))
          .thenAnswer((_) async => tParticipant);
      when(() => mockRepository.checkInParticipant('p1'))
          .thenAnswer((_) async {});
      
      when(() => mockLogUseCase.call(
        userId: any(named: 'userId'),
        actionType: any(named: 'actionType'),
        targetId: any(named: 'targetId'),
        targetType: any(named: 'targetType'),
        details: any(named: 'details'),
      )).thenAnswer((_) async {});

      final testUser = AppUser(
        id: 'admin_1',
        email: 'admin@test.com',
        name: 'Admin',
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          participantRepositoryProvider.overrideWithValue(mockRepository),
          logActivityUseCaseProvider.overrideWithValue(mockLogUseCase),
          currentUserProvider.overrideWithValue(AsyncData(testUser)),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(checkinControllerProvider.notifier);
      await controller.validateAndCheckIn('valid_token');

      verify(() => mockLogUseCase.call(
        userId: 'admin_1',
        actionType: ActivityActionType.checkInParticipant,
        targetId: 'p1',
        targetType: 'participant',
        details: any(named: 'details'),
      )).called(1);
    });
  });
}
