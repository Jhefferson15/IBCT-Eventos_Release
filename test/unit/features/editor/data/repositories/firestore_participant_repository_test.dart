import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/features/editor/data/repositories/firestore_participant_repository.dart';
import 'package:ibct_eventos/features/editor/domain/models/participant_model.dart';
// import 'package:ibct_eventos/features/events/data/firestore_event_repository.dart'; // Removed as unused
// But createItem updates event counter, so we might need an event doc to exist or we just verify collection.

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreParticipantRepository repository;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    repository = FirestoreParticipantRepository(fakeFirestore);
    // Create event doc for counter updates
    await fakeFirestore.collection('events').doc('event1').set({
      'title': 'Test Event',
      'participant_count': 0,
    });
    await fakeFirestore.collection('events').doc('event2').set({
      'title': 'Test Event 2',
      'participant_count': 0,
    });
  });

  final testParticipant = Participant(
    id: 'p1',
    eventId: 'event1',
    name: 'John Doe',
    email: 'john@example.com',
    phone: '1234567890',
    ticketType: 'VIP',
    status: 'confirmed',
    token: 'TOKEN123',
  );

  group('FirestoreParticipantRepository', () {
    test('createItem should add new participant and return ID', () async {
      final id = await repository.createItem(testParticipant);

      // The repository logic:
      // if Item has ID, uses it.
      // else uses transaction and counters.
      
      final snapshot = await fakeFirestore
          .collection('participants') // It uses 'participants' collection, NOT subcollection.
          .doc(id)
          .get();

      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['name'], 'John Doe');
    });

    test('updateItem should update existing participant', () async {
      await repository.createItem(testParticipant);

      final updated = testParticipant.copyWith(name: 'Jane Doe');
      await repository.updateItem(updated);

      final snapshot = await fakeFirestore
          .collection('participants')
          .doc('p1')
          .get();

      expect(snapshot.data()?['name'], 'Jane Doe');
    });

    test('getParticipantsByEvent should return all participants for event', () async {
      await repository.createItem(testParticipant);
      await repository.createItem(Participant(
        id: 'p2',
        eventId: 'event1',
        name: 'Alice',
        email: 'alice@example.com',
        phone: '111',
        ticketType: 'Normal',
        status: 'pending',
        token: 'TOKEN456',
      ));
      // Other event
      await repository.createItem(Participant(
        id: 'p3',
        eventId: 'event2',
        name: 'Bob',
        email: 'bob@example.com',
        phone: '222',
        ticketType: 'Normal',
        status: 'confirmed',
        token: 'TOKEN789',
      ));

      final participants = await repository.getParticipantsByEvent('event1');
      expect(participants.length, 2);
    });

    test('deleteItem should remove from firestore', () async {
      await repository.createItem(testParticipant);
      await repository.deleteItem('p1');

      final snapshot = await fakeFirestore
          .collection('participants')
          .doc('p1')
          .get();

      expect(snapshot.exists, isFalse);
    });

    test('createItemsBatch should add multiple participants', () async {
      final p2 = testParticipant.copyWith(id: 'p2', name: 'P2');
      final p3 = testParticipant.copyWith(id: 'p3', name: 'P3');

      await repository.createItemsBatch([p2, p3]);

      final snapshot = await fakeFirestore.collection('participants').get();
      // Expect 2 items (p2, p3). 
      // Note: repository.createItem uses transaction/ID logic.
      // createItemsBatch uses auto-generated IDs if ID is empty?
      // Repository implementation: final docRef = _collection.doc(); batch.set(docRef, dto.toMap());
      // It IGNORES the ID passed in the DTO if it uses doc().
      // Wait, let's check repository source again.
      // "final docRef = _collection.doc();" -> Generates NEW ID.
      // "batch.set(docRef, dto.toMap());" -> Sets data.
      // So the IDs 'p2', 'p3' passed in might be ignored as document keys, but stored in the map?
      // DTO toMap usually includes ID?
      // If DTO includes ID, it will be saved as a field.
      expect(snapshot.docs.length, 2);
    });

    test('deleteItemsBatch should remove multiple participants', () async {
      // Create manually to check IDs
      await fakeFirestore.collection('participants').doc('p1').set(
        {'name': 'P1', 'eventId': 'event1'}
      );
      await fakeFirestore.collection('participants').doc('p2').set(
        {'name': 'P2', 'eventId': 'event1'}
      );

      await repository.deleteItemsBatch(['p1', 'p2']);

      final s1 = await fakeFirestore.collection('participants').doc('p1').get();
      final s2 = await fakeFirestore.collection('participants').doc('p2').get();

      expect(s1.exists, isFalse);
      expect(s2.exists, isFalse);
    });

    test('checkInParticipant should update status', () async {
      await fakeFirestore.collection('participants').doc('p1').set(
        {'name': 'P1', 'isCheckedIn': false}
      );

      await repository.checkInParticipant('p1');

      final s1 = await fakeFirestore.collection('participants').doc('p1').get();
      expect(s1.data()?['isCheckedIn'], true);
      expect(s1.data()?['status'], 'Presente');
    });

    test('getParticipantByToken should return correct participant', () async {
      await fakeFirestore.collection('participants').doc('p1').set(
        {'name': 'P1', 'token': 'T123'}
      );

      final result = await repository.getParticipantByToken('T123');

      expect(result, isNotNull);
      expect(result!.id, 'p1');
    });
  });
}
