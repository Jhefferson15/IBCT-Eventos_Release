import '../models/transaction_model.dart';

abstract class IStoreRepository {
  Future<List<TransactionModel>> getTransactions(String eventId);
  Future<void> addTransaction(TransactionModel transaction);
}
