import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF172331); // Dark navy blue from buttons
  static const Color primaryLight = Color(0xFF415A7E); // Lighter slate-blue
  static const Color accent = Color(0xFFE38870); // Warm peach/orange from tags
  static const Color accentLight = Color(0xFFF3B49E); // Lighter peach

  /// Brand gradient built from the primary color family.
  static const List<Color> primaryGradient = [primary, primaryLight];

  /// Accent gradient (warm peach) used across the splash, onboarding and
  /// dialogs. The lighter end adds depth so fills never look flat.
  static const List<Color> accentGradient = [accent, accentLight];

  // Light mode colors
  static const Color background = Color(0xFFF9FAFB); // Very light grey/off-white app background
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF111A24); // Almost black navy for headings
  static const Color textSecondary = Color(0xFF6B7280); // Gray for secondary text
  static const Color border = Color(0xFFE5E7EB);
  static const Color cardLight = Color(0xFFF3F4F6);

  // Dark mode colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
}
