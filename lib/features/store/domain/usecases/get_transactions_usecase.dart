import '../models/transaction_model.dart';
import '../repositories/store_repository_interface.dart';

class GetTransactionsUseCase {
  final IStoreRepository _repository;

  GetTransactionsUseCase(this._repository);

  Future<List<TransactionModel>> call(String eventId) async {
    return _repository.getTransactions(eventId);
  }
}
