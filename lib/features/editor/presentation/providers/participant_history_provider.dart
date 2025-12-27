import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/participant_model.dart';
import '../providers/participant_providers.dart';

// Abstract Command Interface
abstract class HistoryCommand {
  Future<void> execute();
  Future<void> undo();
}

// Concrete Command for updating participant
class UpdateParticipantCommand implements HistoryCommand {
  final Participant oldParticipant;
  final Participant newParticipant;
  final String userId;
  final ParticipantsController controller;

  UpdateParticipantCommand(this.controller, this.userId, this.oldParticipant, this.newParticipant);

  @override
  Future<void> execute() async {
    await controller.updateParticipant(newParticipant, userId);
  }

  @override
  Future<void> undo() async {
    await controller.updateParticipant(oldParticipant, userId);
  }
}

// History State
class HistoryState {
  final List<HistoryCommand> undoStack;
  final List<HistoryCommand> redoStack;

  const HistoryState({
    this.undoStack = const [],
    this.redoStack = const [],
  });
  
  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  HistoryState copyWith({
    List<HistoryCommand>? undoStack,
    List<HistoryCommand>? redoStack,
  }) {
    return HistoryState(
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
    );
  }
}

class HistoryNotifier extends Notifier<HistoryState> {
  @override
  HistoryState build() {
    return const HistoryState();
  }

  Future<void> execute(HistoryCommand command) async {
    // Optimistic execution or wait? 
    // Usually spreadsheet is optimistic. But we rely on backend.
    // Let's execute.
    await command.execute();
    
    // Add to undo stack, clear redo stack
    state = state.copyWith(
      undoStack: [...state.undoStack, command],
      redoStack: [],
    );
  }

  Future<void> undo() async {
    if (!state.canUndo) return;

    final command = state.undoStack.last;
    final newUndo = List<HistoryCommand>.from(state.undoStack)..removeLast();
    
    await command.undo();

    state = state.copyWith(
      undoStack: newUndo,
      redoStack: [...state.redoStack, command],
    );
  }

  Future<void> redo() async {
    if (!state.canRedo) return;
    
    final command = state.redoStack.last;
    final newRedo = List<HistoryCommand>.from(state.redoStack)..removeLast();
    
    await command.execute();

    state = state.copyWith(
      undoStack: [...state.undoStack, command],
      redoStack: newRedo,
    );
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, HistoryState>(HistoryNotifier.new);
