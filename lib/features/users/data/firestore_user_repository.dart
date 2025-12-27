import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/app_user.dart';
import '../domain/repositories/user_repository.dart';
import 'models/app_user_dto.dart'; // Import DTO

class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;

  FirestoreUserRepository(this._firestore);

  CollectionReference get _usersCollection => _firestore.collection('users');

  @override
  Future<void> createUser(AppUser user) async {
    final dto = AppUserDto.fromDomain(user);
    await _usersCollection.doc(user.id).set(dto.toMap());
  }

  @override
  Future<AppUser?> getUser(String id) async {
    final doc = await _usersCollection.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return AppUserDto.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Stream<AppUser?> getUserStream(String id) {
    return _usersCollection.doc(id).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return AppUserDto.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  @override
  Future<void> updateUser(AppUser user) async {
    final dto = AppUserDto.fromDomain(user);
    await _usersCollection.doc(user.id).update(dto.toMap());
  }

  @override
  Future<List<AppUser>> getCreatedUsers(String adminId) async {
    final querySnapshot = await _usersCollection
        .where('created_by', isEqualTo: adminId)
        .get();

    return querySnapshot.docs
        .map((doc) => AppUserDto.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<bool> userExists(String id) async {
    final doc = await _usersCollection.doc(id).get();
    return doc.exists;
  }

  @override
  Future<void> deleteUser(String id) async {
    await _usersCollection.doc(id).delete();
  }
}
