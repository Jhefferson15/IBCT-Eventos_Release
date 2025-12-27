import '../models/participant_model.dart';
import '../repositories/participant_repository_interface.dart';
import 'package:ibct_eventos/features/users/domain/models/activity_log.dart';
import 'package:ibct_eventos/features/users/domain/usecases/log_activity_use_case.dart';

class CreateParticipantUseCase {
  final IParticipantRepository _repository;
  final LogActivityUseCase _logActivityUseCase;

  CreateParticipantUseCase(this._repository, this._logActivityUseCase);

  Future<String> call(Participant participant, String userId) async {
    // The repository handles the complex atomic ID generation.
    final id = await _repository.createItem(participant);
    
    await _logActivityUseCase.call(
      userId: userId,
      actionType: ActivityActionType.addParticipant,
      targetId: id,
      targetType: 'participant',
      details: {'name': participant.name, 'eventId': participant.eventId},
    );
    
    return id;
  }
}
