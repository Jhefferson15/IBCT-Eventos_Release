import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/features/editor/domain/models/participant_model.dart';

import 'package:ibct_eventos/features/editor/domain/repositories/participant_repository_interface.dart';
import 'package:ibct_eventos/features/editor/domain/usecases/update_participant_usecase.dart';
import 'package:ibct_eventos/features/users/domain/models/activity_log.dart';
import 'package:ibct_eventos/features/users/domain/usecases/log_activity_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockParticipantRepository extends Mock implements IParticipantRepository {}
class MockLogActivityUseCase extends Mock implements LogActivityUseCase {}
class FakeParticipant extends Fake implements Participant {}

void main() {
  late MockParticipantRepository mockRepository;
  late MockLogActivityUseCase mockLogActivityUseCase;
  late UpdateParticipantUseCase useCase;

  setUpAll(() {
    registerFallbackValue(FakeParticipant());
    registerFallbackValue(ActivityActionType.updateParticipant);
  });

  setUp(() {
    mockRepository = MockParticipantRepository();
    mockLogActivityUseCase = MockLogActivityUseCase();
    useCase = UpdateParticipantUseCase(mockRepository, mockLogActivityUseCase);

    when(() => mockLogActivityUseCase.call(
      userId: any(named: 'userId'),
      actionType: any(named: 'actionType'),
      targetId: any(named: 'targetId'),
      targetType: any(named: 'targetType'),
      details: any(named: 'details'),
    )).thenAnswer((_) async {});
  });

  final tParticipant = Participant(
    id: 'p1',
    eventId: 'e1',
    name: 'John Doe',
    email: 'john@example.com',
    phone: '123456789',
    ticketType: 'VIP',
    status: 'confirmed',
    token: 'token123',
    customFields: {},
  );

  test('should update participant and log activity', () async {
    // Arrange
    when(() => mockRepository.updateItem(any())).thenAnswer((_) async {});
    const tUserId = 'admin_1';

    // Act
    await useCase(tParticipant, tUserId);

    // Assert
    verify(() => mockRepository.updateItem(tParticipant)).called(1);
    verify(() => mockLogActivityUseCase.call(
      userId: tUserId,
      actionType: ActivityActionType.updateParticipant,
      targetId: tParticipant.id,
      targetType: 'participant',
      details: any(named: 'details'),
    )).called(1);
  });

  test('should throw error if repository fails', () async {
    // Arrange
    when(() => mockRepository.updateItem(any())).thenThrow(Exception('DB Error'));
    const tUserId = 'admin_1';

    // Act & Assert
    expect(() => useCase(tParticipant, tUserId), throwsException);
    
    // Should not log if update failed
    verifyNever(() => mockLogActivityUseCase.call(
      userId: any(named: 'userId'),
      actionType: any(named: 'actionType'),
      targetId: any(named: 'targetId'),
      targetType: any(named: 'targetType'),
      details: any(named: 'details'),
    ));
  });
}
