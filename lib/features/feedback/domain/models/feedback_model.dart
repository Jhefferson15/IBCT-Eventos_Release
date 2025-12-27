
class FeedbackModel {
  final String id;
  final String userId;
  final String userEmail;
  final String message;
  final DateTime timestamp;
  final String type; // 'bug' or 'general'
  final Map<String, dynamic>? deviceInfo;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.message,
    required this.timestamp,
    required this.type,
    this.deviceInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'deviceInfo': deviceInfo,
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      message: map['message'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      type: map['type'] ?? 'general',
      deviceInfo: map['deviceInfo'],
    );
  }
}
