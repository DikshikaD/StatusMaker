import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide theme controller. [mode] drives the whole app; changing it rebuilds
/// the UI (see main.dart) so every `AppColors.*` lookup returns the new palette.
/// Mirrors the localization controller (`S`) so the two feel consistent.
class ThemeController {
  /// Current theme mode. Defaults to light on first launch.
  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static const String _prefKey = 'app_theme_mode';

  /// True when the dark palette is active. Used by [AppColors] getters.
  static bool get isDark => mode.value == ThemeMode.dark;

  /// Loads the saved theme before the UI builds. Call once in `main()`.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved == 'dark') {
        mode.value = ThemeMode.dark;
      } else if (saved == 'light') {
        mode.value = ThemeMode.light;
      }
    } catch (_) {
      // If preferences can't be read, fall back to the default (light).
    }
  }

  /// Sets the theme and persists the choice for next launch.
  static void set(ThemeMode m) {
    mode.value = m;
    _persist(m);
  }

  /// Flips between light and dark, persisting the result.
  static void toggle() => set(isDark ? ThemeMode.light : ThemeMode.dark);

  static Future<void> _persist(ThemeMode m) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, m == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {
      // Persisting is best-effort; ignore storage errors.
    }
  }
}
