import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../domain/usecases/get_global_stats_use_case.dart';
import '../../../users/presentation/providers/activity_log_provider.dart';
import '../../../users/presentation/providers/user_providers.dart';
import '../../../users/domain/models/activity_log.dart';

final getGlobalStatsUseCaseProvider = Provider<GetGlobalStatsUseCase>((ref) {
  return GetGlobalStatsUseCase();
});

final globalParticipantCountProvider = Provider<AsyncValue<int>>((ref) {
  final eventsAsync = ref.watch(activeEventsProvider);
  final useCase = ref.watch(getGlobalStatsUseCaseProvider);

  return eventsAsync.whenData((events) => useCase.execute(events));
});

final recentActivitiesProvider = FutureProvider<List<ActivityLog>>((ref) async {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return [];
  
  // Fetch activity logs for current user (or all if admin, but provider takes userId)
  // For dashboard, we might want "all" activities if the user is admin.
  // The existing activityLogsProvider takes String? userId.
  return ref.watch(activityLogsProvider(null).future);
});
