import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/event_stats.dart';
import '../../domain/repositories/analytics_repository_interface.dart';
import '../datasources/analytics_remote_datasource.dart';

class AnalyticsRepositoryImpl implements IAnalyticsRepository {
  final IAnalyticsRemoteDataSource _dataSource;

  AnalyticsRepositoryImpl(this._dataSource);

  @override
  Future<EventStats> getEventStats(String eventId) async {
    return _dataSource.getEventStats(eventId);
  }
}

final analyticsRepositoryProvider = Provider<IAnalyticsRepository>((ref) {
  final dataSource = ref.watch(analyticsRemoteDataSourceProvider);
  return AnalyticsRepositoryImpl(dataSource);
});
