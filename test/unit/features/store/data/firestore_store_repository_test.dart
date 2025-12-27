import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/core/utils/crashlytics_helper.dart';
import 'package:ibct_eventos/features/store/data/firestore_store_repository.dart';
import 'package:ibct_eventos/features/store/domain/models/transaction_model.dart';
import 'package:mocktail/mocktail.dart';

class MockCrashlyticsHelper extends Mock implements CrashlyticsHelper {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockCrashlyticsHelper mockCrashlytics;
  late FirestoreStoreRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockCrashlytics = MockCrashlyticsHelper();

    when(() => mockCrashlytics.recordError(any(), any(), reason: any(named: 'reason'))).thenAnswer((_) async {});

    repository = FirestoreStoreRepository(fakeFirestore, mockCrashlytics);
  });

  final testTransaction = TransactionModel(
    id: 'tx_1',
    eventId: 'event_1',
    participantId: 'p1',
    participantName: 'John',
    productName: 'T-Shirt',
    price: 20.0,
    timestamp: DateTime(2023, 1, 1),
    sellerId: 'user_1',
  );

  group('FirestoreStoreRepository', () {
    test('addTransaction should add to firestore', () async {
      await repository.addTransaction(testTransaction);

      final snapshot = await fakeFirestore.collection('transactions').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['product_name'], 'T-Shirt');
    });

    test('getTransactions should return list of transactions for event', () async {
      final t1 = testTransaction;
      final t2 = TransactionModel(
        id: 'tx_2',
        eventId: 'event_1', // Same event
        participantId: 'p2',
        participantName: 'Jane',
        productName: 'Mug',
        price: 10.0,
        timestamp: DateTime(2023, 1, 2),
        sellerId: 'user_1',
      );
      final t3 = TransactionModel(
        id: 'tx_3',
        eventId: 'event_2', // Different event
        participantId: 'p3',
        participantName: 'Bob',
        productName: 'Hat',
        price: 15.0,
        timestamp: DateTime(2023, 1, 3),
        sellerId: 'user_1',
      );

      await repository.addTransaction(t1);
      await repository.addTransaction(t2);
      await repository.addTransaction(t3);

      final transactions = await repository.getTransactions('event_1');
      expect(transactions.length, 2);
      // Verify ordering (descending timestamp)
      expect(transactions.first.productName, 'Mug'); // t2 is newer
    });
  });
}
