import 'package:ibct_eventos/core/interfaces/database_repository.dart';
import '../../../checkin/domain/repositories/checkin_repository_interface.dart';
import '../models/participant_model.dart';

abstract class IParticipantRepository implements DatabaseRepository<Participant>, ICheckinRepository {
  Future<List<Participant>> getParticipantsByEvent(String eventId);
  @override
  Future<Participant?> getParticipantByToken(String token);
  @override
  Future<void> checkInParticipant(String participantId);
  Future<void> createItemsBatch(List<Participant> items);
  Future<void> deleteItemsBatch(List<String> ids);
  Future<void> updateItemsBatch(List<Participant> items);
}
