import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Thin wrapper around Supabase init + session, so the rest of the app never
/// touches the SDK directly. Repositories use [client]; UI checks [isReady].
class SupabaseService {
  SupabaseService._();

  /// True once real credentials have been added to [SupabaseConfig]. While this
  /// is false the app runs normally with all backend features simply skipped —
  /// so you can keep developing before the project is created.
  static bool get isConfigured =>
      SupabaseConfig.url.startsWith('http') &&
      !SupabaseConfig.anonKey.startsWith('YOUR_') &&
      SupabaseConfig.anonKey.isNotEmpty;

  static bool _initialized = false; // Supabase.initialize() has succeeded
  static bool _ready = false; // initialized AND signed in

  /// True when Supabase is initialised AND we have a signed-in session.
  static bool get isReady => _ready;

  /// The last error from init/sign-in, kept so the UI can explain *why* the
  /// backend is unavailable instead of blaming the network.
  static Object? lastError;

  static SupabaseClient get client => Supabase.instance.client;

  /// Current user id (anonymous or real), or null if not signed in yet.
  static String? get userId => Supabase.instance.client.auth.currentUser?.id;

  /// Call once in main(). Safe to call when unconfigured — it just no-ops.
  /// Never throws to the caller, so a backend hiccup can't block app startup.
  static Future<void> init() async {
    await ensureReady();
  }

  /// Idempotent: makes sure Supabase is initialised and there's a session.
  /// Returns true when ready. Safe to call again (e.g. from a Save/Post retry)
  /// if a previous attempt failed for a transient reason. Never throws.
  static Future<bool> ensureReady() async {
    if (!isConfigured) {
      debugPrint('SupabaseService: not configured — backend disabled.');
      return false;
    }
    try {
      if (!_initialized) {
        await Supabase.initialize(
          url: SupabaseConfig.url,
          anonKey: SupabaseConfig.anonKey,
        );
        _initialized = true;
      }
      await _ensureSignedIn();
      _ready = Supabase.instance.client.auth.currentUser != null;
      if (_ready) lastError = null;
      return _ready;
    } catch (e) {
      lastError = e;
      debugPrint('SupabaseService: not ready ($e).');
      return false;
    }
  }

  /// Gives every user an identity without a login screen. The anonymous account
  /// persists across launches (session is cached), and can be upgraded to a
  /// real email/social account later without losing their data.
  static Future<void> _ensureSignedIn() async {
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession == null) {
      await auth.signInAnonymously();
    }
  }

  /// A human-readable reason the backend isn't ready, mapped from [lastError].
  /// Used by repositories so users see the actual problem, not "no internet".
  static String get statusMessage {
    if (!isConfigured) return 'Cloud backend is not configured yet.';
    final e = lastError;
    if (e == null) return 'Connecting…';
    final s = e.toString().toLowerCase();
    if (e is AuthException) {
      if (s.contains('anonymous') && s.contains('disabled')) {
        return 'Anonymous sign-in is turned off in Supabase. Enable it under '
            'Authentication → Providers → Anonymous, then reopen the app.';
      }
      if (s.contains('invalid') && s.contains('api key')) {
        return 'The Supabase API key looks invalid. Check the anon/publishable '
            'key in SupabaseConfig.';
      }
      return 'Sign-in failed: ${e.message}';
    }
    if (s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('network') ||
        s.contains('timed out') ||
        s.contains('connection')) {
      return 'Can\'t reach the server. Check your internet and try again.';
    }
    return 'Backend unavailable: $e';
  }
}
