import '../../../../editor/domain/models/participant_model.dart';
import '../../../../events/domain/models/event_model.dart';
import '../../../../../core/interfaces/database_repository.dart';
import '../../../../participants/domain/usecases/create_participants_batch_usecase.dart';

class FinalizeImportUseCase {
  final CreateParticipantsBatchUseCase _createBatchUseCase;
  final DatabaseRepository<Event> _eventRepository;

  FinalizeImportUseCase(this._createBatchUseCase, this._eventRepository);

  Future<void> execute({
    required List<Participant> participants,
    required String eventId,
    required String userId,
    required Map<String, String> importMapping,
    required Event? event, 
    String? googleSheetId,
  }) async {
    
    // 1. Create Participants
    await _createBatchUseCase.execute(
      participants: participants,
      eventId: eventId,
      userId: userId,
      importMapping: importMapping,
      googleSheetId: googleSheetId,
    );

    // 2. Update Event if needed (single source logic preserved)
    if (googleSheetId != null && event != null) {
      final updatedEvent = event.copyWith(
        googleSheetsUrl: googleSheetId,
        importMapping: importMapping,
        lastSyncTime: DateTime.now(),
      );
      await _eventRepository.updateItem(updatedEvent);
    }
  }
}

