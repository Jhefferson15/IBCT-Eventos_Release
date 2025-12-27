import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/features/events/data/firestore_event_repository.dart';
import 'package:ibct_eventos/features/events/domain/models/event_model.dart';

import 'package:ibct_eventos/core/utils/crashlytics_helper.dart';
import 'package:mocktail/mocktail.dart';

class MockCrashlyticsHelper extends Mock implements CrashlyticsHelper {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockCrashlyticsHelper mockCrashlytics;
  late FirestoreEventRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockCrashlytics = MockCrashlyticsHelper();
    
    // Stub logging
    when(() => mockCrashlytics.log(any())).thenAnswer((_) async {});
    when(() => mockCrashlytics.recordError(any(), any(), reason: any(named: 'reason'))).thenAnswer((_) async {});

    repository = FirestoreEventRepository(fakeFirestore, mockCrashlytics);
  });

  final testEvent = Event(
    id: 'events_1',
    title: 'New Event',
    date: DateTime(2023, 1, 1),
    description: 'Desc',
    location: 'Loc',
    creatorId: 'user_1',
    participantCount: 0,
  );

  group('FirestoreEventRepository', () {
    test('createItem should add to firestore', () async {
      final id = await repository.createItem(testEvent);

      final snapshot = await fakeFirestore.collection('events').doc(id).get();
      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['title'], 'New Event');
    });

    test('getItems should return list of events', () async {
      await repository.createItem(testEvent);
      await repository.createItem(Event(
        id: 'events_2',
        title: 'Event 2',
        date: DateTime(2023, 2, 2),
        creatorId: 'user_1',
      ));

      final events = await repository.getItems();
      expect(events.length, 2);
    });

    test('updateItem should modify existing event', () async {
      final id = await repository.createItem(testEvent);
      
      // Update event needs the ID that was generated
      final updated = testEvent.copyWith(id: id, title: 'Updated Title');
      await repository.updateItem(updated);

      final snapshot = await fakeFirestore.collection('events').doc(id).get();
      expect(snapshot.data()?['title'], 'Updated Title');
    });

    test('deleteItem should remove event', () async {
      final id = await repository.createItem(testEvent);
      await repository.deleteItem(id);

      final snapshot = await fakeFirestore.collection('events').doc(id).get();
      expect(snapshot.exists, isFalse);
    });
  });
}
