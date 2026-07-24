import 'package:flutter/material.dart';
import 'theme_controller.dart';

/// App palette. Brand colors are fixed; the semantic colors (background,
/// surface, text, border…) are theme-aware getters that switch between the
/// light and dark palettes based on [ThemeController.isDark]. Because the whole
/// app rebuilds when the theme changes (see main.dart), every screen that reads
/// `AppColors.background` etc. updates automatically.
class AppColors {
  // ---- Brand colors (identical in both themes) ----
  static const Color primary = Color(0xFF172331); // Dark navy blue from buttons
  static const Color primaryLight = Color(0xFF415A7E); // Lighter slate-blue
  static const Color accent = Color(0xFFE38870); // Warm peach/orange from tags
  static const Color accentLight = Color(0xFFF3B49E); // Lighter peach

  /// Brand gradient built from the primary color family.
  static const List<Color> primaryGradient = [primary, primaryLight];

  /// Accent gradient (warm peach) used across the splash, onboarding and
  /// dialogs. The lighter end adds depth so fills never look flat.
  static const List<Color> accentGradient = [accent, accentLight];

  // ---- Light palette (raw values) ----
  static const Color lightBackground = Color(0xFFF9FAFB); // off-white
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF111A24); // almost-black navy
  static const Color lightTextSecondary = Color(0xFF6B7280); // gray
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightCard = Color(0xFFF3F4F6);

  // ---- Dark palette (raw values) ----
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkCard = Color(0xFF1E293B);

  static bool get _dark => ThemeController.isDark;

  // ---- Semantic (theme-aware) colors ----
  static Color get background => _dark ? darkBackground : lightBackground;
  static Color get surface => _dark ? darkSurface : lightSurface;
  static Color get textPrimary => _dark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary =>
      _dark ? darkTextSecondary : lightTextSecondary;
  static Color get border => _dark ? darkBorder : lightBorder;
  static Color get cardLight => _dark ? darkCard : lightCard;

  /// Always-light color for text/icons that sit on the primary (navy) buttons,
  /// which stay dark in both themes.
  static const Color onPrimary = Colors.white;
}
