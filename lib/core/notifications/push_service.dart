import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:status_maker/core/supabase/supabase_service.dart';
import 'package:status_maker/core/utils/page_transitions.dart';
import 'package:status_maker/features/preview/presentation/template_detail_screen.dart';
import 'package:status_maker/features/statuses/data/status_repository.dart';

/// Every line this file prints starts with this tag, so the whole push story can
/// be read with one filter:
///
/// ```
/// flutter run | grep PUSH          # or:  adb logcat | grep PUSH
/// ```
const String _tag = '[PUSH]';

void _log(String message) => debugPrint('$_tag $message');

/// Handles a push that arrives while the app is fully closed or backgrounded.
///
/// Required by firebase_messaging even though Android draws the tray
/// notification itself from the `notification` payload the Edge Function sends.
/// The log line is what proves delivery reached this device even when no UI ran.
///
/// Must be a top-level function — it runs in its own isolate, with none of the
/// app's state available.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('$_tag ⬇️  BACKGROUND message received');
  debugPrint('$_tag     title: ${message.notification?.title}');
  debugPrint('$_tag     body : ${message.notification?.body}');
  debugPrint('$_tag     data : ${message.data}');
}

/// Registers this device with FCM so "someone liked your status" can arrive with
/// the app closed.
///
/// Follows the same rule as [SupabaseService]: never throws to the caller. If
/// Firebase is misconfigured, the user denies permission, or the device has no
/// Play Services, the app simply runs without push instead of failing to start —
/// but it says loudly in the log which of those happened.
class PushService {
  PushService._();

  static bool _initialized = false;

  /// Attached to [MaterialApp] in main.dart. Notification taps arrive on
  /// listeners that have no [BuildContext] of their own — this is the only
  /// way to push a screen from here.
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// Also attached to [MaterialApp] — lets [_showForegroundBanner] show a
  /// SnackBar without a [BuildContext] of its own, same reason as [navigatorKey].
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  /// The token last written to the backend, so a refresh reporting the same value
  /// doesn't cause a pointless write on every launch.
  static String? _registeredToken;

  /// This device's current FCM token, once known. Handy for pasting into
  /// Firebase Console → Messaging → Send test message.
  static String? get token => _registeredToken;

  /// Call once in main(), after [SupabaseService.init] — registration needs a
  /// user id to attach the token to.
  static Future<void> init() async {
    _log('──────── push init ────────');

    // Android-only for now: iOS additionally needs an APNs key and a paid Apple
    // Developer account, neither of which is set up.
    if (!Platform.isAndroid) {
      _log('❌ skipped: ${Platform.operatingSystem} is not supported yet '
          '(Android only)');
      return;
    }

    try {
      if (!_initialized) {
        final app = await Firebase.initializeApp();
        _log('✅ Firebase connected');
        _log('   project : ${app.options.projectId}');
        _log('   appId   : ${app.options.appId}');
        FirebaseMessaging.onBackgroundMessage(
            firebaseMessagingBackgroundHandler);
        _initialized = true;
      }

      final messaging = FirebaseMessaging.instance;

      // Android 13+ shows the system permission dialog here. Older versions
      // return authorized immediately.
      final settings = await messaging.requestPermission();
      _log('🔔 permission: ${settings.authorizationStatus.name}');
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _log('❌ user denied notifications — no push will be delivered. '
            'Enable it in Android Settings → Apps → Status Maker → '
            'Notifications.');
        return;
      }

      _log('⏳ requesting FCM token…');
      final fcmToken = await messaging.getToken();
      if (fcmToken == null) {
        _log('❌ FCM returned no token. Usually means Google Play Services is '
            'missing or google-services.json does not match this package.');
        return;
      }
      // Printed in full and on its own line: this is the value you paste into
      // Firebase Console to send a test push straight to this device.
      _log('🎫 FCM TOKEN ↓↓↓');
      _log(fcmToken);
      _log('🎫 FCM TOKEN ↑↑↑ (${fcmToken.length} chars)');

      await _register(fcmToken);

      // Tokens rotate (app restore, cache clear, long idle). Without this the
      // backend keeps pushing to an address the phone no longer answers on.
      messaging.onTokenRefresh.listen((t) {
        _log('♻️  token refreshed by FCM — re-registering');
        _register(t);
      }, onError: (Object e) {
        _log('⚠️  token refresh stream failed: $e');
      });

      // Foreground messages do NOT draw a tray notification on Android — the OS
      // assumes the app will show its own UI. Without the banner below, a push
      // that arrives while the app is open would be delivered successfully and
      // still look, to the user, exactly like it never happened.
      FirebaseMessaging.onMessage.listen((m) {
        _log('⬇️  FOREGROUND message received');
        _log('    title: ${m.notification?.title}');
        _log('    body : ${m.notification?.body}');
        _log('    data : ${m.data}');
        _showForegroundBanner(m);
      });

      // The user tapped a notification and it opened the app.
      FirebaseMessaging.onMessageOpenedApp.listen((m) {
        _log('👆 notification tapped (app was backgrounded): ${m.data}');
        _openFromData(m.data);
      });

      // Same, but the app was fully closed and this launched it.
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _log('👆 app opened from a notification (was closed): ${initial.data}');
        _openFromData(initial.data);
      }

      _log('──────── push ready ────────');
    } catch (e) {
      _log('❌ init failed: $e');
    }
  }

  /// Stores [token] against the current user, so the Edge Function can find it.
  static Future<void> _register(String? token) async {
    if (token == null || token.isEmpty) {
      _log('⚠️  register skipped: empty token');
      return;
    }
    if (token == _registeredToken) {
      _log('↩️  register skipped: token already saved this session');
      return;
    }

    // A token with nobody to attach it to is useless — and the row's user_id is
    // NOT NULL, so this would fail anyway.
    if (!await SupabaseService.ensureReady()) {
      _log('❌ register failed: Supabase not ready — '
          '${SupabaseService.statusMessage}');
      return;
    }
    final userId = SupabaseService.userId;
    if (userId == null) {
      _log('❌ register failed: no signed-in user to attach the token to');
      return;
    }

    try {
      _log('⏳ saving token to device_tokens for user $userId …');
      // Upsert on the token (its primary key): re-registering the same phone
      // updates the row rather than erroring, and a phone that changes hands
      // moves to its new owner instead of keeping the old one's notifications.
      await SupabaseService.client.from('device_tokens').upsert({
        'token': token,
        'user_id': userId,
        'platform': 'android',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'token');
      _registeredToken = token;
      _log('✅ device registered — this phone can now receive push');
    } catch (e) {
      // Not fatal: the in-app bell still works, this device just won't get push
      // until a later launch retries.
      _log('❌ could not save device token: $e');
      _log('   (if this says the table is missing, run '
          'supabase/notifications.sql)');
    }
  }

  /// Opens the status a "someone liked/remixed your status" push points at,
  /// using the `status_id` the Edge Function put in the data payload (see
  /// supabase/functions/notify-on-like/index.ts).
  ///
  /// Best-effort: the notification is still useful without this — if the
  /// navigator isn't attached yet, or the status was deleted since, this just
  /// logs and does nothing rather than crashing app launch.
  static const _openableTypes = {'like', 'remix'};

  static Future<void> _openFromData(Map<String, dynamic> data) async {
    if (!_openableTypes.contains(data['type'])) return;
    final statusId = data['status_id'] as String?;
    if (statusId == null || statusId.isEmpty) return;

    final status = await StatusRepository().fetchById(statusId);
    if (status == null) {
      _log('↩️  tap ignored: status $statusId no longer exists');
      return;
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _log('⚠️  tap ignored: navigator not attached yet');
      return;
    }
    navigator.push(FadeSlidePageRoute(
      page: TemplateDetailScreen(status: status),
    ));
  }

  /// Stands in for the tray notification Android withholds while the app is
  /// in the foreground (see the comment at the [onMessage] listener). Tapping
  /// "View" reuses [_openFromData] — same destination as a real tap would go.
  static void _showForegroundBanner(RemoteMessage m) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) {
      _log('⚠️  banner skipped: ScaffoldMessenger not attached yet');
      return;
    }
    final title = m.notification?.title;
    final body = m.notification?.body;
    if (title == null && body == null) return;

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (body != null) Text(body),
          ],
        ),
        action: _openableTypes.contains(m.data['type'])
            ? SnackBarAction(label: 'View', onPressed: () => _openFromData(m.data))
            : null,
      ),
    );
  }
}
