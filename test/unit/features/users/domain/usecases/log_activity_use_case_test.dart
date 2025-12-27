import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/features/users/domain/models/activity_log.dart';
import 'package:ibct_eventos/features/users/domain/repositories/activity_log_repository_interface.dart';
import 'package:ibct_eventos/features/users/domain/usecases/log_activity_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockActivityLogRepository extends Mock implements IActivityLogRepository {}

class FakeActivityLog extends Fake implements ActivityLog {}

void main() {
  late MockActivityLogRepository mockRepository;
  late LogActivityUseCase useCase;

  setUpAll(() {
    registerFallbackValue(FakeActivityLog());
  });

  setUp(() {
    mockRepository = MockActivityLogRepository();
    useCase = LogActivityUseCase(mockRepository);
  });

  group('LogActivityUseCase', () {
    test('should call repository with correct log', () async {
      // Arrange
      const userId = 'user_123';
      const actionType = ActivityActionType.createEvent;
      const targetId = 'target_123';
      const targetType = 'event';
      final details = {'title': 'Test Event'};

      when(() => mockRepository.logActivity(any())).thenAnswer((_) async {});

      // Act
      await useCase(
        userId: userId,
        actionType: actionType,
        targetId: targetId,
        targetType: targetType,
        details: details,
      );

      // Assert
      verify(() => mockRepository.logActivity(any(that: predicate<ActivityLog>((log) {
        return log.userId == userId &&
            log.actionType == actionType &&
            log.targetId == targetId &&
            log.targetType == targetType &&
            log.details['title'] == 'Test Event';
      })))).called(1);
    });

    test('should not log if userId is empty', () async {
      // Arrange
      const userId = '';
      const actionType = ActivityActionType.createEvent;
      const targetId = 'target_123';
      const targetType = 'event';
      final details = {'title': 'Test Event'};

      // Act
      await useCase(
        userId: userId,
        actionType: actionType,
        targetId: targetId,
        targetType: targetType,
        details: details,
      );

      // Assert
      verifyNever(() => mockRepository.logActivity(any()));
    });
  });
}
