
class TransactionModel {
  final String id;
  final String eventId;
  final String participantId;
  final String participantName;
  final String productName;
  final double price;
  final DateTime timestamp;
  final String sellerId;

  TransactionModel({
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
      'id': id,
      'eventId': eventId,
      'participantId': participantId,
      'participantName': participantName,
      'productName': productName,
      'price': price,
      'timestamp': timestamp.toIso8601String(),
      'sellerId': sellerId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      eventId: map['eventId'] ?? '',
      participantId: map['participantId'] ?? '',
      participantName: map['participantName'] ?? '',
      productName: map['productName'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
      sellerId: map['sellerId'] ?? '',
    );
  }


  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is TransactionModel &&
      other.id == id &&
      other.eventId == eventId &&
      other.participantId == participantId &&
      other.participantName == participantName &&
      other.productName == productName &&
      other.price == price &&
      other.timestamp == timestamp &&
      other.sellerId == sellerId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      eventId.hashCode ^
      participantId.hashCode ^
      participantName.hashCode ^
      productName.hashCode ^
      price.hashCode ^
      timestamp.hashCode ^
      sellerId.hashCode;
  }
}
