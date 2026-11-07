import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Sends crashes and uncaught errors to Firebase Crashlytics
/// (Firebase console → Crashlytics).
///
/// Release builds only: in debug, errors stay in the console and nothing is
/// uploaded, so development crashes don't pollute the dashboard. No user id or
/// other personal data is attached — only the stack trace, device model, OS
/// version and app version Crashlytics collects by default.
class CrashReporting {
  CrashReporting._();

  static bool _enabled = false;

  /// Call before runApp. Never throws: if Firebase can't start (missing
  /// google-services.json, unsupported platform), the app runs without
  /// crash reporting rather than not at all.
  static Future<void> init() async {
    if (!Platform.isAndroid) return;
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 5));
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode);
      _enabled = kReleaseMode;

      // Errors thrown while building, laying out or painting widgets.
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        crashlytics.recordFlutterFatalError(details);
      };
      // Uncaught async errors (futures, timers, platform channels).
      PlatformDispatcher.instance.onError = (error, stack) {
        crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e) {
      debugPrint('Crash reporting unavailable: $e');
    }
  }

  /// Reports a caught, non-fatal error worth knowing about in production.
  static void recordError(Object error, StackTrace? stack, {String? reason}) {
    if (!_enabled) return;
    unawaited(FirebaseCrashlytics.instance.recordError(error, stack, reason: reason));
  }
}
