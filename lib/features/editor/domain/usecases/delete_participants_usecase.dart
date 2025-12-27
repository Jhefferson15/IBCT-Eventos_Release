import '../repositories/participant_repository_interface.dart';
import 'package:ibct_eventos/features/users/domain/models/activity_log.dart';
import 'package:ibct_eventos/features/users/domain/usecases/log_activity_use_case.dart';

class DeleteParticipantsUseCase {
  final IParticipantRepository _repository;
  final LogActivityUseCase _logActivityUseCase;

  DeleteParticipantsUseCase(this._repository, this._logActivityUseCase);

  Future<void> call(List<String> ids, String eventId, String userId) async {
    if (ids.isEmpty) return;

    await _repository.deleteItemsBatch(ids);
    
    await _logActivityUseCase.call(
      userId: userId,
      actionType: ActivityActionType.deleteParticipant,
      targetId: 'bulk-${DateTime.now().millisecondsSinceEpoch}',
      targetType: 'participants_bulk',
      details: {
        'count': ids.length, 
        'eventId': eventId,
        'message': 'Deleted ${ids.length} participants'
      },
    );
  }
}
