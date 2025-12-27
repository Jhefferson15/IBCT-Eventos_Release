


class Event {
  final String? id;
  final String title;
  final DateTime date;
  final String description;
  final int participantCount;
  final String location;
  final String responsiblePersons;
  final String phoneWhatsApp;
  final String emergencyPhone;
  final String eventEmail;
  final String? creatorId;
  final String? googleSheetsUrl;
  final Map<String, String>? importMapping;
  final DateTime? lastSyncTime;
  final List<String> authorizedUsers;
  final List<String> customColumns;
  final List<String> visibleColumns;
  final Map<String, String>? storeSettings;

  Event({
    this.id,
    required this.title,
    required this.date,
    this.description = '',
    this.participantCount = 0,
    this.location = '',
    this.responsiblePersons = '',
    this.phoneWhatsApp = '',
    this.emergencyPhone = '',
    this.eventEmail = '',
    this.googleSheetsUrl,
    this.importMapping,
    this.lastSyncTime,
    this.creatorId,
    this.authorizedUsers = const [],
    this.customColumns = const [],
    this.visibleColumns = const [],
    this.storeSettings,
  });

  /// Returns true if event is archived (more than 7 days in the past)
  bool get isArchived {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return date.isBefore(weekAgo);
  }



  /// Create a copy of this event with some fields replaced
  Event copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? description,
    int? participantCount,
    String? location,
    String? responsiblePersons,
    String? phoneWhatsApp,
    String? emergencyPhone,
    String? eventEmail,
    String? googleSheetsUrl,
    Map<String, String>? importMapping,
    DateTime? lastSyncTime,
    String? creatorId,
    List<String>? authorizedUsers,
    List<String>? customColumns,
    List<String>? visibleColumns,
    Map<String, String>? storeSettings,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      description: description ?? this.description,
      participantCount: participantCount ?? this.participantCount,
      location: location ?? this.location,
      responsiblePersons: responsiblePersons ?? this.responsiblePersons,
      phoneWhatsApp: phoneWhatsApp ?? this.phoneWhatsApp,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      eventEmail: eventEmail ?? this.eventEmail,
      googleSheetsUrl: googleSheetsUrl ?? this.googleSheetsUrl,
      importMapping: importMapping ?? this.importMapping,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      creatorId: creatorId ?? this.creatorId,
      authorizedUsers: authorizedUsers ?? this.authorizedUsers,
      customColumns: customColumns ?? this.customColumns,
      visibleColumns: visibleColumns ?? this.visibleColumns,
      storeSettings: storeSettings ?? this.storeSettings,
    );
  }
}
