import '../../../../core/utils/data_generator.dart';
import '../models/participant_model.dart';
import '../repositories/participant_repository_interface.dart';

class GenerateBulkTokensUseCase {
  final IParticipantRepository _repository;

  GenerateBulkTokensUseCase(this._repository);

  Future<void> execute(String eventId) async {
    final participants = await _repository.getParticipantsByEvent(eventId);
    final List<Participant> toUpdate = [];

    for (var p in participants) {
      if (p.token.isEmpty) {
        toUpdate.add(p.copyWith(token: DataGenerator.generateToken(eventId)));
      }
    }

    if (toUpdate.isNotEmpty) {
      await _repository.updateItemsBatch(toUpdate);
    }
  }
}

class GenerateBulkPasswordsUseCase {
  final IParticipantRepository _repository;

  GenerateBulkPasswordsUseCase(this._repository);

  Future<void> execute(String eventId) async {
    final participants = await _repository.getParticipantsByEvent(eventId);
    final List<Participant> toUpdate = [];

    for (var p in participants) {
      if (p.password.isEmpty) {
        toUpdate.add(p.copyWith(password: DataGenerator.generatePassword()));
      }
    }

    if (toUpdate.isNotEmpty) {
      await _repository.updateItemsBatch(toUpdate);
    }
  }
}

class AssignSequentialIdsUseCase {
  final IParticipantRepository _repository;

  AssignSequentialIdsUseCase(this._repository);

  Future<void> execute(String eventId) async {
    final participants = await _repository.getParticipantsByEvent(eventId);
    // Sort by name or current ID if exists
    participants.sort((a, b) => a.name.compareTo(b.name));
    
    final List<Participant> toUpdate = [];
    int startId = 1;

    for (var i = 0; i < participants.length; i++) {
       // Only assign if it doesn't look like a real ID or force all? 
       // User said "Atribuir IDs". Usually means re-sequencing or filling gaps.
       // Let's assume filling gaps or overwriting if they are just random.
       // To be safe, let's just assign sequence 1, 2, 3...
       toUpdate.add(participants[i].copyWith(externalId: (startId + i).toString().padLeft(4, '0')));
    }

    if (toUpdate.isNotEmpty) {
      await _repository.updateItemsBatch(toUpdate);
    }
  }
}
