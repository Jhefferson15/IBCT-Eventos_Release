import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/participant_model.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../providers/participant_providers.dart';
import '../../domain/usecases/get_filtered_participants_use_case.dart';

// State class for the grid
class ParticipantGridState {
  final String searchQuery;
  final String? sortColumnKey;
  final bool sortAscending;
  final Set<String> selectedIds;
  
  // Focus State
  final String? focusedParticipantId;
  final String? focusedColumnKey;

  // Visual State (Phase 2)
  final Map<String, double> columnWidths;
  final List<String>? columnOrder; // Local override for column order

  // Filters (Phase 3)
  final Map<String, String> columnFilters;

  const ParticipantGridState({
    this.searchQuery = '',
    this.sortColumnKey,
    this.sortAscending = true,
    this.selectedIds = const {},
    this.focusedParticipantId,
    this.focusedColumnKey,
    this.columnWidths = const {},
    this.columnOrder,
    this.columnFilters = const {},
  });

  ParticipantGridState copyWith({
    String? searchQuery,
    String? sortColumnKey,
    bool? sortAscending,
    Set<String>? selectedIds,
    String? focusedParticipantId,
    String? focusedColumnKey,
    Map<String, double>? columnWidths,
    List<String>? columnOrder,
    Map<String, String>? columnFilters,
  }) {
    return ParticipantGridState(
      searchQuery: searchQuery ?? this.searchQuery,
      sortColumnKey: sortColumnKey ?? this.sortColumnKey,
      sortAscending: sortAscending ?? this.sortAscending,
      selectedIds: selectedIds ?? this.selectedIds,
      focusedParticipantId: focusedParticipantId ?? this.focusedParticipantId,
      focusedColumnKey: focusedColumnKey ?? this.focusedColumnKey,
      columnWidths: columnWidths ?? this.columnWidths,
      columnOrder: columnOrder ?? this.columnOrder,
      columnFilters: columnFilters ?? this.columnFilters,
    );
  }
}

// Result object containing the filtered list and other computed data
// Re-exporting from Use Case or adapting.
// For now, let's keep the name for compatibility but map from Use Case result.
class ParticipantGridData {
  final List<Participant> participants;
  final List<String> sortedCustomKeys; 
  final List<String> visibleColumns; 

  ParticipantGridData(this.participants, this.sortedCustomKeys, this.visibleColumns);
}

// Using standard Notifier with constructor for family argument
class ParticipantGridNotifier extends Notifier<ParticipantGridState> {
  final String eventId;
  
  // Constructor handling the family argument
  ParticipantGridNotifier(this.eventId);

  @override
  ParticipantGridState build() {
    return const ParticipantGridState();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSort(String columnKey, bool ascending) {
    state = state.copyWith(
      sortColumnKey: columnKey,
      sortAscending: ascending,
    );
  }

  void toggleSelection(String id, bool? selected) {
    final newSelection = Set<String>.from(state.selectedIds);
    if (selected == true) {
      newSelection.add(id);
    } else {
      newSelection.remove(id);
    }
    state = state.copyWith(selectedIds: newSelection);
  }
  
  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  void setFocus(String? participantId, String? columnKey) {
    state = state.copyWith(
      focusedParticipantId: participantId,
      focusedColumnKey: columnKey,
    );
  }

  void setColumnWidth(String columnKey, double width) {
    final newWidths = Map<String, double>.from(state.columnWidths);
    newWidths[columnKey] = width;
    state = state.copyWith(columnWidths: newWidths);
  }

  void setColumnOrder(List<String> newOrder) {
    state = state.copyWith(columnOrder: newOrder);
  }

  void setFilter(String columnKey, String value) {
    final newFilters = Map<String, String>.from(state.columnFilters);
    if (value.isEmpty) {
      newFilters.remove(columnKey);
    } else {
      newFilters[columnKey] = value;
    }
    state = state.copyWith(columnFilters: newFilters);
  }
}

final participantGridStateProvider =
    NotifierProvider.family<ParticipantGridNotifier, ParticipantGridState, String>(ParticipantGridNotifier.new);

// Provider for the Use Case
final getFilteredParticipantsUseCaseProvider = Provider<GetFilteredParticipantsUseCase>((ref) {
  return GetFilteredParticipantsUseCase();
});

// Computed provider
final filteredParticipantsProvider = Provider.family<AsyncValue<ParticipantGridData>, String>((ref, eventId) {
  final participantsAsync = ref.watch(participantsControllerProvider(eventId));
  final gridState = ref.watch(participantGridStateProvider(eventId));
  final eventAsync = ref.watch(singleEventProvider(eventId));
  final useCase = ref.watch(getFilteredParticipantsUseCaseProvider);

  return participantsAsync.whenData((participants) {
    final result = useCase.call(
      participants: participants,
      searchQuery: gridState.searchQuery,
      columnFilters: gridState.columnFilters,
      sortColumnKey: gridState.sortColumnKey,
      sortAscending: gridState.sortAscending,
      columnOrder: gridState.columnOrder,
      defaultVisibleColumns: eventAsync.value?.visibleColumns ?? [],
    );

    return ParticipantGridData(result.participants, result.sortedCustomKeys, result.visibleColumns);
  });
});
