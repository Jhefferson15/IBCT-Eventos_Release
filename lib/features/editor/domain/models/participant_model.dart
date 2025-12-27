import 'package:flutter/foundation.dart';


class Participant {
  final String id;
  final String eventId;
  final String name;
  final String email;
  final String phone;
  final String ticketType;
  final String status;
  final bool isCheckedIn;
  final DateTime? checkInTime;
  final String token;
  final String password;
  final String externalId;
  final Map<String, dynamic> customFields;
  final String? company;
  final String? role;
  final String? cpf;

  Participant({
    required this.id,
    required this.eventId,
    required this.name,
    required this.email,
    required this.phone,
    required this.ticketType,
    required this.status,
    this.isCheckedIn = false,
    this.checkInTime,
    required this.token,
    this.password = '',
    this.externalId = '',
    this.customFields = const {},
    this.company,
    this.role,
    this.cpf,
  });



  Participant copyWith({
    String? id,
    String? eventId,
    String? name,
    String? email,
    String? phone,
    String? ticketType,
    String? status,
    bool? isCheckedIn,
    DateTime? checkInTime,
    String? token,
    String? password,
    String? externalId,
    Map<String, dynamic>? customFields,
    String? company,
    String? role,
    String? cpf,
  }) {
    return Participant(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      ticketType: ticketType ?? this.ticketType,
      status: status ?? this.status,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      checkInTime: checkInTime ?? this.checkInTime,
      token: token ?? this.token,
      password: password ?? this.password,
      externalId: externalId ?? this.externalId,
      customFields: customFields ?? this.customFields,
      company: company ?? this.company,
      role: role ?? this.role,
      cpf: cpf ?? this.cpf,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Participant &&
      other.id == id &&
      other.eventId == eventId &&
      other.name == name &&
      other.email == email &&
      other.phone == phone &&
      other.ticketType == ticketType &&
      other.status == status &&
      other.isCheckedIn == isCheckedIn &&
      other.checkInTime == checkInTime &&
      other.token == token &&
      other.password == password &&
      other.externalId == externalId &&
      mapEquals(other.customFields, customFields) &&
      other.company == company &&
      other.cpf == cpf;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      eventId.hashCode ^
      name.hashCode ^
      email.hashCode ^
      phone.hashCode ^
      ticketType.hashCode ^
      status.hashCode ^
      isCheckedIn.hashCode ^
      checkInTime.hashCode ^
      token.hashCode ^
      password.hashCode ^
      externalId.hashCode ^
      company.hashCode ^
      role.hashCode ^
      cpf.hashCode;
  }
}
