import '../../../../core/usecases/use_case.dart';
import '../../../../features/editor/domain/models/participant_model.dart';
import '../../../../features/users/domain/models/activity_log.dart';
import '../../../../features/users/domain/usecases/log_activity_use_case.dart';
import '../repositories/checkin_repository_interface.dart';

class CheckInParticipantParams {
  final String token;
  final String? operatorId;

  const CheckInParticipantParams({
    required this.token,
    this.operatorId,
  });
}

class CheckInResult {
  final Participant participant;
  final bool alreadyCheckedIn;

  CheckInResult(this.participant, this.alreadyCheckedIn);
}

class CheckInParticipantUseCase implements UseCase<CheckInResult, CheckInParticipantParams> {
  final ICheckinRepository _repository;
  final LogActivityUseCase _logActivityUseCase;

  CheckInParticipantUseCase(this._repository, this._logActivityUseCase);

  @override
  Future<CheckInResult> call(CheckInParticipantParams params) async {
    final participant = await _repository.getParticipantByToken(params.token);

    if (participant == null) {
      throw Exception('Código Inválido');
    }

    if (participant.isCheckedIn) {
      return CheckInResult(participant, true);
    }

    await _repository.checkInParticipant(participant.id);

    // Log the activity if an operator ID is provided
    if (params.operatorId != null) {
      try {
        await _logActivityUseCase.call(
            userId: params.operatorId!,
            actionType: ActivityActionType.checkInParticipant,
            targetId: participant.id,
            targetType: 'participant',
            details: {'name': participant.name, 'eventId': participant.eventId},
          );
      } catch (_) {
        // Silently fail logging to not disrupt check-in flow
      }
    }

    final updatedParticipant = participant.copyWith(
      isCheckedIn: true,
      checkInTime: DateTime.now(), // In a real app, repository might return updated entity
      status: 'Presente',
    );

    return CheckInResult(updatedParticipant, false);
  }
}
