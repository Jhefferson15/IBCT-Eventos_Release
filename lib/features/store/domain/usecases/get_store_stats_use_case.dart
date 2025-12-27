import '../repositories/store_repository_interface.dart';
import '../../data/firestore_product_repository.dart'; // Ideally use interface

class StoreStats {
  final int productsCount;
  final int todaySalesCount;

  StoreStats({required this.productsCount, required this.todaySalesCount});
}

class GetStoreStatsUseCase {
  final IStoreRepository _storeRepository;
  final FirestoreProductRepository _productRepository; // Should use interface

  GetStoreStatsUseCase(this._storeRepository, this._productRepository);

  Future<StoreStats> execute(String eventId) async {
    // 1. Get products
    final products = await _productRepository.getProducts(eventId);
    final productsCount = products.length;

    // 2. Get today's transactions
    final transactions = await _storeRepository.getTransactions(eventId);
    final now = DateTime.now();
    final todayTransactions = transactions.where((t) {
      return t.timestamp.year == now.year &&
             t.timestamp.month == now.month &&
             t.timestamp.day == now.day;
    }).length;

    return StoreStats(
      productsCount: productsCount,
      todaySalesCount: todayTransactions,
    );
  }
}
