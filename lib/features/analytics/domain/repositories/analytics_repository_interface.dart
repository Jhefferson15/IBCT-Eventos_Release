import '../models/event_stats.dart';

abstract class IAnalyticsRepository {
  Future<EventStats> getEventStats(String eventId);
}
