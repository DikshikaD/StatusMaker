import 'package:flutter/widgets.dart';

/// Central responsive-sizing utility.
///
/// The whole app is designed against a baseline phone (iPhone X @ 375 x 812
/// logical px). At runtime we compute a scale factor from the real device size
/// and multiply every design value by it, so the UI keeps its proportions on
/// small and large phones instead of relying on hard-coded pixels.
///
/// Usage:
/// ```dart
/// SizedBox(height: 24.h);        // height-scaled spacing
/// Padding(padding: EdgeInsets.all(16.w));
/// Text('Hi', style: TextStyle(fontSize: 18.sp));
/// BorderRadius.circular(20.r);   // generic / radius scaling
/// ```
///
/// Call [ScreenUtil.init] once, high in the tree (done in `main.dart` via
/// `MaterialApp.builder`) so the values are ready before any screen builds.
class ScreenUtil {
  ScreenUtil._();

  /// Baseline design canvas the UI was laid out against (logical px).
  static const double _designWidth = 375.0;
  static const double _designHeight = 812.0;

  static double _screenWidth = _designWidth;
  static double _screenHeight = _designHeight;
  static double _devicePixelRatio = 1.0;
  static double _statusBar = 0.0;
  static double _bottomBar = 0.0;

  /// Initialise from the current [MediaQuery]. Safe to call every frame.
  static void init(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    if (mq == null) return;
    _screenWidth = mq.size.width;
    _screenHeight = mq.size.height;
    _devicePixelRatio = mq.devicePixelRatio;
    _statusBar = mq.padding.top;
    _bottomBar = mq.padding.bottom;
  }

  static double get screenWidth => _screenWidth;
  static double get screenHeight => _screenHeight;
  static double get devicePixelRatio => _devicePixelRatio;
  static double get statusBarHeight => _statusBar;
  static double get bottomBarHeight => _bottomBar;

  /// True for larger phones / small tablets. Handy for the odd layout tweak.
  static bool get isLargeScreen => _screenWidth >= 600;

  /// Raw scale factors. Clamped so phones (small <-> large) stay balanced and
  /// nothing blows up on tablets. Width drives horizontal sizes, fonts and
  /// radii; height drives vertical spacing.
  static double get _widthScale =>
      (_screenWidth / _designWidth).clamp(0.82, 1.30);
  static double get _heightScale =>
      (_screenHeight / _designHeight).clamp(0.82, 1.30);

  /// Fonts use a slightly gentler curve so text never gets oversized.
  static double get _fontScale =>
      (_screenWidth / _designWidth).clamp(0.85, 1.20);

  /// Width-proportional size (horizontal padding, widths, icon sizes).
  static double w(double size) => size * _widthScale;

  /// Height-proportional size (vertical padding, heights, gaps).
  static double h(double size) => size * _heightScale;

  /// Generic / radius scaling (uses width scale).
  static double r(double size) => size * _widthScale;

  /// Scalable font size.
  static double sp(double size) => size * _fontScale;

  /// Fraction (0..1) of the screen width.
  static double sw(double fraction) => _screenWidth * fraction;

  /// Fraction (0..1) of the screen height.
  static double sh(double fraction) => _screenHeight * fraction;
}

/// Terse `num` extensions so design values read almost like the originals:
/// `16.w`, `24.h`, `18.sp`, `20.r`, plus `0.4.sw` / `0.3.sh` for fractions.
extension ResponsiveSizeExtension on num {
  /// Width-proportional size.
  double get w => ScreenUtil.w(toDouble());

  /// Height-proportional size.
  double get h => ScreenUtil.h(toDouble());

  /// Scalable font size.
  double get sp => ScreenUtil.sp(toDouble());

  /// Generic / radius scaling.
  double get r => ScreenUtil.r(toDouble());

  /// Fraction of screen width (expects 0..1).
  double get sw => ScreenUtil.sw(toDouble());

  /// Fraction of screen height (expects 0..1).
  double get sh => ScreenUtil.sh(toDouble());
}
