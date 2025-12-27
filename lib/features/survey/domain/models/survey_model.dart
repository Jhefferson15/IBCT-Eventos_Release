
class SurveyResponse {
  final String id;
  final String userId;
  final String userEmail;
  final Map<String, dynamic> answers;
  final DateTime timestamp;

  SurveyResponse({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.answers,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'answers': answers,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SurveyResponse.fromMap(Map<String, dynamic> map) {
    return SurveyResponse(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      answers: Map<String, dynamic>.from(map['answers'] ?? {}),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SurveyResponse && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
