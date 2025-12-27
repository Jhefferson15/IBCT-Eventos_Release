import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/features/editor/domain/models/participant_model.dart';

import 'package:ibct_eventos/features/editor/domain/repositories/participant_repository_interface.dart';
import 'package:ibct_eventos/features/editor/domain/usecases/create_participant_usecase.dart';
import 'package:ibct_eventos/features/users/domain/usecases/log_activity_use_case.dart';
import 'package:ibct_eventos/features/users/domain/models/activity_log.dart';
import 'package:mocktail/mocktail.dart';


class MockParticipantRepository extends Mock implements IParticipantRepository {}
class MockLogActivityUseCase extends Mock implements LogActivityUseCase {}
class FakeParticipant extends Fake implements Participant {}

void main() {
  late MockParticipantRepository mockRepository;
  late MockLogActivityUseCase mockLogUseCase;
  late CreateParticipantUseCase useCase;

  setUpAll(() {
    registerFallbackValue(FakeParticipant());
    registerFallbackValue(ActivityActionType.addParticipant);
  });

  setUp(() {
    mockRepository = MockParticipantRepository();
    mockLogUseCase = MockLogActivityUseCase();
    useCase = CreateParticipantUseCase(mockRepository, mockLogUseCase);
    
    // Default stub for log
    when(() => mockLogUseCase.call(
      userId: any(named: 'userId'),
      actionType: any(named: 'actionType'),
      targetId: any(named: 'targetId'),
      targetType: any(named: 'targetType'),
      details: any(named: 'details'),
    )).thenAnswer((_) async {});
  });


  group('CreateParticipantUseCase', () {
    test('should call repository and log service on success', () async {
      final participant = Participant(
        id: 'new_id',
        eventId: 'event1',
        name: 'New User',
        email: 'new@test.com',
        phone: '000',
        ticketType: 'full',
        status: 'confirmed',
        token: 'abc',
      );

      when(() => mockRepository.createItem(any())).thenAnswer((_) async => 'new_id');

      await useCase.call(participant, 'admin1');


      final captured = verify(() => mockRepository.createItem(captureAny())).captured;
      expect(captured.length, 1);
      final capturedParticipant = captured.first as Participant;
      expect(capturedParticipant.id, participant.id);
      expect(capturedParticipant.name, participant.name);
      expect(capturedParticipant.email, participant.email);
    });

    test('should rethrow exception if repository fails', () async {
      final participant = Participant(
        id: 'new_id',
        eventId: 'event1',
        name: 'New User',
        email: 'new@test.com',
        phone: '000',
        ticketType: 'full',
        status: 'confirmed',
        token: 'abc',
      );
      
      when(() => mockRepository.createItem(any())).thenThrow(Exception('DB Error'));

      expect(() => useCase.call(participant, 'admin1'), throwsException);

    });
  });
}
