import '../../../../core/interfaces/database_repository.dart';
import '../models/event_model.dart';

class GetArchivedEventsUseCase {
  final DatabaseRepository<Event> _eventRepository;

  GetArchivedEventsUseCase(this._eventRepository);

  Future<List<Event>> call() async {
    final events = await _eventRepository.getItems();
    final archivedEvents = events.where((event) => event.isArchived).toList();
    // Sort chronologically: most recent first (descending)
    archivedEvents.sort((a, b) => b.date.compareTo(a.date));
    return archivedEvents;
  }
}
