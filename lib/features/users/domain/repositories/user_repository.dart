import '../models/app_user.dart';

abstract class UserRepository {
  Future<void> createUser(AppUser user);
  Future<AppUser?> getUser(String id);
  Stream<AppUser?> getUserStream(String id);
  Future<void> updateUser(AppUser user);
  Future<List<AppUser>> getCreatedUsers(String adminId);
  Future<bool> userExists(String id);
  Future<void> deleteUser(String id);
}
