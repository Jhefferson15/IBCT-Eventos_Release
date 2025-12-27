
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/transaction_model.dart';

class TransactionDto {
  final String id;
  final String eventId;
  final String participantId;
  final String participantName;
  final String productName;
  final double price;
  final DateTime timestamp;
  final String sellerId;

  TransactionDto({
    required this.id,
    required this.eventId,
    required this.participantId,
    required this.participantName,
    required this.productName,
    required this.price,
    required this.timestamp,
    required this.sellerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'participant_id': participantId,
      'participant_name': participantName,
      'product_name': productName,
      'price': price,
      'timestamp': Timestamp.fromDate(timestamp),
      'seller_id': sellerId,
    };
  }

  factory TransactionDto.fromMap(Map<String, dynamic> map, String id) {
    return TransactionDto(
      id: id,
      eventId: map['event_id'] ?? '',
      participantId: map['participant_id'] ?? '',
      participantName: map['participant_name'] ?? '',
      productName: map['product_name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      sellerId: map['seller_id'] ?? '',
    );
  }

  factory TransactionDto.fromDomain(TransactionModel transaction) {
    return TransactionDto(
      id: transaction.id,
      eventId: transaction.eventId,
      participantId: transaction.participantId,
      participantName: transaction.participantName,
      productName: transaction.productName,
      price: transaction.price,
      timestamp: transaction.timestamp,
      sellerId: transaction.sellerId,
    );
  }

  TransactionModel toDomain() {
    return TransactionModel(
      id: id,
      eventId: eventId,
      participantId: participantId,
      participantName: participantName,
      productName: productName,
      price: price,
      timestamp: timestamp,
      sellerId: sellerId,
    );
  }
}
