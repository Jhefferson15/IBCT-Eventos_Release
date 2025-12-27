import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/survey_model.dart';

import '../../domain/repositories/survey_repository_interface.dart';

class SurveyRepository implements ISurveyRepository {
  final FirebaseFirestore _firestore;

  SurveyRepository(this._firestore);

  @override
  Future<void> submitSurvey(SurveyResponse response) async {
    try {
      await _firestore.collection('surveys').doc(response.id).set(response.toMap());
    } catch (e) {
      throw Exception('Failed to submit survey: $e');
    }
  }
}
