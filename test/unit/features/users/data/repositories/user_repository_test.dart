import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/features/users/data/firestore_user_repository.dart';
import 'package:ibct_eventos/features/users/domain/models/app_user.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreUserRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = FirestoreUserRepository(fakeFirestore);
  });

  final testUser = AppUser(
    id: 'user_1',
    email: 'test@example.com',
    name: 'Test User',
    role: UserRole.admin,
    createdAt: DateTime(2023, 1, 1),
    createdBy: 'super_admin',
  );

  group('FirestoreUserRepository', () {
    test('createUser should add user to firestore', () async {
      await repository.createUser(testUser);

      final snapshot = await fakeFirestore.collection('users').doc('user_1').get();
      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['email'], 'test@example.com');
      expect(snapshot.data()?['role'], 'admin');
    });

    test('getUser should return User when it exists', () async {
      await repository.createUser(testUser);

      final result = await repository.getUser('user_1');

      expect(result, isNotNull);
      expect(result!.id, 'user_1');
      expect(result.name, 'Test User');
    });

    test('getUser should return null when user does not exist', () async {
      final result = await repository.getUser('non_existent');
      expect(result, isNull);
    });

    test('updateUser should update fields in firestore', () async {
      await repository.createUser(testUser);

      final updatedUser = testUser.copyWith(name: 'Updated Name');
      await repository.updateUser(updatedUser);

      final snapshot = await fakeFirestore.collection('users').doc('user_1').get();
      expect(snapshot.data()?['name'], 'Updated Name');
    });

    test('deleteUser should remove user from firestore', () async {
      await repository.createUser(testUser);
      await repository.deleteUser('user_1');

      final snapshot = await fakeFirestore.collection('users').doc('user_1').get();
      expect(snapshot.exists, isFalse);
    });

    test('userExists should return true if user exists', () async {
      await repository.createUser(testUser);
      final exists = await repository.userExists('user_1');
      expect(exists, isTrue);
    });

    test('userExists should return false if user does not exist', () async {
      final exists = await repository.userExists('non_existent');
      expect(exists, isFalse);
    });

    test('getCreatedUsers should return users created by specific admin', () async {
      await repository.createUser(testUser);
      await repository.createUser(AppUser(
        id: 'user_2',
        email: 'other@example.com',
        name: 'Other User',
        role: UserRole.participant,
        createdAt: DateTime.now(),
        createdBy: 'super_admin',
      ));
      await repository.createUser(AppUser(
        id: 'user_3',
        email: 'another@example.com',
        name: 'Another User',
        role: UserRole.participant,
        createdAt: DateTime.now(),
        createdBy: 'other_admin',
      ));

      final users = await repository.getCreatedUsers('super_admin');

      expect(users.length, 2);
      expect(users.any((u) => u.id == 'user_1'), isTrue);
      expect(users.any((u) => u.id == 'user_2'), isTrue);
      expect(users.any((u) => u.id == 'user_3'), isFalse);
    });
  });
}
