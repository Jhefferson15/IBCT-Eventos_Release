import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/crashlytics_helper.dart';
import '../domain/models/transaction_model.dart';
import 'models/transaction_dto.dart';
import '../domain/repositories/store_repository_interface.dart';

class FirestoreStoreRepository implements IStoreRepository {
  final FirebaseFirestore _firestore;
  final CrashlyticsHelper _crashlytics;
  final String _collection = 'transactions';

  FirestoreStoreRepository([FirebaseFirestore? firestore, CrashlyticsHelper? crashlytics])
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _crashlytics = crashlytics ?? CrashlyticsHelper();

  @override
  Future<List<TransactionModel>> getTransactions(String eventId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('event_id', isEqualTo: eventId)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return TransactionDto.fromMap(doc.data(), doc.id).toDomain();
    }).toList();
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      final dto = TransactionDto.fromDomain(transaction);
      // Let Firestore generate the ID
      await _firestore.collection(_collection).add(dto.toMap());
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack, reason: 'Error adding transaction');
      rethrow;
    }
  }
}
