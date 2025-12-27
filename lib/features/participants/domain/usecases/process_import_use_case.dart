
import 'package:uuid/uuid.dart';
import '../../../editor/domain/models/participant_model.dart';

class ProcessImportUseCase {
  
  /// Suggests a mapping of Field IDs to Header Names based on heuristics.
  Map<String, String> suggestMapping(List<String> headers) {
    final mapping = <String, String>{};
    
    // Define standard fields and their match logic (could be more flexible in future)
    final fields = ['name', 'email', 'phone', 'ticketType', 'status', 'company', 'role', 'cpf', 'checkinDate'];

    for (var fieldId in fields) {
      for (var header in headers) {
        if (_isMatch(fieldId, header)) {
          mapping[fieldId] = header;
          break; // Match first valid header
        }
      }
    }
    return mapping;
  }

  bool _isMatch(String fieldId, String header) {
    String h = header.toLowerCase();
    switch (fieldId) {
      case 'name': return h.contains('nome') || h.contains('name');
      case 'email': return h.contains('mail');
      case 'phone': return h.contains('tel') || h.contains('cel') || h.contains('what') || h.contains('zap');
      case 'ticketType': return h.contains('ingresso') || h.contains('ticket') || h.contains('tipo');
      case 'status': return h.contains('status') || h.contains('situa');
      case 'company': return h.contains('empresa') || h.contains('company') || h.contains('organization');
      case 'role': return h.contains('cargo') || h.contains('role') || h.contains('position') || h.contains('job');
      case 'cpf': return h.contains('cpf') || h.contains('doc') || h.contains('cnpj');
      case 'checkinDate': return h.contains('check-in') || h.contains('checkin') || h.contains('entrada');
      default: return false;
    }
  }

  /// Processes raw data into new unique Participants.
  /// 
  /// [eventId]: The ID of the event.
  /// [rawData]: The List of Maps from the file/source.
  /// [fieldMapping]: Map of Field ID -> Header Name.
  /// [existingParticipants]: List of current participants to check against for duplicates.
  List<Participant> execute({
    required String eventId,
    required List<Map<String, dynamic>> rawData,
    required Map<String, String> fieldMapping,
    required List<Participant> existingParticipants,
  }) {
    // 1. Convert to Participant Objects
    final candidates = _processParticipants(
      eventId: eventId,
      rawData: rawData,
      mapping: fieldMapping,
    );

    // 2. Filter Duplicates
    return _filterDuplicates(candidates, existingParticipants);
  }

  List<Participant> _processParticipants({
    required String eventId,
    required List<Map<String, dynamic>> rawData,
    required Map<String, String> mapping,
  }) {
    return rawData.map((row) {
      // Helper to get value based on mapping
      String getValue(String fieldId) {
        final mappedHeader = mapping[fieldId];
        if (mappedHeader != null && row.containsKey(mappedHeader)) {
           return row[mappedHeader]?.toString() ?? '';
        }
        return '';
      }
      
      final stdKeys = {'name', 'email', 'phone', 'ticketType', 'status', 'company', 'role', 'cpf', 'checkinDate'};
      final customFields = <String, dynamic>{};
      
      // 1. Process Explicit Mappings (Standard + Custom)
      mapping.forEach((key, header) {
         if (!stdKeys.contains(key)) {
           if (row.containsKey(header)) {
             customFields[key] = row[header]?.toString() ?? '';
           }
         }
      });
      
      // 2. Process Leftovers (Unmapped columns)
      final mappedHeaders = mapping.values.toSet();
      row.forEach((key, value) {
        if (!mappedHeaders.contains(key)) {
          customFields[key] = value?.toString() ?? '';
        }
      });

      return Participant(
        id: '', // Generated later or by DB
        eventId: eventId,
        name: getValue('name'),
        email: getValue('email').trim(),
        phone: getValue('phone').trim(),
        ticketType: getValue('ticketType').isNotEmpty ? getValue('ticketType') : 'Standard',
        status: getValue('status').isNotEmpty ? getValue('status') : 'Pendente',
        token: const Uuid().v4(), // Business logic: New participant gets a token
        customFields: customFields,
        company: getValue('company').isNotEmpty ? getValue('company') : null,
        role: getValue('role').isNotEmpty ? getValue('role') : null,
        cpf: getValue('cpf').isNotEmpty ? getValue('cpf') : null,
        isCheckedIn: getValue('checkinDate').isNotEmpty,
        checkInTime: getValue('checkinDate').isNotEmpty 
            ? DateTime.tryParse(getValue('checkinDate')) 
            : null,
      );
    }).toList();
  }

  List<Participant> _filterDuplicates(List<Participant> candidates, List<Participant> existing) {
    
    final existingEmails = existing
        .where((p) => p.email.isNotEmpty)
        .map((p) => p.email.toLowerCase())
        .toSet();
        
    final existingPhones = existing
        .where((p) => p.phone.isNotEmpty)
        .map((p) => p.phone.replaceAll(RegExp(r'\D'), '')) 
        .toSet();

    final uniqueNewParticipants = <Participant>[];

    for (var p in candidates) {
      final pEmail = p.email.toLowerCase();
      final pPhone = p.phone.replaceAll(RegExp(r'\D'), '');

      bool isDuplicate = false;
      
      if (pEmail.isNotEmpty && existingEmails.contains(pEmail)) {
        isDuplicate = true;
      }
      
      if (!isDuplicate && pPhone.isNotEmpty && existingPhones.contains(pPhone)) {
        isDuplicate = true;
      }

      if (!isDuplicate) {
        uniqueNewParticipants.add(p);
      }
    }
    
    return uniqueNewParticipants;
  }
}
