import 'package:flutter/material.dart';

/// Clips a box into a heart. Used for the "heart" image shape.
class HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(0.5 * w, h * 0.35);
    path.cubicTo(0.2 * w, h * 0.10, -0.25 * w, h * 0.45, 0.5 * w, h);
    path.moveTo(0.5 * w, h * 0.35);
    path.cubicTo(0.8 * w, h * 0.10, 1.25 * w, h * 0.45, 0.5 * w, h);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
