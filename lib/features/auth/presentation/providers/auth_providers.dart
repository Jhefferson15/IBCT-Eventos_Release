import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/auth_repository_interface.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/usecases/login_with_google_use_case.dart';
import '../../domain/usecases/login_with_email_use_case.dart';
import '../../../users/presentation/providers/user_di.dart';
import '../../../users/presentation/providers/activity_log_provider.dart';

// Data Source Provider
final authRemoteDataSourceProvider = Provider<IAuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl();
});

// The repository provider (Interface based)
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Stream of auth state changes
final authStateChangesProvider = StreamProvider<AuthUser?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

// Current user provider (Sync, might be null if not initialized or logged out)
final firebaseUserProvider = Provider<AuthUser?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.value;
});

// Use Cases
final loginWithGoogleUseCaseProvider = Provider<LoginWithGoogleUseCase>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  final logActivityUseCase = ref.watch(logActivityUseCaseProvider);
  
  return LoginWithGoogleUseCase(
    authRepository,
    userRepository,
    logActivityUseCase,
  );
});

final loginWithEmailUseCaseProvider = Provider<LoginWithEmailUseCase>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  final logActivityUseCase = ref.watch(logActivityUseCaseProvider);

  return LoginWithEmailUseCase(
    authRepository,
    userRepository,
    logActivityUseCase,
  );
});
