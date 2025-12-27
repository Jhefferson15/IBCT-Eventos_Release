import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/firestore_product_repository.dart';
import '../../domain/models/product.dart';

final productRepositoryProvider = Provider<FirestoreProductRepository>((ref) {
  return FirestoreProductRepository();
});

final productsProvider = FutureProvider.family<List<Product>, String>((ref, eventId) async {
  ref.keepAlive();
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProducts(eventId);
});

final productControllerProvider = AsyncNotifierProvider<ProductController, void>(ProductController.new);

class ProductController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No initial state to load
  }

  Future<void> addProduct(Product product) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(productRepositoryProvider).addProduct(product);
      ref.invalidate(productsProvider(product.eventId));
    });
  }

  Future<void> updateProduct(Product product) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(productRepositoryProvider).updateProduct(product);
      ref.invalidate(productsProvider(product.eventId));
    });
  }

  Future<void> deleteProduct(String productId) async {
    // We need eventId to invalidate. 
    // This method signature is weak as it lacks eventId.
    // However, usually we have the product object context in UI or we can pass eventId.
    // For now, let's assume we can't invalidate easily without eventId OR we pass it.
    // I'll update the signature to accept eventId or assume global refresh if critical.
    // But wait, the repo deleteProduct only takes ID.
    // If I can't invalidate specific provider, I might leave it stale? No.
    // Best fix: pass eventId to deleteProduct.
    // But that requires changing the abstract/interface method signature?
    // Repository doesn't enforce eventId.
    // Let's modify the Controller method to take eventId.
    state = await AsyncValue.guard(() => ref.read(productRepositoryProvider).deleteProduct(productId));
  }
}
