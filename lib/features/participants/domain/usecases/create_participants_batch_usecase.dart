import 'package:ibct_eventos/features/editor/domain/models/participant_model.dart';
import 'package:ibct_eventos/features/editor/domain/repositories/participant_repository_interface.dart';
import 'package:ibct_eventos/features/users/domain/models/activity_log.dart';
import 'package:ibct_eventos/features/users/domain/usecases/log_activity_use_case.dart';

class CreateParticipantsBatchUseCase {
  final IParticipantRepository _repository;
  final LogActivityUseCase _logActivityUseCase;

  CreateParticipantsBatchUseCase(this._repository, this._logActivityUseCase);

  Future<void> execute({
    required List<Participant> participants,
    required String eventId,
    required String userId,
    Map<String, String>? importMapping,
    String? googleSheetId,
  }) async {
    if (participants.isEmpty) return;

    // 1. Create participants in batch
    await _repository.createItemsBatch(participants);

    // 2. Log activity
    await _logActivityUseCase.call(
      userId: userId,
      actionType: ActivityActionType.importParticipants,
      targetId: eventId,
      targetType: 'event',
      details: {
        'count': participants.length,
        'importType': 'batch',
      },
    );
  }
}
