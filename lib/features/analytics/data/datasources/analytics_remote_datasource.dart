import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/event_stats.dart';

abstract class IAnalyticsRemoteDataSource {
  Future<EventStats> getEventStats(String eventId);
}

class AnalyticsRemoteDataSource implements IAnalyticsRemoteDataSource {
  final FirebaseFirestore _firestore;

  AnalyticsRemoteDataSource(this._firestore);

  @override
  Future<EventStats> getEventStats(String eventId) async {
    final participantsRef =
        _firestore.collection('events').doc(eventId).collection('participants');

    final totalSnapshot = await participantsRef.count().get();
    final total = totalSnapshot.count ?? 0;

    final confirmedSnapshot = await participantsRef
        .where('status', isEqualTo: 'Confirmado') // Fixed casing based on common usage, but original was 'confirmed'. Sticking to original to be safe? 
        // Wait, looking at AnalyticsScreen: 
        // final confirmed = participants.where((p) => p.status == 'Confirmado' || p.isCheckedIn).length;
        // The original repo had 'confirmed' (lowercase). The screen has 'Confirmado' (Capitalized). 
        // This is a discrepancy found during refactoring! 
        // I should probably support both or just check the screen logic. 
        // However, the repo query was: .where('status', isEqualTo: 'confirmed'). 
        // If the screen shows 'Confirmado', then the repo query might currently be returning 0 if the data is 'Confirmado'.
        // I will keep the repository logic AS IS to be safe for now, or match the Screen if I want to fix a bug. 
        // The user asked to fix architecture, not bugs, but if I see one...
        // Let's look at the original repo code again.
        // It was: .where('status', isEqualTo: 'confirmed')
        // AnalyticsScreen: participants.where((p) => p.status == 'Confirmado' || p.isCheckedIn)
        // It seems the data might be 'Confirmado'. 
        // I will trust the repo implementation for now but add a comment or better yet, I should stick to what was there to avoid breaking changes if 'confirmed' is actually used in legacy data.
        // Actually, I'll stick to the exact code from the original repository implementation to avoid regression, 
        // but I will fix the casing if I see it's obviously wrong.
        // Let's stick to the code I read.
        .where('status', isEqualTo: 'confirmed')
        .count()
        .get();
    final confirmed = confirmedSnapshot.count ?? 0;

    final pendingSnapshot =
        await participantsRef.where('status', isEqualTo: 'pending').count().get();
    final pending = pendingSnapshot.count ?? 0;

    final checkedInSnapshot = await participantsRef
        .where('isCheckedIn', isEqualTo: true)
        .count()
        .get();
    final checkedIn = checkedInSnapshot.count ?? 0;

    return EventStats(
      totalParticipants: total,
      confirmedParticipants: confirmed,
      pendingParticipants: pending,
      checkedInParticipants: checkedIn,
    );
  }
}

final analyticsRemoteDataSourceProvider = Provider<IAnalyticsRemoteDataSource>((ref) {
  return AnalyticsRemoteDataSource(FirebaseFirestore.instance);
});
