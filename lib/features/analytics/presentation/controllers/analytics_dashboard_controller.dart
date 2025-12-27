import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../editor/domain/models/participant_model.dart';
import '../../../editor/presentation/providers/participant_providers.dart';

// ViewModel/State for the Dashboard
class AnalyticsDashboardState {
  final int total;
  final int confirmed;
  final int pending;
  final int checkedIn;
  final List<Participant> participants;
  final bool isLoading;
  final String? error;

  AnalyticsDashboardState({
    this.total = 0,
    this.confirmed = 0,
    this.pending = 0,
    this.checkedIn = 0,
    this.participants = const [],
    this.isLoading = true,
    this.error,
  });
}

// Controller
class AnalyticsDashboardController
    extends Notifier<AnalyticsDashboardState> {
  final String eventId;
  AnalyticsDashboardController(this.eventId);

  @override
  AnalyticsDashboardState build() {
    final participantsAsync = ref.watch(participantsControllerProvider(eventId));

    return participantsAsync.when(
      data: (participants) {
        final total = participants.length;
        final confirmed = participants
            .where((p) => p.status == 'Confirmado' || p.isCheckedIn)
            .length;
        final pending = participants
            .where((p) => p.status == 'Pendente' && !p.isCheckedIn)
            .length;
        final checkedIn = participants.where((p) => p.isCheckedIn).length;

        return AnalyticsDashboardState(
          total: total,
          confirmed: confirmed,
          pending: pending,
          checkedIn: checkedIn,
          participants: participants,
          isLoading: false,
        );
      },
      error: (err, stack) {
        return AnalyticsDashboardState(isLoading: false, error: err.toString());
      },
      loading: () {
        return AnalyticsDashboardState(isLoading: true);
      },
    );
  }
}

final analyticsDashboardControllerProvider =
    NotifierProvider.family<AnalyticsDashboardController, AnalyticsDashboardState, String>(
        AnalyticsDashboardController.new);
