import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.backgroundLight,
      primaryColor: AppColors.primaryGradientStart,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineMedium: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        bodyLarge: const TextStyle(
          color: AppColors.textPrimary,
        ),
        bodyMedium: const TextStyle(
          color: AppColors.textSecondary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.iconActive),
        systemOverlayStyle: SystemUiOverlayStyle.dark, // Makes status bar icons dark
      ),
      useMaterial3: true,
    );
  }
}
