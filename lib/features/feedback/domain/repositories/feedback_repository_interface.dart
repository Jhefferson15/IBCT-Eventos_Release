import '../models/feedback_model.dart';

abstract class FeedbackRepositoryInterface {
  Future<void> submitFeedback(FeedbackModel feedback);
}
