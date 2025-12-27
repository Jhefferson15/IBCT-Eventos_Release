import 'package:uuid/uuid.dart';

import '../../../../features/users/domain/models/activity_log.dart';
import '../../../../features/users/domain/usecases/log_activity_use_case.dart';
import '../../../store/domain/models/transaction_model.dart';
import '../../../store/domain/repositories/store_repository_interface.dart';
import '../../presentation/providers/pos_providers.dart'; // For CartItem Model

class ProcessSaleUseCase {
  final IStoreRepository _storeRepository;
  final LogActivityUseCase _logActivityUseCase;

  ProcessSaleUseCase(this._storeRepository, this._logActivityUseCase);

  Future<void> executeSingle({
    required String eventId,
    required String participantId,
    required String participantName,
    required String productName,
    required double price,
    required String sellerId,
  }) async {
    final transaction = TransactionModel(
      id: const Uuid().v4(),
      eventId: eventId,
      participantId: participantId,
      participantName: participantName,
      productName: productName,
      price: price,
      timestamp: DateTime.now(),
      sellerId: sellerId,
    );

    await _storeRepository.addTransaction(transaction);

    await _logActivity(
      userId: sellerId,
      eventId: eventId,
      actionType: ActivityActionType.sale,
      targetId: transaction.id,
      targetType: 'transaction',
      details: {
        'participantName': participantName,
        'productName': productName,
        'value': price,
      },
    );
  }

  Future<void> executeCart({
    required String eventId,
    required String participantId,
    required String participantName,
    required List<CartItem> items,
    required String sellerId,
  }) async {
    final batch = <Future>[];
    
    // Create transactions for each item quantity
    // Note: TransactionModel logic here mimics controller logic: separate transaction per unit?
    // Controller loop: for item in items -> for i=0; i<quantity; i++ -> addTransaction
    // This seems verbose for DB but I will preserve existing logic.

    for (final item in items) {
      for (var i = 0; i < item.quantity; i++) {
        final transaction = TransactionModel(
          id: const Uuid().v4(),
          eventId: eventId,
          participantId: participantId,
          participantName: participantName,
          productName: item.product.name,
          price: item.product.price,
          timestamp: DateTime.now(),
          sellerId: sellerId,
        );
        batch.add(_storeRepository.addTransaction(transaction));
      }
    }

    await Future.wait(batch);

    // Single Log for Cart
    final totalCount = items.fold<int>(0, (p, e) => p + e.quantity);
    final totalValue = items.fold<double>(0, (p, e) => p + (e.product.price * e.quantity));

    await _logActivity(
      userId: sellerId,
      eventId: eventId,
      actionType: ActivityActionType.sale,
      targetId: eventId, 
      targetType: 'event', // Cart sale logged at event level per existing logic
      details: {
        'participantName': participantName,
        'itemCount': totalCount,
        'totalValue': totalValue,
      },
    );
  }

  Future<void> _logActivity({
    required String userId,
    required String eventId, // Not always used in targetId but good for context
    required ActivityActionType actionType,
    required String targetId,
    required String targetType,
    required Map<String, dynamic> details,
  }) async {
      try {
        await _logActivityUseCase.call(
          userId: userId,
          actionType: actionType,
          targetId: targetId,
          targetType: targetType,
          details: details,
        );
      } catch (e) {
        // Silently fail logging as per original
      }
  }
}
