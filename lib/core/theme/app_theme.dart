import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        textPrimary: AppColors.lightTextPrimary,
        textSecondary: AppColors.lightTextSecondary,
        border: AppColors.lightBorder,
      );

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        textPrimary: AppColors.darkTextPrimary,
        textSecondary: AppColors.darkTextSecondary,
        border: AppColors.darkBorder,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    final dark = brightness == Brightness.dark;
    // Navy primary is invisible on the dark background, and every stock widget
    // that isn't styled by hand (spinners, text cursors, switch tracks, plain
    // TextButtons) draws in primary. Dark mode uses the accent instead.
    final primary = dark ? AppColors.accent : AppColors.primary;
    // Status-bar icons: dark on the light theme, light on the dark one. Set on
    // the AppBar theme because an AppBar otherwise guesses from its own
    // background — and a transparent background reads as "dark", which gave
    // white icons on the light screens.
    final overlay = (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
        .copyWith(statusBarColor: Colors.transparent);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        surface: surface,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionColor: AppColors.accent.withValues(alpha: 0.30),
        selectionHandleColor: AppColors.accent,
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.accent),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.accent : null),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.accent.withValues(alpha: 0.45)
                : null),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
      ),
      scaffoldBackgroundColor: background,
      textTheme: AppTypography.textTheme(
        textPrimary: textPrimary,
        textSecondary: textSecondary,
      ),
      appBarTheme: AppBarTheme(
        systemOverlayStyle: overlay,
        backgroundColor: background,
        elevation: 0,
        // Without this, Material 3 tints the app bar toward `primary` as content
        // scrolls under it, so the deliberate flat/flush look above quietly
        // broke on every scrolling screen.
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.onPrimary,
          iconColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.r),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dark ? textPrimary : AppColors.primary,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        ),
      ),
      // The shipped bottom bar is hand-rolled in MainLayout, so this only
      // applies to a plain BottomNavigationBar. It said selected == primary
      // while the real bar uses accent, which made the theme actively
      // misleading about the app's own selection convention.
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
