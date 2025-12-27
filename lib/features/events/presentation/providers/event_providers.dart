
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/firestore_event_repository.dart';
import '../../domain/models/event_model.dart';
import '../../../../core/interfaces/database_repository.dart';
import '../../domain/usecases/get_active_events_use_case.dart';
import '../../domain/usecases/get_archived_events_use_case.dart';
import '../../domain/usecases/delete_event_use_case.dart';
import '../../domain/usecases/search_events_use_case.dart';
import '../../../users/presentation/providers/activity_log_provider.dart';

// Repository Provider
final eventRepositoryProvider = Provider<DatabaseRepository<Event>>((ref) {
  return FirestoreEventRepository();
});

// Use Cases Providers
final getActiveEventsUseCaseProvider = Provider<GetActiveEventsUseCase>((ref) {
  return GetActiveEventsUseCase(ref.watch(eventRepositoryProvider));
});

final getArchivedEventsUseCaseProvider = Provider<GetArchivedEventsUseCase>((ref) {
  return GetArchivedEventsUseCase(ref.watch(eventRepositoryProvider));
});

final deleteEventUseCaseProvider = Provider<DeleteEventUseCase>((ref) {
  return DeleteEventUseCase(
    ref.watch(eventRepositoryProvider),
    ref.watch(logActivityUseCaseProvider),
  );
});

final searchEventsUseCaseProvider = Provider<SearchEventsUseCase>((ref) {
  return SearchEventsUseCase();
});

// Stream Provider for real-time events (Keep for now if utilized elsewhere directly, or deprecate)
// Future Provider for events
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  ref.keepAlive();
  final repository = ref.watch(eventRepositoryProvider);
  return await repository.getItems();
});

// Provider for a single event by ID
final singleEventProvider = FutureProvider.family<Event?, String>((ref, eventId) async {
  ref.keepAlive();
  final repository = ref.watch(eventRepositoryProvider);
  return await repository.getItem(eventId);
});


// Stream Provider for active events
final activeEventsProvider = StreamProvider<List<Event>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.watchItems().map((events) {
    final active = events.where((event) => !event.isArchived).toList();
    active.sort((a, b) => a.date.compareTo(b.date));
    return active;
  });
});

// Stream Provider for archived events
final archivedEventsProvider = StreamProvider<List<Event>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.watchItems().map((events) {
    final archived = events.where((event) => event.isArchived).toList();
    archived.sort((a, b) => b.date.compareTo(a.date));
    return archived;
  });
});

// State provider for search query
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String newState) {
    state = newState;
  }
}

// Provider for filtered events based on search query
final filteredEventsProvider = StreamProvider<List<Event>>((ref) {
  final activeEventsAsync = ref.watch(activeEventsProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final searchUseCase = ref.watch(searchEventsUseCaseProvider);
  
  return activeEventsAsync.when(
    data: (activeEvents) => Stream.value(searchUseCase.call(events: activeEvents, query: searchQuery)),
    loading: () => const Stream.empty(),
    error: (err, stack) => Stream.error(err, stack),
  );
});
