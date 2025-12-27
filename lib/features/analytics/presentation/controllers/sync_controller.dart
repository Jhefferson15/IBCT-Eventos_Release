import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibct_eventos/features/auth/presentation/providers/auth_providers.dart';
import 'package:ibct_eventos/features/editor/presentation/providers/participant_providers.dart';
import 'package:ibct_eventos/features/events/presentation/providers/event_providers.dart';
import 'package:ibct_eventos/features/shared/import/presentation/providers/import_providers.dart';

class SyncController extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  Future<Map<String, dynamic>> syncParticipants(String eventId) async {
    state = true;
    try {
      final eventAsync = ref.read(singleEventProvider(eventId));
      final event = eventAsync.value;

      if (event == null ||
          event.googleSheetsUrl == null ||
          event.importMapping == null) {
        throw Exception('Configuração de integração inválida.');
      }

      // 1. Fetch Data
      List<Map<String, dynamic>> rawData = [];
      final source = event.googleSheetsUrl!;
      final isUrl = source.startsWith('http');
      final getImportData = ref.read(getImportDataUseCaseProvider);

      if (isUrl) {
        rawData = await getImportData.execute(googleSheetsUrl: source);
      } else {
        final authRepo = ref.read(authRepositoryProvider);
        final client = await authRepo.requestFormsAccess();

        if (client != null) {
          rawData = await getImportData.execute(authClient: client, formId: source);
        } else {
          throw Exception('Permissão negada para acessar o Formulário.');
        }
      }

      // 2. Fetch existing
      final currentParticipantsAsync =
          ref.read(participantsControllerProvider(eventId));
      final existingParticipants = currentParticipantsAsync.value ?? [];

      // 3. Process
      final processImportUseCase = ref.read(processImportUseCaseProvider);
      final newParticipants = processImportUseCase.execute(
          eventId: eventId,
          rawData: rawData,
          fieldMapping: event.importMapping!,
          existingParticipants: existingParticipants);

      // 4. Save
      if (newParticipants.isNotEmpty) {
        final repository = ref.read(participantRepositoryProvider);
        await repository.createItemsBatch(newParticipants);
      }

      // 5. Update Event Metadata
      final totalCount = (existingParticipants.length + newParticipants.length);
      final eventRepo = ref.read(eventRepositoryProvider);

      await eventRepo.updateItem(event.copyWith(
        lastSyncTime: DateTime.now(),
        participantCount: totalCount.toInt(),
      ));
      
      return {
        'success': true,
        'newCount': newParticipants.length,
      };

    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    } finally {
      state = false;
    }
  }
}

final syncControllerProvider = NotifierProvider<SyncController, bool>(SyncController.new);
