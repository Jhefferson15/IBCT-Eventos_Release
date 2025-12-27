import 'package:flutter_riverpod/flutter_riverpod.dart';
export 'store_controller.dart';

import '../../domain/models/transaction_model.dart';
import '../../data/firestore_store_repository.dart';
import '../../domain/repositories/store_repository_interface.dart';
import '../../domain/usecases/get_transactions_usecase.dart';
import '../../domain/usecases/process_sale_use_case.dart';
import '../../domain/usecases/get_store_stats_use_case.dart';
import 'product_providers.dart';
import '../../../users/presentation/providers/activity_log_provider.dart';

final storeRepositoryProvider = Provider<IStoreRepository>((ref) {
  return FirestoreStoreRepository();
});

final getTransactionsUseCaseProvider = Provider<GetTransactionsUseCase>((ref) {
  final repository = ref.watch(storeRepositoryProvider);
  return GetTransactionsUseCase(repository);
});

final processSaleUseCaseProvider = Provider<ProcessSaleUseCase>((ref) {
  final repository = ref.watch(storeRepositoryProvider);
  final logActivityUseCase = ref.watch(logActivityUseCaseProvider);
  return ProcessSaleUseCase(repository, logActivityUseCase);
});

final getStoreStatsUseCaseProvider = Provider<GetStoreStatsUseCase>((ref) {
  final storeRepo = ref.watch(storeRepositoryProvider);
  final productRepo = ref.watch(productRepositoryProvider);
  return GetStoreStatsUseCase(storeRepo, productRepo);
});

final storeStatsProvider = FutureProvider.family<StoreStats, String>((ref, eventId) async {
  final useCase = ref.watch(getStoreStatsUseCaseProvider);
  return await useCase.execute(eventId);
});

final storeTransactionsProvider = FutureProvider.family<List<TransactionModel>, String>((ref, eventId) async {
  ref.keepAlive();
  final useCase = ref.watch(getTransactionsUseCaseProvider);
  return useCase(eventId);
});
