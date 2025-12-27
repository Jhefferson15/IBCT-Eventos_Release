import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/core/interfaces/database_repository.dart';
import 'package:ibct_eventos/features/event_creation/domain/usecases/create_event_usecase.dart';
import 'package:ibct_eventos/features/events/domain/models/event_model.dart';
import 'package:ibct_eventos/features/users/domain/usecases/log_activity_use_case.dart';
import 'package:ibct_eventos/features/users/domain/models/activity_log.dart';
import 'package:mocktail/mocktail.dart';


class MockEventRepository extends Mock implements DatabaseRepository<Event> {}
class MockLogActivityUseCase extends Mock implements LogActivityUseCase {}
class FakeEvent extends Fake implements Event {}

void main() {
  late MockEventRepository mockRepository;
  late MockLogActivityUseCase mockLogUseCase;
  late CreateEventUseCase useCase;

  setUpAll(() {
    registerFallbackValue(FakeEvent());
    registerFallbackValue(ActivityActionType.createEvent);
  });

  setUp(() {
    mockRepository = MockEventRepository();
    mockLogUseCase = MockLogActivityUseCase();
    useCase = CreateEventUseCase(mockRepository, mockLogUseCase);

    when(() => mockLogUseCase.call(
      userId: any(named: 'userId'),
      actionType: any(named: 'actionType'),
      targetId: any(named: 'targetId'),
      targetType: any(named: 'targetType'),
      details: any(named: 'details'),
    )).thenAnswer((_) async {});
  });


  group('CreateEventUseCase', () {
    test('should create event and log activity', () async {
      final event = Event(
        id: '1',
        title: 'Title',
        date: DateTime.now(),
        creatorId: 'user1',
        description: 'Desc',
        location: 'Loc',
      );

      when(() => mockRepository.createItem(any())).thenAnswer((_) async => '1');

      await useCase.call(event, 'admin1');

      verify(() => mockRepository.createItem(any())).called(1);
      verify(() => mockLogUseCase.call(
        userId: 'admin1',
        actionType: ActivityActionType.createEvent,
        targetId: any(named: 'targetId'),
        targetType: 'event',
        details: any(named: 'details'),
      )).called(1);

    });

  });
}
