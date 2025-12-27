import '../models/participant_model.dart';
import '../repositories/participant_repository_interface.dart';
import 'package:ibct_eventos/features/users/domain/models/activity_log.dart';
import 'package:ibct_eventos/features/users/domain/usecases/log_activity_use_case.dart';

class UpdateParticipantUseCase {
  final IParticipantRepository _repository;
  final LogActivityUseCase _logActivityUseCase;

  UpdateParticipantUseCase(this._repository, this._logActivityUseCase);

  Future<void> call(Participant participant, String userId) async {
    await _repository.updateItem(participant);
    
    await _logActivityUseCase.call(
      userId: userId,
      actionType: ActivityActionType.updateParticipant,
      targetId: participant.id,
      targetType: 'participant',
      details: {'name': participant.name, 'eventId': participant.eventId, 'changes': 'updated inline'}, 
    );
  }
}
