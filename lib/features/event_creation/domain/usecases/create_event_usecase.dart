
import 'package:ibct_eventos/core/interfaces/database_repository.dart';
import 'package:ibct_eventos/features/events/domain/models/event_model.dart';
import 'package:ibct_eventos/features/users/domain/models/activity_log.dart';
import 'package:ibct_eventos/features/users/domain/usecases/log_activity_use_case.dart';

class CreateEventUseCase {
  final DatabaseRepository<Event> _eventRepository;
  final LogActivityUseCase _logActivityUseCase;

  CreateEventUseCase(this._eventRepository, this._logActivityUseCase);

  Future<String> call(Event event, String userId) async {
    final docId = await _eventRepository.createItem(event);
    
    // Log Activity
    try {
      await _logActivityUseCase.call(
        userId: userId,
        actionType: ActivityActionType.createEvent,
        targetId: docId,
        targetType: 'event',
        details: {'title': event.title, 'date': event.date.toIso8601String()},
      );
    } catch (e) {
      // Activity logging failure shouldn't fail the event creation
    }
    return docId;
  }
}
