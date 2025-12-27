import '../models/survey_model.dart';
import '../repositories/survey_repository_interface.dart';

class SubmitSurveyUseCase {
  final ISurveyRepository _repository;

  SubmitSurveyUseCase(this._repository);

  Future<void> call(SurveyResponse response) async {
    return _repository.submitSurvey(response);
  }
}
