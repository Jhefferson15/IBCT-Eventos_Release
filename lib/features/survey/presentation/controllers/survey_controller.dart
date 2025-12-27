import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/di/firebase_providers.dart';
import '../../data/repositories/survey_repository.dart';
import '../../domain/models/survey_model.dart';
import '../../domain/repositories/survey_repository_interface.dart';
import '../../domain/usecases/submit_survey_usecase.dart';
import '../../../users/presentation/providers/user_providers.dart';
import 'package:ibct_eventos/features/users/domain/models/activity_log.dart';
import 'package:ibct_eventos/features/users/presentation/providers/activity_log_provider.dart';

final surveyRepositoryProvider = Provider<ISurveyRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return SurveyRepository(firestore);
});

final submitSurveyUseCaseProvider = Provider<SubmitSurveyUseCase>((ref) {
  final repository = ref.watch(surveyRepositoryProvider);
  return SubmitSurveyUseCase(repository);
});

final surveyControllerProvider = AsyncNotifierProvider<SurveyController, void>(SurveyController.new);

class SurveyController extends AsyncNotifier<void> {

  @override
  FutureOr<void> build() {
    return null;
  }

  Future<void> submitSurvey(Map<String, dynamic> answers) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final submitUseCase = ref.read(submitSurveyUseCaseProvider);
      final userState = ref.read(currentUserProvider);
      final user = userState.value;
      
      if (user == null) {
        throw Exception('User not logged in');
      }

      final survey = SurveyResponse(
        id: const Uuid().v4(),
        userId: user.id,
        userEmail: user.email,
        answers: answers,
        timestamp: DateTime.now(),
      );

      await submitUseCase(survey);
      
      // Log Activity
      try {
        await ref.read(logActivityUseCaseProvider).call(
          userId: user.id,
          actionType: ActivityActionType.surveyAnswer,
          targetId: survey.id,
          targetType: 'survey_response',
          details: {'email': user.email},
        );
      } catch (e) {
        // ignore
      }
    });
  }
}
