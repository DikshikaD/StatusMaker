import 'package:flutter/material.dart';

class AppColors {
  // Primary Gradient Colors
  static const Color primaryGradientStart = Color(0xFFFF6B6B);
  static const Color primaryGradientEnd = Color(0xFFFFA500);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceWhite = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Colors.white;

  // Icon Colors
  static const Color iconActive = Color(0xFFFF6B6B);
  static const Color iconInactive = Color(0xFF9CA3AF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGradientStart, primaryGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
