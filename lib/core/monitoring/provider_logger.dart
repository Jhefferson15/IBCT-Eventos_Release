import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/crashlytics_helper.dart';

final class ProviderLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (newValue is AsyncError) {
      CrashlyticsHelper().recordError(
        newValue.error, 
        newValue.stackTrace, 
        reason: 'Provider Error: ${context.provider.name ?? context.provider.runtimeType}'
      );
    }
  }

  @override
  void didAddProvider(
    ProviderObserverContext context,
    Object? value,
  ) {
     // Optional: Log provider creation if needed for debugging
     // CrashlyticsService().log('Provider added: ${context.provider.name ?? context.provider.runtimeType}');
  }
}
