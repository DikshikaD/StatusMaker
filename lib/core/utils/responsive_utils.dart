import 'package:flutter/material.dart';

extension ResponsiveContext on BuildContext {
  /// Returns a percentage of the screen width
  double wp(double percentage) {
    return MediaQuery.of(this).size.width * (percentage / 100);
  }

  /// Returns a percentage of the screen height
  double hp(double percentage) {
    return MediaQuery.of(this).size.height * (percentage / 100);
  }

  /// Returns responsive font size (relative to screen width)
  /// Base assumption: standard mobile width is around 375-400dp.
  double sp(double size) {
    return (MediaQuery.of(this).size.width / 375) * size;
  }
}
