import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibct_eventos/features/shared/import/data/repositories/import_repository_impl.dart';
import 'package:ibct_eventos/features/shared/import/domain/repositories/import_repository_interface.dart';
import 'package:ibct_eventos/features/shared/import/domain/usecases/get_import_data_usecase.dart';
import 'package:ibct_eventos/features/participants/domain/usecases/process_import_use_case.dart';
import 'package:ibct_eventos/features/participants/domain/usecases/create_participants_batch_usecase.dart';
import 'package:ibct_eventos/features/editor/presentation/providers/participant_providers.dart';
import 'package:ibct_eventos/features/users/presentation/providers/activity_log_provider.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../events/presentation/providers/event_providers.dart';
import '../../domain/usecases/get_drive_files_use_case.dart';
import '../../domain/usecases/finalize_import_use_case.dart';
import '../../domain/usecases/request_google_access_use_case.dart';

final importRepositoryProvider = Provider<ImportRepository>((ref) {
  return ImportRepositoryImpl();
});

final getImportDataUseCaseProvider = Provider<GetImportDataUseCase>((ref) {
  final repository = ref.read(importRepositoryProvider);
  return GetImportDataUseCase(repository);
});

final processImportUseCaseProvider = Provider<ProcessImportUseCase>((ref) {
  return ProcessImportUseCase();
});

final createParticipantsBatchUseCaseProvider = Provider<CreateParticipantsBatchUseCase>((ref) {
  final repository = ref.read(participantRepositoryProvider);
  final logActivityUseCase = ref.read(logActivityUseCaseProvider);
  return CreateParticipantsBatchUseCase(repository, logActivityUseCase);
});

final getDriveFilesUseCaseProvider = Provider<GetDriveFilesUseCase>((ref) {
  return GetDriveFilesUseCase(
    ref.read(authRepositoryProvider),
    ref.read(importRepositoryProvider),
  );
});

final finalizeImportUseCaseProvider = Provider<FinalizeImportUseCase>((ref) {
  return FinalizeImportUseCase(
    ref.read(createParticipantsBatchUseCaseProvider),
    ref.read(eventRepositoryProvider),
  );
});

final requestGoogleAccessUseCaseProvider = Provider<RequestGoogleAccessUseCase>((ref) {
  return RequestGoogleAccessUseCase(ref.read(authRepositoryProvider));
});
