
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibct_eventos/features/events/domain/models/event_model.dart';
import 'package:ibct_eventos/features/events/presentation/providers/event_providers.dart';
import 'package:ibct_eventos/features/users/presentation/providers/activity_log_provider.dart';
import '../../domain/usecases/create_event_usecase.dart';
import '../../domain/usecases/update_event_usecase.dart';

import 'package:ibct_eventos/features/users/presentation/providers/user_providers.dart'; // Added for currentUserProvider

// UseCase Providers
final createEventUseCaseProvider = Provider<CreateEventUseCase>((ref) {
  final eventRepository = ref.watch(eventRepositoryProvider);
  final logActivityUseCase = ref.watch(logActivityUseCaseProvider);
  return CreateEventUseCase(eventRepository, logActivityUseCase);
});

final updateEventUseCaseProvider = Provider<UpdateEventUseCase>((ref) {
  final eventRepository = ref.watch(eventRepositoryProvider);
  final logActivityUseCase = ref.watch(logActivityUseCaseProvider);
  return UpdateEventUseCase(eventRepository, logActivityUseCase);
});

enum MutationStatus { initial, loading, success, error }

class MutationState {
  final MutationStatus status;
  final String? resultId; // For creation
  final String? errorMessage;

  const MutationState({
    this.status = MutationStatus.initial,
    this.resultId,
    this.errorMessage,
  });
}


class EventMutationController extends Notifier<MutationState> {
  @override
  MutationState build() => const MutationState();

  Future<void> createEvent(Event event) async {
    state = const MutationState(status: MutationStatus.loading);
    try {
      final createUseCase = ref.watch(createEventUseCaseProvider);
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) throw Exception("Usuário não autenticado");
      
      final docId = await createUseCase(event, currentUser.id);
      ref.invalidate(eventsProvider);
      state = MutationState(status: MutationStatus.success, resultId: docId);
    } catch (e) {
      state = MutationState(status: MutationStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> updateEvent(Event event) async {
    state = const MutationState(status: MutationStatus.loading);
    try {
      final updateUseCase = ref.watch(updateEventUseCaseProvider);
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) throw Exception("Usuário não autenticado");

      await updateUseCase(event, currentUser.id);
      ref.invalidate(eventsProvider);
      if (event.id != null) {
        ref.invalidate(singleEventProvider(event.id!));
      }
      state = const MutationState(status: MutationStatus.success);
    } catch (e) {
      state = MutationState(status: MutationStatus.error, errorMessage: e.toString());
    }
  }

  void reset() {
    state = const MutationState();
  }
}

final eventMutationControllerProvider = NotifierProvider<EventMutationController, MutationState>(() {
  return EventMutationController();
});
