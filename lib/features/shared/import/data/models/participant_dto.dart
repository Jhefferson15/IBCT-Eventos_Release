import 'package:ibct_eventos/features/editor/domain/models/participant_model.dart';

class ParticipantDto extends Participant {
  ParticipantDto({
    required super.id,
    required super.eventId,
    required super.name,
    required super.email,
    required super.phone,
    required super.ticketType,
    required super.status,
    super.isCheckedIn = false,
    super.checkInTime,
    required super.token,
    super.password = '',
    super.externalId = '',
    super.customFields = const {},
    super.company,
    super.role,
    super.cpf,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'name': name,
      'email': email,
      'phone': phone,
      'ticketType': ticketType,
      'status': status,
      'isCheckedIn': isCheckedIn,
      'checkInTime': checkInTime?.toIso8601String(),
      'token': token,
      'password': password,
      'externalId': externalId,
      'customFields': customFields,
      'company': company,
      'role': role,
      'cpf': cpf,
    };
  }

  factory ParticipantDto.fromMap(Map<String, dynamic> map, String id) {
    return ParticipantDto(
      id: id,
      eventId: map['eventId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      ticketType: map['ticketType'] ?? 'Standard',
      status: map['status'] ?? 'Pendente',
      isCheckedIn: map['isCheckedIn'] ?? false,
      checkInTime: map['checkInTime'] != null
          ? DateTime.tryParse(map['checkInTime'])
          : null,
      token: map['token'] ?? '',
      password: map['password'] ?? '',
      externalId: map['externalId'] ?? '',
      customFields: Map<String, dynamic>.from(map['customFields'] ?? {}),
      company: map['company'],
      role: map['role'],
      cpf: map['cpf'],
    );
  }

  factory ParticipantDto.fromDomain(Participant participant) {
    return ParticipantDto(
      id: participant.id,
      eventId: participant.eventId,
      name: participant.name,
      email: participant.email,
      phone: participant.phone,
      ticketType: participant.ticketType,
      status: participant.status,
      isCheckedIn: participant.isCheckedIn,
      checkInTime: participant.checkInTime,
      token: participant.token,
      password: participant.password,
      externalId: participant.externalId,
      customFields: participant.customFields,
      company: participant.company,
      role: participant.role,
      cpf: participant.cpf,
    );
  }
}
