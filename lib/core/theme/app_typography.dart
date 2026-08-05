import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:status_maker/core/utils/responsive.dart';

class AppTypography {
  /// The app's text scale, bound to the palette of the theme being built.
  ///
  /// Colours are **passed in** rather than read from `AppColors`: those getters
  /// resolve against [ThemeController.isDark], which is global state, not the
  /// brightness of the theme under construction. Reading them here made
  /// `AppTheme.lightTheme` and `AppTheme.darkTheme` come out text-identical —
  /// whichever palette happened to be active won for both. It only looked right
  /// because `MaterialApp.themeMode` selects the matching one; a local
  /// `Theme(data: AppTheme.lightTheme)` or a future `ThemeMode.system` would
  /// have rendered dark text on the dark background.
  static TextTheme textTheme({
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 32.sp,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 28.sp,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 24.sp,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      // The headline family used to be missing entirely, so anything reaching
      // for it silently fell back to Flutter's default (Roboto/SF, Material's
      // own sizes and colours) — breaking both the font and dark mode.
      headlineLarge: GoogleFonts.inter(
        fontSize: 26.sp,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 22.sp,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22.sp,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      // Flutter's default style for a bare `Text()`. Deliberately the muted
      // colour — most body copy in this app is secondary — so a heading must
      // ask for a title/headline slot explicitly.
      bodyMedium: GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      // Not onPrimary: every button type sets its own `foregroundColor`, which
      // Flutter's ButtonStyleButton applies *over* this style's colour, so the
      // white here never reached a button label — it only leaked into non-button
      // consumers of labelLarge, where it was invisible in light mode.
      labelLarge: GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        color: textSecondary,
      ),
    );
  }
}
