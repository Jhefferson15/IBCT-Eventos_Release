import '../../../editor/domain/models/participant_model.dart';

abstract class ICheckinRepository {
  Future<Participant?> getParticipantByToken(String token);
  Future<void> checkInParticipant(String participantId);
}
