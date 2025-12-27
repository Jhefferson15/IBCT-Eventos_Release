import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/feedback_model.dart';
import '../../domain/repositories/feedback_repository_interface.dart';

class FeedbackRepositoryImpl implements FeedbackRepositoryInterface {
  final FirebaseFirestore _firestore;

  FeedbackRepositoryImpl(this._firestore);

  @override
  Future<void> submitFeedback(FeedbackModel feedback) async {
    try {
      await _firestore.collection('feedback').doc(feedback.id).set(feedback.toMap());
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }
}
