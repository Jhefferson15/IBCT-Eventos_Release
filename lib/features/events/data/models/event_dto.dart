import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/event_model.dart';

class EventDto extends Event {
  EventDto({
    super.id,
    required super.title,
    required super.date,
    super.description = '',
    super.participantCount = 0,
    super.location = '',
    super.responsiblePersons = '',
    super.phoneWhatsApp = '',
    super.emergencyPhone = '',
    super.eventEmail = '',
    super.googleSheetsUrl,
    super.importMapping,
    super.lastSyncTime,
    super.creatorId,
    super.authorizedUsers = const [],
    super.customColumns = const [],
    super.visibleColumns = const [],
    super.storeSettings,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'description': description,
      'participant_count': participantCount,
      'location': location,
      'responsible_persons': responsiblePersons,
      'phone_whatsapp': phoneWhatsApp,
      'emergency_phone': emergencyPhone,
      'event_email': eventEmail,
      'google_sheets_url': googleSheetsUrl,
      'import_mapping': importMapping,
      'last_sync_time': lastSyncTime != null ? Timestamp.fromDate(lastSyncTime!) : null,
      'creator_id': creatorId,
      'authorized_users': authorizedUsers,
      'custom_columns': customColumns,
      'visible_columns': visibleColumns,
      'store_settings': storeSettings,
    };
  }

  factory EventDto.fromMap(Map<String, dynamic> map, String id) {
    return EventDto(
      id: id,
      title: map['title'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      description: map['description'] ?? '',
      participantCount: map['participant_count']?.toInt() ?? 0,
      location: map['location'] ?? '',
      responsiblePersons: map['responsible_persons'] ?? '',
      phoneWhatsApp: map['phone_whatsapp'] ?? '',
      emergencyPhone: map['emergency_phone'] ?? '',
      eventEmail: map['event_email'] ?? '',
      googleSheetsUrl: map['google_sheets_url'],
      importMapping: (map['import_mapping'] as Map<String, dynamic>?)?.cast<String, String>(),
      lastSyncTime: map['last_sync_time'] != null ? (map['last_sync_time'] as Timestamp).toDate() : null,
      creatorId: map['creator_id'],
      authorizedUsers: (map['authorized_users'] as List<dynamic>?)?.cast<String>() ?? [],
      customColumns: (map['custom_columns'] as List<dynamic>?)?.cast<String>() ?? [],
      visibleColumns: (map['visible_columns'] as List<dynamic>?)?.cast<String>() ?? [],
      storeSettings: (map['store_settings'] as Map<String, dynamic>?)?.cast<String, String>(),
    );
  }

  factory EventDto.fromDomain(Event event) {
    return EventDto(
      id: event.id,
      title: event.title,
      date: event.date,
      description: event.description,
      participantCount: event.participantCount,
      location: event.location,
      responsiblePersons: event.responsiblePersons,
      phoneWhatsApp: event.phoneWhatsApp,
      emergencyPhone: event.emergencyPhone,
      eventEmail: event.eventEmail,
      googleSheetsUrl: event.googleSheetsUrl,
      importMapping: event.importMapping,
      lastSyncTime: event.lastSyncTime,
      creatorId: event.creatorId,
      authorizedUsers: event.authorizedUsers,
      customColumns: event.customColumns,
      visibleColumns: event.visibleColumns,
      storeSettings: event.storeSettings,
    );
  }
}
