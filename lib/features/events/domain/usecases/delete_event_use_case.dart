import '../../../../core/interfaces/database_repository.dart';
import '../models/event_model.dart';
import '../../../users/domain/models/activity_log.dart';
import '../../../users/domain/usecases/log_activity_use_case.dart';

class DeleteEventUseCase {
  final DatabaseRepository<Event> _eventRepository;
  final LogActivityUseCase _logActivityUseCase;

  DeleteEventUseCase(this._eventRepository, this._logActivityUseCase);

  Future<void> call({
    required String eventId,
    required String userId,
    required String eventTitle,
  }) async {
    await _eventRepository.deleteItem(eventId);

    try {
      await _logActivityUseCase.call(
        userId: userId,
        actionType: ActivityActionType.deleteEvent,
        targetId: eventId,
        targetType: 'event',
        details: {'title': eventTitle},
      );
    } catch (e) {
      // Log failure should not fail the operation
    }
  }
}
