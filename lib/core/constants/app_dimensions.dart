import 'package:status_maker/core/utils/responsive.dart';

/// App-wide spacing, radius and icon sizes.
///
/// These are now responsive getters (scaled via [ScreenUtil]) instead of raw
/// constants, so a value like [paddingMedium] adapts to the device size.
/// Because they are no longer compile-time constants they cannot be used inside
/// `const` expressions — drop the `const` keyword at those call sites.
class AppDimensions {
  // Padding & Margin
  static double get paddingXSmall => 4.0.r;
  static double get paddingSmall => 8.0.r;
  static double get paddingMedium => 16.0.r;
  static double get paddingLarge => 24.0.r;
  static double get paddingXLarge => 32.0.r;

  // Border Radius
  static double get radiusSmall => 8.0.r;
  static double get radiusMedium => 16.0.r;
  static double get radiusLarge => 24.0.r;
  static double get radiusXLarge => 32.0.r;
  static double get radiusCircular => 100.0.r;

  // Icon Sizes
  static double get iconSmall => 16.0.r;
  static double get iconMedium => 24.0.r;
  static double get iconLarge => 32.0.r;
}
