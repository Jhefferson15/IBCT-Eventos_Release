import '../../../events/domain/models/event_model.dart';

class GetGlobalStatsUseCase {
  GetGlobalStatsUseCase();

  int execute(List<Event> events) {
    return events.fold(0, (sum, event) => sum + event.participantCount);
  }
}
