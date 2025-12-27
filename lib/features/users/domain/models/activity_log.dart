
enum ActivityActionType {
  // Auth
  login,
  logout,
  
  // Event Management
  createEvent,
  updateEvent,
  deleteEvent,
  
  // Participant Management
  addParticipant,
  updateParticipant,
  importParticipants,
  deleteParticipant,
  checkInParticipant,
  
  // Team Management
  addHelper,
  removeHelper,
  
  // Store
  productCreate,
  productUpdate,
  productDelete,
  sale,
  
  // Surveys
  surveyCreate,
  surveyAnswer,
  
  // User Profile
  profileUpdate,
  
  unknown,
}

class ActivityLog {
  final String id;
  final String userId; // Changed from adminId to userId to be more inclusive
  final ActivityActionType actionType;
  final String targetId;
  final String targetType; // 'event', 'participant', 'user', 'transaction', etc.
  final Map<String, dynamic> details;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.userId,
    required this.actionType,
    required this.targetId,
    required this.targetType,
    required this.details,
    required this.timestamp,
  });
}
