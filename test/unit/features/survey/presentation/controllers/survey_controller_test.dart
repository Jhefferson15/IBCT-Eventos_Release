import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/features/survey/domain/models/survey_model.dart';
import 'package:ibct_eventos/features/survey/domain/usecases/submit_survey_usecase.dart';
import 'package:ibct_eventos/features/survey/presentation/controllers/survey_controller.dart';
import 'package:ibct_eventos/features/users/domain/models/app_user.dart';
import 'package:ibct_eventos/features/users/presentation/providers/user_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockSubmitSurveyUseCase extends Mock implements SubmitSurveyUseCase {}
class FakeSurveyResponse extends Fake implements SurveyResponse {}

void main() {
  late MockSubmitSurveyUseCase mockUseCase;

  setUpAll(() {
    registerFallbackValue(FakeSurveyResponse());
  });

  setUp(() {
    mockUseCase = MockSubmitSurveyUseCase();
  });

  group('SurveyController', () {
    test('submitSurvey should call usecase and set state', () async {
      when(() => mockUseCase.call(any())).thenAnswer((_) async {});

      final testUser = AppUser(
        id: 'user1',
        email: 'test@test.com',
        name: 'Test',
        role: UserRole.participant,
        createdAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          submitSurveyUseCaseProvider.overrideWithValue(mockUseCase),
          currentUserProvider.overrideWithValue(AsyncData(testUser)),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(surveyControllerProvider.notifier);

      await controller.submitSurvey({'q1': 'a1'});

      verify(() => mockUseCase.call(any(that: predicate<SurveyResponse>((s) {
        return s.userId == 'user1' &&
               s.userEmail == 'test@test.com' &&
               s.answers['q1'] == 'a1';
      })))).called(1);

      final state = container.read(surveyControllerProvider);
      expect(state, const AsyncData<void>(null));
    });

    test('submitSurvey should set error if user not logged in', () async {
      final container = ProviderContainer(
        overrides: [
          submitSurveyUseCaseProvider.overrideWithValue(mockUseCase),
          currentUserProvider.overrideWithValue(const AsyncData(null)),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(surveyControllerProvider.notifier);

      await controller.submitSurvey({'q1': 'a1'});

      final state = container.read(surveyControllerProvider);
      expect(state, isA<AsyncError>());
      expect(state.error.toString(), contains('User not logged in'));
    });
  });
}
