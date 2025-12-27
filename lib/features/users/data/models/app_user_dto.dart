import '../../domain/models/app_user.dart';

class AppUserDto extends AppUser {
  AppUserDto({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.createdBy,
    super.isFirstLogin = false,
    required super.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'created_by': createdBy,
      'is_first_login': isFirstLogin,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppUserDto.fromMap(Map<String, dynamic> map) {
    return AppUserDto(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.participant,
      ),
      createdBy: map['created_by'],
      isFirstLogin: map['is_first_login'] ?? false,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
    );
  }

  factory AppUserDto.fromDomain(AppUser user) {
    return AppUserDto(
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      createdBy: user.createdBy,
      isFirstLogin: user.isFirstLogin,
      createdAt: user.createdAt,
    );
  }
}
