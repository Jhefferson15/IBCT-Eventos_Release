import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/features/users/domain/models/activity_log.dart';
import 'package:ibct_eventos/features/users/domain/repositories/activity_log_repository_interface.dart';
import 'package:ibct_eventos/features/users/domain/usecases/get_activity_logs_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockActivityLogRepository extends Mock implements IActivityLogRepository {}

void main() {
  late MockActivityLogRepository mockRepository;
  late GetActivityLogsUseCase useCase;

  setUp(() {
    mockRepository = MockActivityLogRepository();
    useCase = GetActivityLogsUseCase(mockRepository);
  });

  group('GetActivityLogsUseCase', () {
    test('should call repository with correct parameters', () async {
      // Arrange
      const userId = 'user_123';
      const limit = 20;
      final expectedLogs = [
        ActivityLog(
          id: '1',
          userId: userId,
          actionType: ActivityActionType.createEvent,
          targetId: 'target_1',
          targetType: 'event',
          details: {},
          timestamp: DateTime.now(),
        ),
      ];

      when(() => mockRepository.getLogs(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => expectedLogs);

      // Act
      final result = await useCase(userId: userId, limit: limit);

      // Assert
      expect(result, expectedLogs);
      verify(() => mockRepository.getLogs(userId: userId, limit: limit)).called(1);
    });

    test('should call repository with default limit when not provided', () async {
      // Arrange
      when(() => mockRepository.getLogs(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => []);

      // Act
      await useCase();

      // Assert
      verify(() => mockRepository.getLogs(userId: null, limit: 50)).called(1);
    });
  });
}
