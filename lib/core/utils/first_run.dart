import 'package:shared_preferences/shared_preferences.dart';

/// Whether the user has already been through the language picker and the
/// onboarding. Read once in `main()` so the app can open straight on the shell
/// for returning users instead of replaying the first-run flow on every launch.
class FirstRun {
  FirstRun._();

  static const String _prefKey = 'onboarding_done';

  static bool _done = false;

  /// True once onboarding has been finished (or skipped) on this install.
  static bool get done => _done;

  /// Loads the saved flag before the UI builds. Call once in `main()`.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _done = prefs.getBool(_prefKey) ?? false;
    } catch (_) {
      // Unreadable preferences: show the first-run flow, which is harmless.
    }
  }

  /// Records that onboarding is finished, so the next launch skips it.
  static Future<void> markDone() async {
    _done = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
    } catch (_) {
      // Best-effort: worst case the user sees onboarding once more.
    }
  }
}
