import '../models/feedback_model.dart';
import '../repositories/feedback_repository_interface.dart';

class SubmitFeedbackUseCase {
  final FeedbackRepositoryInterface _repository;

  SubmitFeedbackUseCase(this._repository);

  Future<void> call(FeedbackModel feedback) {
    return _repository.submitFeedback(feedback);
  }
}
