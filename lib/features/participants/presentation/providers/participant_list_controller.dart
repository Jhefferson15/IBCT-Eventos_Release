import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../editor/domain/models/participant_model.dart';
import '../../../editor/presentation/providers/participant_providers.dart';

class ParticipantListState {
  final String searchQuery;
  final int currentPage;
  final int itemsPerPage;

  const ParticipantListState({
    this.searchQuery = '',
    this.currentPage = 1,
    this.itemsPerPage = 100,
  });

  ParticipantListState copyWith({
    String? searchQuery,
    int? currentPage,
    int? itemsPerPage,
  }) {
    return ParticipantListState(
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
    );
  }
}

class ParticipantListNotifier extends Notifier<ParticipantListState> {
  final String eventId;
  ParticipantListNotifier(this.eventId);

  @override
  ParticipantListState build() {
    return const ParticipantListState();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
  }

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  void nextPage() {
    state = state.copyWith(currentPage: state.currentPage + 1);
  }

  void previousPage() {
    if (state.currentPage > 1) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }
}

final participantListStateProvider =
    NotifierProvider.family<ParticipantListNotifier, ParticipantListState, String>(
        ParticipantListNotifier.new);

final paginatedParticipantsProvider =
    Provider.family<AsyncValue<PaginatedParticipantsResult>, String>((ref, eventId) {
  final participantsAsync = ref.watch(participantsControllerProvider(eventId));
  final listState = ref.watch(participantListStateProvider(eventId));

  return participantsAsync.whenData((participants) {
    // 1. Filter
    var filtered = participants;
    if (listState.searchQuery.isNotEmpty) {
      final query = listState.searchQuery.toLowerCase();
      filtered = participants.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.email.toLowerCase().contains(query) ||
            (p.cpf?.contains(query) ?? false);
      }).toList();
    }

    // 2. Paginate
    final totalItems = filtered.length;
    final totalPages = (totalItems / listState.itemsPerPage).ceil();
    // Ensure current page is valid (e.g. if search reduced results)
    final currentPage = listState.currentPage > totalPages && totalPages > 0
        ? totalPages
        : listState.currentPage;
    
    final startIndex = (currentPage - 1) * listState.itemsPerPage;
    final endIndex = (startIndex + listState.itemsPerPage) > totalItems
        ? totalItems
        : (startIndex + listState.itemsPerPage);

    final pageItems = (startIndex < totalItems)
        ? filtered.sublist(startIndex, endIndex)
        : <Participant>[];

    return PaginatedParticipantsResult(
      items: pageItems,
      totalItems: totalItems,
      totalPages: totalPages,
      currentPage: currentPage,
    );
  });
});

class PaginatedParticipantsResult {
  final List<Participant> items;
  final int totalItems;
  final int totalPages;
  final int currentPage;

  PaginatedParticipantsResult({
    required this.items,
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
  });
}
