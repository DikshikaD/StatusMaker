import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/notifications/push_banner.dart';
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

  /// Also attached to [MaterialApp], so a SnackBar can be shown without a
  /// [BuildContext] of its own — same reason as [navigatorKey].
  ///
  /// No longer used by [_showForegroundBanner], which now renders through the
  /// navigator's overlay (see [PushBanner]). Kept as the app-wide messenger
  /// hook; nothing currently reads it.
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  /// The token last written to the backend, so a refresh reporting the same value
  /// doesn't cause a pointless write on every launch.
  static String? _registeredToken;

  /// The language stored alongside [_registeredToken]. Tracked so switching
  /// language in Settings re-registers (the row would otherwise keep wording
  /// tray notifications in the old language), while an unchanged language
  /// still skips the redundant write.
  static String? _registeredLang;

  /// Guards against attaching the language listener twice if [init] re-runs.
  static bool _langListenerAttached = false;

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
      // Firebase Console to send a test push straight to this device. Debug
      // builds only — in release it would sit in logcat for any app with log
      // access to read.
      if (kDebugMode) {
        _log('🎫 FCM TOKEN ↓↓↓');
        _log(fcmToken);
        _log('🎫 FCM TOKEN ↑↑↑ (${fcmToken.length} chars)');
      } else {
        _log('🎫 FCM token received (${fcmToken.length} chars)');
      }

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

      // Switching language in Settings must reach the backend too, or tray
      // notifications keep arriving in the language chosen at install time.
      if (!_langListenerAttached) {
        _langListenerAttached = true;
        S.lang.addListener(() {
          if (_registeredToken == null) return;
          _log('🌐 language changed to ${S.lang.value} — re-registering device');
          _register(_registeredToken);
        });
      }

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

  /// Re-attaches this phone's token to whoever is signed in now — used after
  /// "Delete my data" swaps the account for a fresh anonymous one.
  static Future<void> reRegisterForCurrentUser() async {
    final token = _registeredToken;
    if (token == null) return;
    _registeredLang = null; // defeats the "already saved" short-circuit
    await _register(token);
  }

  /// Stores [token] against the current user, so the Edge Function can find it.
  static Future<void> _register(String? token) async {
    if (token == null || token.isEmpty) {
      _log('⚠️  register skipped: empty token');
      return;
    }
    if (token == _registeredToken && S.lang.value == _registeredLang) {
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
      _log('⏳ saving token to device_tokens'
          '${kDebugMode ? ' for user $userId' : ''} …');
      // Upsert on the token (its primary key): re-registering the same phone
      // updates the row rather than erroring, and a phone that changes hands
      // moves to its new owner instead of keeping the old one's notifications.
      // `lang` is what the Edge Function words closed-app pushes in.
      final lang = S.lang.value;
      final platform = Platform.operatingSystem;
      try {
        // Preferred path: register_device (supabase/migrations/0002) runs as
        // the table owner, so it can move a token another account registered
        // — which the RLS-checked upsert below can't.
        await SupabaseService.client.rpc('register_device', params: {
          'p_token': token,
          'p_platform': platform,
          'p_lang': lang,
        });
      } on PostgrestException catch (e) {
        _log('ℹ️  register_device unavailable (${e.code}) — plain upsert');
        await SupabaseService.client.from('device_tokens').upsert({
          'token': token,
          'user_id': userId,
          'platform': platform,
          'lang': lang,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'token');
      }
      _registeredToken = token;
      _registeredLang = lang;
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

  /// Whether MainLayout is mounted. A tap that cold-starts the app arrives
  /// while the splash / language picker / onboarding is still up; opening the
  /// status on top of those would leave back landing on the picker, and the
  /// editor's "go to My Creations" would have no shell to answer it. Such a tap
  /// is parked in [_pendingOpen] until the shell reports in.
  static bool _shellMounted = false;
  static Map<String, dynamic>? _pendingOpen;

  /// Called by MainLayout as it mounts / unmounts.
  static void shellMounted(bool mounted) {
    _shellMounted = mounted;
    if (mounted && _pendingOpen != null) {
      final data = _pendingOpen!;
      _pendingOpen = null;
      _openFromData(data);
    }
  }

  static Future<void> _openFromData(Map<String, dynamic> data) async {
    if (!_openableTypes.contains(data['type'])) return;
    if (!_shellMounted) {
      _log('⏸️  tap parked until the app shell is up');
      _pendingOpen = data;
      return;
    }
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
  /// in the foreground (see the comment at the [onMessage] listener).
  ///
  /// Rendered as a themed heads-up tile dropping in from the top rather than a
  /// bottom SnackBar: an incoming push reads as a notification, and the bottom
  /// of the screen is already taken by the nav bar and the editor toolbars.
  /// Tapping it reuses [_openFromData] — the same destination a real tray tap
  /// would reach.
  static void _showForegroundBanner(RemoteMessage m) {
    // The root overlay, so the tile floats above the nav bar and any open
    // bottom sheet or dialog.
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) {
      _log('⚠️  banner skipped: navigator overlay not attached yet');
      return;
    }

    // toString() rather than a cast: FCM data values are strings in practice,
    // but a cast would throw the whole banner away if one ever isn't.
    final type = m.data['type']?.toString();
    final openable = _openableTypes.contains(type);
    final copy = _localizedCopy(m, type);

    PushBanner.show(
      overlay,
      title: copy.$1,
      body: copy.$2,
      type: type,
      onOpen: openable ? () => _openFromData(m.data) : null,
    );
  }

  /// The banner's wording in the user's chosen app language.
  ///
  /// The `notification` payload is worded server-side, and the Edge Function
  /// can only pick a language from what was stored at device-registration time
  /// — which is stale the moment the user switches language in Settings. While
  /// the app is open we know the current choice, so re-word from [S] using the
  /// `type` in the data payload and ignore the server's strings entirely.
  ///
  /// Unknown types fall back to whatever the server sent: an untranslated
  /// notification still beats a blank one.
  static (String?, String?) _localizedCopy(RemoteMessage m, String? type) {
    if (type != 'like' && type != 'remix') {
      return (m.notification?.title, m.notification?.body);
    }

    final statusTitle = m.data['status_title']?.toString();
    final hasTitle = statusTitle != null && statusTitle.isNotEmpty;

    final title = S.t('push_${type}_title');
    final body = hasTitle
        ? S.t('push_${type}_body_named').replaceAll('{title}', statusTitle)
        : S.t('push_${type}_body');

    return (title, body);
  }
}
