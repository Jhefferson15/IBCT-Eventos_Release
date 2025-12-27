
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/firebase_providers.dart';
import '../../domain/models/activity_log.dart';
import '../../data/firestore_activity_log_repository.dart';
import '../../domain/repositories/activity_log_repository_interface.dart';
import '../../domain/usecases/log_activity_use_case.dart';
import '../../domain/usecases/get_activity_logs_use_case.dart';


final activityLogRepositoryProvider = Provider<IActivityLogRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreActivityLogRepository(firestore);
});

final logActivityUseCaseProvider = Provider<LogActivityUseCase>((ref) {
  final repository = ref.watch(activityLogRepositoryProvider);
  return LogActivityUseCase(repository);
});

final getActivityLogsUseCaseProvider = Provider<GetActivityLogsUseCase>((ref) {
  final repository = ref.watch(activityLogRepositoryProvider);
  return GetActivityLogsUseCase(repository);
});

final activityLogsProvider = FutureProvider.autoDispose.family<List<ActivityLog>, String?>((ref, userId) {
  final useCase = ref.watch(getActivityLogsUseCaseProvider);
  return useCase(userId: userId);
});
