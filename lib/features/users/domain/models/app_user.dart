
enum UserRole {
  admin,      // Total access to created events and linked forms
  helper,     // Access only to assigned events
  participant // Access only to own data and history
}

class AppUser {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? createdBy; // ID of the admin who created this user (for helpers)
  final bool isFirstLogin; // Forces password change on first login
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.createdBy,
    this.isFirstLogin = false,
    required this.createdAt,
  });



  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? createdBy,
    bool? isFirstLogin,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdBy: createdBy ?? this.createdBy,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
