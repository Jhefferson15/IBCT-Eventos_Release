import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ibct_eventos/features/survey/domain/usecases/submit_survey_usecase.dart';
import 'package:ibct_eventos/features/survey/domain/models/survey_model.dart';
import '../../../../../mocks/mocks.dart';

void main() {
  late SubmitSurveyUseCase useCase;
  late MockSurveyRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(SurveyResponse(
      id: 'fake',
      userId: 'fake',
      userEmail: 'fake',
      answers: {},
      timestamp: DateTime.now(),
    ));
  });

  setUp(() {
    mockRepository = MockSurveyRepository();
    useCase = SubmitSurveyUseCase(mockRepository);
  });

  final tSurveyResponse = SurveyResponse(
    id: '1',
    userId: 'user123',
    userEmail: 'test@test.com',
    answers: {'q1': 'a1'},
    timestamp: DateTime(2023, 1, 1),
  );

  group('SubmitSurveyUseCase', () {
    test('should call submitSurvey on repository with correct data', () async {
      // Arrange
      when(() => mockRepository.submitSurvey(any()))
          .thenAnswer((_) async => {});
      
      // Act
      await useCase(tSurveyResponse);

      // Assert
      verify(() => mockRepository.submitSurvey(tSurveyResponse)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should throw an exception when repository fails', () async {
      // Arrange
      when(() => mockRepository.submitSurvey(any()))
          .thenThrow(Exception('Database error'));
      
      // Act & Assert
      expect(() => useCase(tSurveyResponse), throwsException);
    });
    group('Some grouped tests', () {
        // ... more tests if needed
    });
  });
}
