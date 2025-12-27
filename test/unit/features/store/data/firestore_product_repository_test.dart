import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/core/utils/crashlytics_helper.dart';
import 'package:ibct_eventos/features/store/data/firestore_product_repository.dart';
import 'package:ibct_eventos/features/store/domain/models/product.dart';
import 'package:mocktail/mocktail.dart';

class MockCrashlyticsHelper extends Mock implements CrashlyticsHelper {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockCrashlyticsHelper mockCrashlytics;
  late FirestoreProductRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockCrashlytics = MockCrashlyticsHelper();

    when(() => mockCrashlytics.recordError(any(), any(), reason: any(named: 'reason'))).thenAnswer((_) async {});

    repository = FirestoreProductRepository(fakeFirestore, mockCrashlytics);
  });

  final testProduct = Product(
    id: 'prod_1',
    eventId: 'event_1',
    name: 'T-Shirt',
    description: 'Cotton T-Shirt',
    price: 25.0,
    imageUrl: 'img_url',
    isAvailable: true,
    category: 'Clothing',
  );

  group('FirestoreProductRepository', () {
    test('addProduct should add to firestore', () async {
      await repository.addProduct(testProduct);

      final snapshot = await fakeFirestore.collection('products').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['name'], 'T-Shirt');
    });

    test('getProducts should return list of products for event', () async {
      await repository.addProduct(testProduct);
      await repository.addProduct(Product(
        id: 'prod_2',
        eventId: 'event_2', // Different event
        name: 'Mug',
        description: 'Ceramic Muk',
        price: 10.0,
        imageUrl: '',
        isAvailable: true,
        category: 'Houseware',
      ));

      final products = await repository.getProducts('event_1');
      expect(products.length, 1);
      expect(products.first.name, 'T-Shirt');
    });

    test('updateProduct should modify existing product', () async {
      // Since addProduct uses auto-generated ID? Wait, let's check repo.
      // Repo uses .add(dto.toMap()). The valid product ID (which is in DTO) might not be respected if .add() ignores "id" field in map if strictly using Generated ID.
      // But here the repo: await _firestore.collection(_collection).add(dto.toMap());
      // The doc ID is generated. The 'id' inside the map depends on dto.toMap().
      // If product has ID 'prod_1', checking if it's set in the doc data.
      
      await repository.addProduct(testProduct);
      
      // To update, we needs the generated ID.
      final snapshot = await fakeFirestore.collection('products').get();
      final generatedId = snapshot.docs.first.id;

      final updated = testProduct.copyWith(id: generatedId, name: 'Blue T-Shirt');
      await repository.updateProduct(updated);

      final updatedSnapshot = await fakeFirestore.collection('products').doc(generatedId).get();
      expect(updatedSnapshot.data()?['name'], 'Blue T-Shirt');
    });

    test('deleteProduct should remove product', () async {
      // First add
      await repository.addProduct(testProduct);
      final snapshot = await fakeFirestore.collection('products').get();
      final generatedId = snapshot.docs.first.id;

      // Delete
      await repository.deleteProduct(generatedId);

      final deletedSnapshot = await fakeFirestore.collection('products').doc(generatedId).get();
      expect(deletedSnapshot.exists, isFalse);
    });
  });
}
