import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_participant_repository.dart';
import '../../domain/models/participant_model.dart';
import '../../domain/repositories/participant_repository_interface.dart';
import '../../domain/usecases/create_participant_usecase.dart';
import '../../domain/usecases/update_participant_usecase.dart';
import '../../domain/usecases/delete_participants_usecase.dart';
import '../../domain/usecases/batch_actions_use_cases.dart';
import '../../../users/presentation/providers/activity_log_provider.dart';


// Repository Provider
final participantRepositoryProvider = Provider<IParticipantRepository>((ref) {
  return FirestoreParticipantRepository();
});

final createParticipantUseCaseProvider = Provider<CreateParticipantUseCase>((ref) {
  final repository = ref.watch(participantRepositoryProvider);
  final logActivityUseCase = ref.watch(logActivityUseCaseProvider);
  return CreateParticipantUseCase(repository, logActivityUseCase);
});

final updateParticipantUseCaseProvider = Provider<UpdateParticipantUseCase>((ref) {
  final repository = ref.watch(participantRepositoryProvider);
  final logActivityUseCase = ref.watch(logActivityUseCaseProvider);
  return UpdateParticipantUseCase(repository, logActivityUseCase);
});

final deleteParticipantsUseCaseProvider = Provider<DeleteParticipantsUseCase>((ref) {
  final repository = ref.watch(participantRepositoryProvider);
  final logActivityUseCase = ref.watch(logActivityUseCaseProvider);
  return DeleteParticipantsUseCase(repository, logActivityUseCase);
});

final generateBulkTokensUseCaseProvider = Provider<GenerateBulkTokensUseCase>((ref) {
  final repository = ref.watch(participantRepositoryProvider);
  return GenerateBulkTokensUseCase(repository);
});

final generateBulkPasswordsUseCaseProvider = Provider<GenerateBulkPasswordsUseCase>((ref) {
  final repository = ref.watch(participantRepositoryProvider);
  return GenerateBulkPasswordsUseCase(repository);
});

final assignSequentialIdsUseCaseProvider = Provider<AssignSequentialIdsUseCase>((ref) {
  final repository = ref.watch(participantRepositoryProvider);
  return AssignSequentialIdsUseCase(repository);
});

// Controller for managing the list of participants (CRUD)
final participantsControllerProvider = AsyncNotifierProvider.family<ParticipantsController, List<Participant>, String>(ParticipantsController.new);

class ParticipantsController extends AsyncNotifier<List<Participant>> {
  final String eventId;
  ParticipantsController(this.eventId);

  late final IParticipantRepository _repository;
  late final CreateParticipantUseCase _createUseCase;
  late final UpdateParticipantUseCase _updateUseCase;
  late final DeleteParticipantsUseCase _deleteUseCase;

  @override
  Future<List<Participant>> build() async {
    _repository = ref.watch(participantRepositoryProvider);
    _createUseCase = ref.watch(createParticipantUseCaseProvider);
    _updateUseCase = ref.watch(updateParticipantUseCaseProvider);
    _deleteUseCase = ref.watch(deleteParticipantsUseCaseProvider);
    
    return _repository.getParticipantsByEvent(eventId);
  }

  Future<void> addParticipant(Participant participant, String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _createUseCase.call(participant, userId);
      return _repository.getParticipantsByEvent(eventId);
    });
  }

  Future<void> updateParticipant(Participant participant, String userId) async {
    // Optimistic update could be done here, but for now simple reload
    // To do optimistic: update 'state' with new list
    final previousState = state.value;
    if (previousState != null) {
       final index = previousState.indexWhere((p) => p.id == participant.id);
       if (index != -1) {
         final newList = List<Participant>.from(previousState);
         newList[index] = participant;
         state = AsyncValue.data(newList);
       }
    }
    
    // Perform actual update
    try {
      await _updateUseCase.call(participant, userId);
    } catch (e, stack) {
      // Revert on error
      state = AsyncValue.error(e, stack);
      // refetch
      state = await AsyncValue.guard(() => _repository.getParticipantsByEvent(eventId));
    }
  }

  Future<void> deleteParticipants(List<String> ids, String userId) async {
    final previousState = state.value;
    if (previousState != null) {
       final newList = previousState.where((p) => !ids.contains(p.id)).toList();
       state = AsyncValue.data(newList);
    }

    try {
      await _deleteUseCase.call(ids, eventId, userId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      state = await AsyncValue.guard(() => _repository.getParticipantsByEvent(eventId));
    }
  }
  
  Future<void> generateTokens() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(generateBulkTokensUseCaseProvider);
      await useCase.execute(eventId);
      return _repository.getParticipantsByEvent(eventId);
    });
  }

  Future<void> generatePasswords() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(generateBulkPasswordsUseCaseProvider);
      await useCase.execute(eventId);
      return _repository.getParticipantsByEvent(eventId);
    });
  }

  Future<void> assignSequentialIds() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(assignSequentialIdsUseCaseProvider);
      await useCase.execute(eventId);
      return _repository.getParticipantsByEvent(eventId);
    });
  }

  Future<void> bulkUpdateStatus(List<String> ids, String status, String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final participants = await _repository.getParticipantsByEvent(eventId);
      final List<Participant> toUpdate = [];
      for (var id in ids) {
        final p = participants.firstWhere((p) => p.id == id);
        toUpdate.add(p.copyWith(
          status: status,
          isCheckedIn: status == 'Presente',
          checkInTime: status == 'Presente' ? DateTime.now() : p.checkInTime,
        ));
      }
      await _repository.updateItemsBatch(toUpdate);
      return _repository.getParticipantsByEvent(eventId);
    });
  }

  Future<void> refresh() async {
     state = const AsyncValue.loading();
     state = await AsyncValue.guard(() => _repository.getParticipantsByEvent(eventId));
  }
}


