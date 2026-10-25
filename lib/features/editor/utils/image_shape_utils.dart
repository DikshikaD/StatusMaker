import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/widgets/heart_clipper.dart';

/// The natural (unscaled) box size for each on-canvas image shape. Shared by
/// [EditableImageWidget] and the photo-reposition screen so both crop the
/// photo identically — the user adjusts against exactly what will render.
Size baseSizeForImageShape(ImageShape shape) {
  switch (shape) {
    case ImageShape.square:
    case ImageShape.circle:
      return const Size(220, 220);
    case ImageShape.roundedRectangle:
      return const Size(220, 270);
    case ImageShape.oval:
      return const Size(200, 260);
    case ImageShape.heart:
      return const Size(240, 220);
  }
}

/// [shape]'s outline in a box of [size] — the same edge [clipToImageShape]
/// cuts along, for drawing a guide line around it.
Path imageShapePath(ImageShape shape, Size size) {
  final rect = Offset.zero & size;
  switch (shape) {
    case ImageShape.square:
      return Path()..addRect(rect);
    case ImageShape.roundedRectangle:
      return Path()
        ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24)));
    case ImageShape.circle:
    case ImageShape.oval:
      return Path()..addOval(rect);
    case ImageShape.heart:
      return HeartClipper().getClip(size);
  }
}

/// Clips [child] into [shape]'s outline.
Widget clipToImageShape(ImageShape shape, Widget child) {
  switch (shape) {
    case ImageShape.square:
      return child;
    case ImageShape.roundedRectangle:
      return ClipRRect(borderRadius: BorderRadius.circular(24), child: child);
    case ImageShape.circle:
    case ImageShape.oval:
      return ClipOval(child: child);
    case ImageShape.heart:
      return ClipPath(clipper: HeartClipper(), child: child);
  }
}
