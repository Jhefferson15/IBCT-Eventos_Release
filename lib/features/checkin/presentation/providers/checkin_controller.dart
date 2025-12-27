import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/editor/domain/models/participant_model.dart';
import '../../../../features/editor/presentation/providers/participant_providers.dart';
import '../../../../features/users/presentation/providers/activity_log_provider.dart';
import '../../../../features/users/presentation/providers/user_providers.dart';
import '../../domain/usecases/checkin_participant_usecase.dart';

// Dependency Injection for the Use Case
// Assuming participantRepositoryProvider implements ICheckinRepository or fits the shape.
// If not, we might need a specific provider for CheckinRepository. 
// For now, based on previous context, we'll try to use participantRepositoryProvider as source.
final checkInParticipantUseCaseProvider = Provider<CheckInParticipantUseCase>((ref) {
  final repository = ref.watch(participantRepositoryProvider); 
  final logActivityUseCase = ref.watch(logActivityUseCaseProvider);
  return CheckInParticipantUseCase(repository, logActivityUseCase);
});

sealed class CheckinState {
  const CheckinState();
}

class CheckinIdle extends CheckinState {
  const CheckinIdle();
}

class CheckinProcessing extends CheckinState {
  const CheckinProcessing();
}

class CheckinSuccess extends CheckinState {
  final Participant participant;
  final bool alreadyCheckedIn;
  const CheckinSuccess(this.participant, this.alreadyCheckedIn);
}

class CheckinError extends CheckinState {
  final String message;
  const CheckinError(this.message);
}

final checkinControllerProvider = NotifierProvider<CheckinController, CheckinState>(CheckinController.new);

class CheckinController extends Notifier<CheckinState> {
  @override
  CheckinState build() {
    return const CheckinIdle();
  }

  Future<void> validateAndCheckIn(String token) async {
    state = const CheckinProcessing();
    
    try {
      final useCase = ref.read(checkInParticipantUseCaseProvider);
      final currentUser = ref.read(currentUserProvider).value;

      final result = await useCase.call(CheckInParticipantParams(
        token: token,
        operatorId: currentUser?.id,
      ));

      state = CheckinSuccess(result.participant, result.alreadyCheckedIn);
    } catch (e) {
      // In a real app, map specific exceptions to user-friendly messages
      state = CheckinError(e.toString().replaceAll('Exception: ', '')); 
    }
  }

  void reset() {
    state = const CheckinIdle();
  }
}
