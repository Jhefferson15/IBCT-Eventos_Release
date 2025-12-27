import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/firebase_providers.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/firestore_user_repository.dart';
import 'activity_log_provider.dart';
import '../../domain/usecases/manage_helper_use_case.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreUserRepository(firestore);
});

final manageHelperUseCaseProvider = Provider<ManageHelperUseCase>((ref) {
  return ManageHelperUseCase(
    ref.read(userRepositoryProvider),
    ref.read(logActivityUseCaseProvider),
  );
});
