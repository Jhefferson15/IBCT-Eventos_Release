import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/features/editor/domain/repositories/participant_repository_interface.dart';
import 'package:ibct_eventos/features/editor/domain/usecases/delete_participants_usecase.dart';
import 'package:ibct_eventos/features/users/domain/models/activity_log.dart';
import 'package:ibct_eventos/features/users/domain/usecases/log_activity_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockParticipantRepository extends Mock implements IParticipantRepository {}
class MockLogActivityUseCase extends Mock implements LogActivityUseCase {}

void main() {
  late MockParticipantRepository mockRepository;
  late MockLogActivityUseCase mockLogActivityUseCase;
  late DeleteParticipantsUseCase useCase;

  setUpAll(() {
    registerFallbackValue(ActivityActionType.deleteParticipant);
  });

  setUp(() {
    mockRepository = MockParticipantRepository();
    mockLogActivityUseCase = MockLogActivityUseCase();
    useCase = DeleteParticipantsUseCase(mockRepository, mockLogActivityUseCase);

    when(() => mockLogActivityUseCase.call(
      userId: any(named: 'userId'),
      actionType: any(named: 'actionType'),
      targetId: any(named: 'targetId'),
      targetType: any(named: 'targetType'),
      details: any(named: 'details'),
    )).thenAnswer((_) async {});
  });

  const tIds = ['p1', 'p2', 'p3'];
  const tEventId = 'e1';
  const tUserId = 'admin_1';

  test('should delete participants batch and log activity', () async {
    // Arrange
    when(() => mockRepository.deleteItemsBatch(any())).thenAnswer((_) async {});

    // Act
    await useCase(tIds, tEventId, tUserId);

    // Assert
    verify(() => mockRepository.deleteItemsBatch(tIds)).called(1);
    verify(() => mockLogActivityUseCase.call(
      userId: tUserId,
      actionType: ActivityActionType.deleteParticipant,
      targetId: any(named: 'targetId'),
      targetType: 'participants_bulk',
      details: any(named: 'details'),
    )).called(1);
  });

  test('should do nothing if ids list is empty', () async {
    // Act
    await useCase([], tEventId, tUserId);

    // Assert
    verifyNever(() => mockRepository.deleteItemsBatch(any()));
    verifyNever(() => mockLogActivityUseCase.call(
      userId: any(named: 'userId'),
      actionType: any(named: 'actionType'),
      targetId: any(named: 'targetId'),
      targetType: any(named: 'targetType'),
      details: any(named: 'details'),
    ));
  });

  test('should throw error if repository fails', () async {
    // Arrange
    when(() => mockRepository.deleteItemsBatch(any())).thenThrow(Exception('DB Error'));

    // Act & Assert
    expect(() => useCase(tIds, tEventId, tUserId), throwsException);
  });
}
