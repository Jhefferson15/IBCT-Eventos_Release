import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../users/presentation/providers/user_providers.dart';

// State for the Dashboard UI
class DashboardState {
  final bool isSearchExpanded;

  const DashboardState({
    this.isSearchExpanded = false,
  });

  DashboardState copyWith({
    bool? isSearchExpanded,
  }) {
    return DashboardState(
      isSearchExpanded: isSearchExpanded ?? this.isSearchExpanded,
    );
  }
}

class DashboardController extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    return const DashboardState();
  }

  void toggleSearch() {
    final newExpandedState = !state.isSearchExpanded;
    state = state.copyWith(isSearchExpanded: newExpandedState);
    
    // Side effect: Clear search query
    if (!newExpandedState) {
      ref.read(searchQueryProvider.notifier).update('');
    }
  }

  void updateSearchQuery(String query) {
    ref.read(searchQueryProvider.notifier).update(query);
  }

  Future<void> deleteEvent(String eventId, String eventTitle) async {
    final currentUser = ref.read(currentUserProvider).value;

    if (currentUser != null) {
      // Use the provider for the use case which is now in events feature
      final deleteEventUseCase = ref.read(deleteEventUseCaseProvider);
      await deleteEventUseCase.call(
        eventId: eventId,
        userId: currentUser.id,
        eventTitle: eventTitle,
      );
    }
    
    // Invalidate list providers to refresh the UI
    ref.invalidate(eventsProvider);
    ref.invalidate(activeEventsProvider);
    ref.invalidate(archivedEventsProvider);
  }
}

final dashboardControllerProvider = NotifierProvider<DashboardController, DashboardState>(DashboardController.new);
