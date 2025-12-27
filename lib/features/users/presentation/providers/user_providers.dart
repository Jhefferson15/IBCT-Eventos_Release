import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/app_user.dart';
import 'user_di.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final currentUserStreamProvider = StreamProvider<AppUser?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);

  return authRepository.authStateChanges.asyncMap((firebaseUser) async {
    if (firebaseUser == null) return null;

    final appUser = await userRepository.getUser(firebaseUser.uid);
    if (appUser != null) {
      // User exists, just return it. 
      // The logic "prevails highest privilege" is implicit: we don't overwrite the existing user 
      // just because they signed in with Google. If they were created as Admin/Helper by another admin, 
      // their row in Firestore has that role, and we keep it.
      return appUser;
    } else {
      // New user via Google Sign In (or first time DB access)
      // Default to Participant
      
      // Check if this user might have been created via Email/Pass with a higher role 
      // but somehow the ID changed? Unlikely with Firebase Auth linking.
      // We assume if doc doesn't exist, it's a new participant.
      
      final newUser = AppUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? 'Usuário',
        role: UserRole.participant, // Default role
        createdAt: DateTime.now(),
      );
      await userRepository.createUser(newUser);
      return newUser;
    }
  });
});

final currentUserProvider = Provider<AsyncValue<AppUser?>>((ref) {
  return ref.watch(currentUserStreamProvider);
});

final currentUserRoleProvider = Provider<UserRole>((ref) {
  final userAsync = ref.watch(currentUserStreamProvider);
  return userAsync.value?.role ?? UserRole.participant;
});

final teamMembersProvider = FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return [];
  
  // Only admins can have team members in this context
  if (currentUser.role != UserRole.admin) return [];

  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.getCreatedUsers(currentUser.id);
});
