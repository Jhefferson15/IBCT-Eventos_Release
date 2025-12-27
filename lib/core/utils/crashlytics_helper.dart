import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsHelper {
  // Singleton pattern
  static final CrashlyticsHelper _instance = CrashlyticsHelper._internal();
  factory CrashlyticsHelper() => _instance;
  CrashlyticsHelper._internal();

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  Future<void> initialize() async {
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = (errorDetails) {
      _crashlytics.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
    
    // Force crashlytics collection enabled/disabled based on kReleaseMode
    // Only enabled in strictly release mode (disabled in debug and profile)
    await _crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode);
  }

  /// Record a non-fatal error.
  Future<void> recordError(dynamic exception, StackTrace? stack, {dynamic reason, bool fatal = false}) async {
    if (!kReleaseMode) {
      // In debug/profile mode, just print to console
      debugPrint('Error recorded: $exception');
      if (stack != null) debugPrintStack(stackTrace: stack);
      return;
    }
    await _crashlytics.recordError(exception, stack, reason: reason, fatal: fatal);
  }

  /// Log a message that will be included in the next crash report.
  Future<void> log(String message) async {
    if (!kReleaseMode) {
      debugPrint('[Crashlytics Log]: $message');
      return;
    }
    await _crashlytics.log(message);
  }

  /// Set a user identifier (e.g. user ID or email) for the current session.
  Future<void> setUserIdentifier(String identifier) async {
    if (!kReleaseMode) {
      debugPrint('[Crashlytics User]: $identifier');
      return;
    }
    await _crashlytics.setUserIdentifier(identifier);
  }

  /// Set a custom key-value pair for the current session.
  Future<void> setCustomKey(String key, dynamic value) async {
    if (!kReleaseMode) return;
    
    if (value is String) {
      await _crashlytics.setCustomKey(key, value);
    } else if (value is int) {
      await _crashlytics.setCustomKey(key, value);
    } else if (value is double) {
      await _crashlytics.setCustomKey(key, value);
    } else if (value is bool) {
      await _crashlytics.setCustomKey(key, value);
    } else {
      await _crashlytics.setCustomKey(key, value.toString());
    }
  }
}
