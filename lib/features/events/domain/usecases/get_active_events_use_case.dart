import '../../../../core/interfaces/database_repository.dart';
import '../models/event_model.dart';

class GetActiveEventsUseCase {
  final DatabaseRepository<Event> _eventRepository;

  GetActiveEventsUseCase(this._eventRepository);

  Future<List<Event>> call() async {
    final events = await _eventRepository.getItems();
    final activeEvents = events.where((event) => !event.isArchived).toList();
    // Sort chronologically: soonest events first
    activeEvents.sort((a, b) => a.date.compareTo(b.date));
    return activeEvents;
  }
}
