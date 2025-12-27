import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:uuid/uuid.dart';

import 'providers/import_providers.dart';
// import '../../../auth/presentation/providers/auth_providers.dart'; // Removed direct auth repo usage
import '../../../editor/presentation/providers/participant_providers.dart'; // Keep for existingParticipants reading? - used in goToPreview
import '../../../users/presentation/providers/user_providers.dart'; // Keep for currentUser
import '../../../events/presentation/providers/event_providers.dart'; // Keep for singleEventProvider (reading state)
import 'import_state.dart';

final importControllerProvider = NotifierProvider.family<ImportController, ImportState, String>(ImportController.new);

class ImportController extends Notifier<ImportState> {
  final String? _eventId;
  ImportController([this._eventId]);

  String get eventId => _eventId ?? (throw Exception('EventId not initialized'));

  @override
  ImportState build() {
    return ImportState(eventId: eventId);
  }

  void setSource(ImportSource source) {
    state = state.copyWith(source: source);
  }

  void addFile(PlatformFile file) {
    if (state.selectedItems.any((i) => i.name == file.name && i.type == ImportSource.file)) {
      return; // Prevent duplicates by name for now, or use ID if available
    }
    final item = ImportSourceItem(
      id: const Uuid().v4(),
      type: ImportSource.file,
      name: file.name,
      file: file,
    );
    state = state.copyWith(selectedItems: [...state.selectedItems, item]);
  }

  void addDriveFile(drive.File file, ImportSource source) {
     if (state.selectedItems.any((i) => i.id == file.id)) {
      return; 
    }
    final item = ImportSourceItem(
      id: file.id ?? const Uuid().v4(),
      type: source,
      name: file.name ?? 'Sem Nome',
      driveFile: file,
    );
    state = state.copyWith(selectedItems: [...state.selectedItems, item]);
  }

  void removeSourceItem(String id) {
    state = state.copyWith(
      selectedItems: state.selectedItems.where((i) => i.id != id).toList(),
    );
  }

  void clearSelection() {
    state = state.clearSelection();
  }

  Future<void> pickFile() async {
     await _requestPermission();
     try {
       FilePickerResult? result = await FilePicker.platform.pickFiles(
         type: FileType.custom,
         allowedExtensions: ['csv', 'xlsx', 'xls'],
       );

       if (result != null) {
         for (var file in result.files) {
           addFile(file);
         }
       }
     } catch (e) {
       _setError('Erro ao selecionar arquivo: $e');
     }
  }

  Future<bool> connectAndLoadForms() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final getDriveFiles = ref.read(getDriveFilesUseCaseProvider);
      final forms = await getDriveFiles.execute(isSpreadsheet: false);
      
      state = state.copyWith(
        availableDriveFiles: forms,
        isLoading: false
      );
      return true;
    } catch (e) {
      _setError('Erro ao conectar com Google Forms: $e');
    }
    state = state.copyWith(isLoading: false);
    return false;
  }

  Future<bool> connectAndLoadSheets() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final getDriveFiles = ref.read(getDriveFilesUseCaseProvider);
      final sheets = await getDriveFiles.execute(isSpreadsheet: true);
      
      state = state.copyWith(
        availableDriveFiles: sheets,
        isLoading: false
      );
      return true;
    } catch (e) {
      _setError('Erro ao conectar com Google Sheets: $e');
    }
    state = state.copyWith(isLoading: false);
    return false;
  }

  Future<bool> _requestPermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  void _setError(String msg) {
    state = state.copyWith(errorMessage: msg, isLoading: false);
  }
  
  void clearError() {
    state = state.clearError();
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }
  
  // Mapping Actions
  void updateMapping(String fieldId, String? header) {
    final newFields = state.mappingFields.map((f) {
      if (f.id == fieldId) {
        return f.copyWith(selectedHeader: header);
      }
      return f;
    }).toList();
    state = state.copyWith(mappingFields: newFields);
  }

  void addCustomColumn(String label) {
     final newField = MappingField(
       id: const Uuid().v4(),
       label: label,
       isCustom: true,
       selectedHeader: null, // User picks header after adding
     );
     state = state.copyWith(mappingFields: [...state.mappingFields, newField]);
  }

  void removeColumn(String fieldId) {
    state = state.copyWith(
      mappingFields: state.mappingFields.where((f) => f.id != fieldId).toList(),
    );
  }

  void renameColumn(String fieldId, String newLabel) {
     final newFields = state.mappingFields.map((f) {
      if (f.id == fieldId) {
        return f.copyWith(label: newLabel);
      }
      return f;
    }).toList();
    state = state.copyWith(mappingFields: newFields);
  }
  
  void reorderColumns(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final items = List<MappingField>.from(state.mappingFields);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = state.copyWith(mappingFields: items);
  }

  Future<void> processSource() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final getImportData = ref.read(getImportDataUseCaseProvider);
      // final authRepo = ref.read(authRepositoryProvider);
      
      List<Map<String, dynamic>> allData = [];
      Set<String> allHeaders = {};

      if (state.selectedItems.isEmpty) {
        throw Exception('Selecione pelo menos uma fonte de dados.');
      }

       for (var item in state.selectedItems) {
         List<Map<String, dynamic>> itemData = [];
         
         if (item.type == ImportSource.file && item.file != null) {
           itemData = await getImportData.execute(file: item.file);
         } else if ((item.type == ImportSource.googleForms || item.type == ImportSource.googleSheets) && item.driveFile != null) {
            final authUseCase = ref.read(requestGoogleAccessUseCaseProvider);
            final client = await authUseCase.execute();
            if (client != null) {
              if (item.type == ImportSource.googleForms) {
                 itemData = await getImportData.execute(authClient: client, formId: item.driveFile!.id!);
              } else {
                 itemData = await getImportData.execute(authClient: client, spreadsheetId: item.driveFile!.id!);
              }
            } else {
              throw Exception('Falha na autenticação Google para ${item.name}');
            }
         }
        
        if (itemData.isNotEmpty) {
          allData.addAll(itemData);
          if (itemData.first.isNotEmpty) {
             allHeaders.addAll(itemData.first.keys);
             // Note: ideally we check all rows for headers if schema varies, but for CSV usually first row is header.
             // But valid point: if second file has Diff headers, we need to collect them.
             // Ideally getImportData returns headers too. Assuming here keys are headers.
             // We should check all rows? Expensive. 
             // Let's assume common practice: all rows have same keys for a single file. 
             // But multiple files might have diff keys.
             // so allHeaders.addAll(itemData.first.keys) is correct per file.
          }
        }
      }

      if (allData.isEmpty) {
        throw Exception('Nenhum dado encontrado nas fontes selecionadas.');
      }
      
      final headersList = allHeaders.toList();
      state = state.copyWith(
        rawData: allData,
        headers: headersList,
        currentStep: 1,
        isLoading: false,
      );
      
      _autoMapColumns(headersList);
      
    } catch (e) {
      debugPrint('ImportController: processSource error: $e');
      _setError(e.toString());
    }
  }

  void _autoMapColumns(List<String> headers) {
    final useCase = ref.read(processImportUseCaseProvider);
    final suggestions = useCase.suggestMapping(headers);

    // Initial Standard Fields
    final standardFields = [
      const MappingField(id: 'name', label: 'Nome Completo', isRequired: true),
      const MappingField(id: 'email', label: 'Email', isRequired: true),
      const MappingField(id: 'phone', label: 'Telefone/WhatsApp'),
      const MappingField(id: 'ticketType', label: 'Tipo de Ingresso'),
      const MappingField(id: 'status', label: 'Status'),
      const MappingField(id: 'company', label: 'Empresa'),
      const MappingField(id: 'role', label: 'Cargo'),
      const MappingField(id: 'cpf', label: 'CPF/CNPJ'),
      const MappingField(id: 'checkinDate', label: 'Data Check-in'),
    ];

    List<MappingField> mappedFields = [];
    
    for (var field in standardFields) {
       // Apply suggestion if available
       final suggestedHeader = suggestions[field.id];
       mappedFields.add(field.copyWith(selectedHeader: suggestedHeader));
    }

    state = state.copyWith(mappingFields: mappedFields);
  }


  Future<void> goToPreview() async {
     state = state.copyWith(isLoading: true, errorMessage: null);

     try {
       // Prepare Mapping Map
       final Map<String, String> map = {};
       for (var f in state.mappingFields) {
         if (f.selectedHeader != null) {
           map[f.id] = f.selectedHeader!;
         }
       }

       final repository = ref.read(participantRepositoryProvider);
       final existingParticipants = await repository.getParticipantsByEvent(eventId);
       
       final useCase = ref.read(processImportUseCaseProvider);
       
       final newParticipants = useCase.execute(
         eventId: eventId,
         rawData: state.rawData,
         fieldMapping: map,
         existingParticipants: existingParticipants,
       );
       
       if (newParticipants.isEmpty) {
         _setError('Todos os participantes encontrados já estão cadastrados.');
         return;
       }

       state = state.copyWith(
         previewParticipants: newParticipants,
         currentStep: 2,
         isLoading: false,
       );
     } catch (e) {
       _setError('Erro ao processar dados: $e');
     }
  }

  Future<bool> finalizeImport() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final finalizeImportUseCase = ref.read(finalizeImportUseCaseProvider);
      final currentUser = ref.read(currentUserProvider).value;
      
      if (currentUser == null) {
        throw Exception('Usuário não autenticado.');
      }

      // Collect Import Mapping
      final Map<String, String> map = {};
      for (var f in state.mappingFields) {
        if (f.selectedHeader != null) {
          map[f.id] = f.selectedHeader!;
        }
      }
      
      // Determine Google Sheet ID if applicable for single source
      String? googleSheetId;
      if (state.selectedItems.length == 1) {
          final item = state.selectedItems.first;
           if ((item.type == ImportSource.googleForms || item.type == ImportSource.googleSheets) && item.driveFile != null) {
             googleSheetId = item.driveFile!.id;
           }
      }
      
      final eventAsync = ref.read(singleEventProvider(eventId));
      final event = eventAsync.value;

      await finalizeImportUseCase.execute(
        participants: state.previewParticipants, 
        eventId: eventId, 
        userId: currentUser.id,
        importMapping: map,
        event: event,
        googleSheetId: googleSheetId
      );

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      _setError('Erro ao salvar no banco de dados: $e');
      return false;
    }
  }
}
