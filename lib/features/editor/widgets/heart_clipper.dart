import 'package:flutter/material.dart';

/// Clips a box into a heart. Used for the "heart" image shape.
///
/// The heart touches all four edges of the box, so a photo fills the whole
/// slot. The old outline only covered about the lower 65% and middle 80% of
/// its box: the photo was cropped to a small heart sitting low inside a much
/// larger frame and selection box.
class HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    // The familiar Material "favorite" heart, normalised to a 1×1 box.
    return Path()
      ..moveTo(0.5 * w, h)
      ..lineTo(0.4275 * w, 0.9286 * h)
      ..cubicTo(0.17 * w, 0.6736 * h, 0, 0.5057 * h, 0, 0.2997 * h)
      ..cubicTo(0, 0.134 * h, 0.121 * w, 0, 0.275 * w, 0)
      ..cubicTo(0.362 * w, 0, 0.4455 * w, 0.0441 * h, 0.5 * w, 0.1139 * h)
      ..cubicTo(0.5545 * w, 0.0441 * h, 0.638 * w, 0, 0.725 * w, 0)
      ..cubicTo(0.879 * w, 0, w, 0.1319 * h, w, 0.2997 * h)
      ..cubicTo(w, 0.5057 * h, 0.83 * w, 0.6736 * h, 0.5725 * w, 0.9292 * h)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
