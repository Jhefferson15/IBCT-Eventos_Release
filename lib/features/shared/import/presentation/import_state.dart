
import 'package:file_picker/file_picker.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../../../editor/domain/models/participant_model.dart';

enum ImportSource { file, googleForms, googleSheets }


class MappingField {
  final String id;
  final String label;
  final String? selectedHeader;
  final bool isRequired;
  final bool isCustom;

  const MappingField({
    required this.id,
    required this.label,
    this.selectedHeader,
    this.isRequired = false,
    this.isCustom = false,
  });

  MappingField copyWith({
    String? id,
    String? label,
    String? selectedHeader,
    bool? isRequired,
    bool? isCustom,
  }) {
    return MappingField(
      id: id ?? this.id,
      label: label ?? this.label,
      selectedHeader: selectedHeader ?? this.selectedHeader,
      isRequired: isRequired ?? this.isRequired,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

class ImportSourceItem {
  final String id;
  final ImportSource type;
  final String name;
  final PlatformFile? file;
  final drive.File? driveFile;

  const ImportSourceItem({
    required this.id,
    required this.type,
    required this.name,
    this.file,
    this.driveFile,
  });
}

class ImportState {
  final int currentStep;
  final ImportSource source; // Acts as "Current Tab" in UI
  final List<ImportSourceItem> selectedItems;
  final List<drive.File> availableDriveFiles; // For selection dialog
  final List<Map<String, dynamic>> rawData;
  final List<String> headers;
  final List<MappingField> mappingFields;
  final List<Participant> previewParticipants;
  final bool isLoading;
  final String? errorMessage;
  final String eventId;

  const ImportState({
    this.currentStep = 0,
    this.source = ImportSource.file,
    this.selectedItems = const [],
    this.availableDriveFiles = const [],
    this.rawData = const [],
    this.headers = const [],
    this.mappingFields = const [],
    this.previewParticipants = const [],
    this.isLoading = false,
    this.errorMessage,
    required this.eventId,
  });

  ImportState copyWith({
    int? currentStep,
    ImportSource? source,
    List<ImportSourceItem>? selectedItems,
    List<drive.File>? availableDriveFiles,
    List<Map<String, dynamic>>? rawData,
    List<String>? headers,
    List<MappingField>? mappingFields,
    List<Participant>? previewParticipants,
    bool? isLoading,
    String? errorMessage,
    String? eventId,
  }) {
    return ImportState(
      currentStep: currentStep ?? this.currentStep,
      source: source ?? this.source,
      selectedItems: selectedItems ?? this.selectedItems,
      availableDriveFiles: availableDriveFiles ?? this.availableDriveFiles,
      rawData: rawData ?? this.rawData,
      headers: headers ?? this.headers,
      mappingFields: mappingFields ?? this.mappingFields,
      previewParticipants: previewParticipants ?? this.previewParticipants,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, 
      eventId: eventId ?? this.eventId,
    );
  }
  
  ImportState clearError() {
    return ImportState(
      currentStep: currentStep,
      source: source,
      selectedItems: selectedItems,
      availableDriveFiles: availableDriveFiles,
      rawData: rawData,
      headers: headers,
      mappingFields: mappingFields,
      previewParticipants: previewParticipants,
      isLoading: isLoading,
      errorMessage: null,
      eventId: eventId,
    );
  }

  ImportState clearSelection() {
    return ImportState(
      currentStep: currentStep,
      source: source,
      availableDriveFiles: availableDriveFiles,
      eventId: eventId,
      // Reset everything else related to the selected data
      selectedItems: const [],
      rawData: const [],
      headers: const [],
      mappingFields: const [],
      previewParticipants: const [],
      isLoading: false,
      errorMessage: null,
    );
  }
}
