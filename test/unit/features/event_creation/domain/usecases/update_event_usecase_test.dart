import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/core/interfaces/database_repository.dart';
import 'package:ibct_eventos/features/events/domain/models/event_model.dart';
import 'package:ibct_eventos/features/event_creation/domain/usecases/update_event_usecase.dart';
import 'package:ibct_eventos/features/users/domain/models/activity_log.dart';
import 'package:ibct_eventos/features/users/domain/usecases/log_activity_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements DatabaseRepository<Event> {}
class MockLogActivityUseCase extends Mock implements LogActivityUseCase {}
class FakeEvent extends Fake implements Event {}

void main() {
  late MockEventRepository mockRepository;
  late MockLogActivityUseCase mockLogActivityUseCase;
  late UpdateEventUseCase useCase;

  setUpAll(() {
    registerFallbackValue(FakeEvent());
    registerFallbackValue(ActivityActionType.updateEvent);
  });

  setUp(() {
    mockRepository = MockEventRepository();
    mockLogActivityUseCase = MockLogActivityUseCase();
    useCase = UpdateEventUseCase(mockRepository, mockLogActivityUseCase);

    when(() => mockLogActivityUseCase.call(
      userId: any(named: 'userId'),
      actionType: any(named: 'actionType'),
      targetId: any(named: 'targetId'),
      targetType: any(named: 'targetType'),
      details: any(named: 'details'),
    )).thenAnswer((_) async {});
  });

  final tEvent = Event(
    id: 'e1',
    title: 'Updated Event',
    date: DateTime.now(),
    description: 'Desc',
    location: 'Loc',
    creatorId: 'user1',
  );

  test('should update event and log activity', () async {
    // Arrange
    when(() => mockRepository.updateItem(any())).thenAnswer((_) async {});
    const tUserId = 'admin1';

    // Act
    await useCase(tEvent, tUserId);

    // Assert
    verify(() => mockRepository.updateItem(tEvent)).called(1);
    verify(() => mockLogActivityUseCase.call(
      userId: tUserId,
      actionType: ActivityActionType.updateEvent,
      targetId: tEvent.id!,
      targetType: 'event',
      details: any(named: 'details'),
    )).called(1);
  });

  test('should propagate repository errors', () async {
     // Arrange
    when(() => mockRepository.updateItem(any())).thenThrow(Exception('Update Failed'));
    const tUserId = 'admin1';

    // Act & Assert
    expect(() => useCase(tEvent, tUserId), throwsException);
  });
}
