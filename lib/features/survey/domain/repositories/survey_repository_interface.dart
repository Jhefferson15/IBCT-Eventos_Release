import '../models/survey_model.dart';
import 'dart:async';

abstract class ISurveyRepository {
  Future<void> submitSurvey(SurveyResponse response);
}
