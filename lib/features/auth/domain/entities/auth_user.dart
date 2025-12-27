
class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AuthUser &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoURL == photoURL;
  }

  @override
  int get hashCode {
    return uid.hashCode ^ email.hashCode ^ displayName.hashCode ^ photoURL.hashCode;
  }
}
