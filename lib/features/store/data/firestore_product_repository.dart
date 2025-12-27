import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/crashlytics_helper.dart';
import '../domain/models/product.dart';
import 'models/product_dto.dart';

class FirestoreProductRepository {
  final FirebaseFirestore _firestore;
  final CrashlyticsHelper _crashlytics;
  final String _collection = 'products';

  FirestoreProductRepository([FirebaseFirestore? firestore, CrashlyticsHelper? crashlytics])
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _crashlytics = crashlytics ?? CrashlyticsHelper();

  Future<List<Product>> getProducts(String eventId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('event_id', isEqualTo: eventId)
        .get();

    return snapshot.docs.map((doc) {
      return ProductDto.fromMap(doc.data(), doc.id).toDomain();
    }).toList();
  }

  Future<void> addProduct(Product product) async {
    try {
      final dto = ProductDto.fromDomain(product);
      await _firestore.collection(_collection).add(dto.toMap());
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack, reason: 'Error adding product');
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      final dto = ProductDto.fromDomain(product);
      await _firestore.collection(_collection).doc(product.id).update(dto.toMap());
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack, reason: 'Error updating product');
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection(_collection).doc(productId).delete();
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack, reason: 'Error deleting product');
      rethrow;
    }
  }
}
