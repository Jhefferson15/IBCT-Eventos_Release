import 'package:ibct_eventos/core/interfaces/database_repository.dart';
import 'package:ibct_eventos/features/events/domain/models/event_model.dart';
import 'package:ibct_eventos/features/users/domain/models/activity_log.dart';
import 'package:ibct_eventos/features/users/domain/usecases/log_activity_use_case.dart';

class UpdateEventUseCase {
  final DatabaseRepository<Event> _eventRepository;
  final LogActivityUseCase _logActivityUseCase;

  UpdateEventUseCase(this._eventRepository, this._logActivityUseCase);

  Future<void> call(Event event, String userId) async {
    await _eventRepository.updateItem(event);
    
     // Log Activity
    try {
      if (event.id != null) {
        await _logActivityUseCase.call(
          userId: userId,
          actionType: ActivityActionType.updateEvent,
          targetId: event.id!,
          targetType: 'event',
          details: {'title': event.title},
        );
      }
    } catch (e) {
      // Activity logging failure shouldn't fail the event update
    }
  }
}
