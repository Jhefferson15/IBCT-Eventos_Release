import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/feedback_repository_impl.dart';
import '../../domain/repositories/feedback_repository_interface.dart';
import '../../domain/usecases/submit_feedback_use_case.dart';
import '../../domain/models/feedback_model.dart';
import '../../../users/presentation/providers/user_providers.dart';

// DI Providers - ideally move to a feedback_di.dart or similar but keeping here for now to minimize file sprawl if not needed
final feedbackRepositoryProvider = Provider<FeedbackRepositoryInterface>((ref) {
  return FeedbackRepositoryImpl(FirebaseFirestore.instance);
});

final submitFeedbackUseCaseProvider = Provider<SubmitFeedbackUseCase>((ref) {
  return SubmitFeedbackUseCase(ref.read(feedbackRepositoryProvider));
});

final feedbackControllerProvider = AsyncNotifierProvider<FeedbackController, void>(FeedbackController.new);

class FeedbackController extends AsyncNotifier<void> {
  
  @override
  FutureOr<void> build() {
    // Initial state is null (void)
    return null;
  }

  Future<void> submitFeedback({required String message, required String type}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(submitFeedbackUseCaseProvider);
      final userState = ref.read(currentUserProvider);
      final user = userState.value;
      
      if (user == null) {
        throw Exception('User not logged in');
      }

      final feedback = FeedbackModel(
        id: const Uuid().v4(),
        userId: user.id,
        userEmail: user.email,
        message: message,
        timestamp: DateTime.now(),
        type: type,
      );

      await useCase.call(feedback);
    });
  }
}
