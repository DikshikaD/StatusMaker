import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/widgets/heart_clipper.dart';

/// Paints the border of a photo slot in whichever [PhotoFrameStyle] the
/// design asks for. Shared by the locked canvas and the free editor so a
/// design looks the same in both — they used to carry two identical private
/// painters, which is how the two could have drifted.
///
/// Every style is drawn *inside* the slot's box and never changes the photo's
/// size or position, which is what makes it safe to toggle from the locked
/// toolbar.
class PhotoFramePainter extends CustomPainter {
  final ImageShape shape;
  final Color color;
  final PhotoFrameStyle style;

  const PhotoFramePainter({
    required this.shape,
    required this.color,
    this.style = PhotoFrameStyle.classic,
  });

  Path _outline(Size size, double inset) {
    final rect = Rect.fromLTWH(
        inset, inset, size.width - 2 * inset, size.height - 2 * inset);
    switch (shape) {
      case ImageShape.square:
        return Path()..addRect(rect);
      case ImageShape.roundedRectangle:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
              rect, Radius.circular(math.max(0, 24 - inset))));
      case ImageShape.circle:
      case ImageShape.oval:
        return Path()..addOval(rect);
      case ImageShape.heart:
        // The heart has no simple inset; shrink it about its centre instead.
        final base = HeartClipper().getClip(size);
        if (inset == 0) return base;
        final sx = (size.width - 2 * inset) / size.width;
        final sy = (size.height - 2 * inset) / size.height;
        // Scale about the centre: column-major 4×4 with the translation that
        // keeps (w/2, h/2) fixed. Built by hand so it doesn't depend on which
        // vector_math API the host SDK ships.
        final cx = size.width / 2, cy = size.height / 2;
        final m = Float64List.fromList([
          sx, 0, 0, 0, //
          0, sy, 0, 0, //
          0, 0, 1, 0, //
          cx - sx * cx, cy - sy * cy, 0, 1,
        ]);
        return base.transform(m);
    }
  }

  void _stroke(Canvas canvas, Size size, double width, Paint paint) {
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..isAntiAlias = true;
    canvas.drawPath(_outline(size, width / 2), paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case PhotoFrameStyle.classic:
        _stroke(canvas, size, 6, Paint()..color = color);
      case PhotoFrameStyle.thin:
        _stroke(canvas, size, 2.5, Paint()..color = color);
      case PhotoFrameStyle.doubleLine:
        _stroke(canvas, size, 1.5, Paint()..color = color);
        final p = Paint()
          ..color = color.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..isAntiAlias = true;
        canvas.drawPath(_outline(size, 7), p);
      case PhotoFrameStyle.gold:
        // A metallic sweep: light gold → deep gold → light gold along the
        // diagonal, which is what reads as "gold" rather than "yellow".
        final gold = Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(size.width, size.height),
            const [
              Color(0xFFFFF1B8),
              Color(0xFFD4AF37),
              Color(0xFF8A6A12),
              Color(0xFFF4D77A),
            ],
            const [0.0, 0.4, 0.7, 1.0],
          );
        _stroke(canvas, size, 5, gold);
        // Hairline inside for a bevelled look.
        final inner = Paint()
          ..color = const Color(0x99FFF7D6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..isAntiAlias = true;
        canvas.drawPath(_outline(size, 7), inner);
      case PhotoFrameStyle.glow:
        // Soft halo just inside the edge plus a crisp hairline.
        final halo = Paint()
          ..color = color.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..isAntiAlias = true;
        canvas.save();
        canvas.clipPath(_outline(size, 0));
        canvas.drawPath(_outline(size, 2), halo);
        canvas.restore();
        _stroke(canvas, size, 1.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant PhotoFramePainter old) =>
      old.shape != shape || old.color != color || old.style != style;
}

/// Feathers the edge of an already shape-clipped photo so it blends into the
/// background. Pure GPU gradient masks (no blur pass): radial for round
/// shapes, two crossed linear fades for rectangles. Hearts keep a hard edge —
/// a feathered heart just looks smudged.
///
/// [softEdge] is in the slot's own unscaled pixels; [size] is the slot box.
Widget softenPhotoEdge(ImageShape shape, double softEdge, Size size, Widget child) {
  if (softEdge <= 0) return child;
  switch (shape) {
    case ImageShape.circle:
    case ImageShape.oval:
      final r = math.max(size.width, size.height) / 2;
      final start = (1 - softEdge / r).clamp(0.0, 0.99);
      return ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => RadialGradient(
          colors: const [Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, start, 1.0],
          // Scale the circle to the oval's box so the fade follows the rim.
          radius: 0.5,
        ).createShader(bounds),
        child: child,
      );
    case ImageShape.square:
    case ImageShape.roundedRectangle:
      final fx = (softEdge / size.width).clamp(0.0, 0.45);
      final fy = (softEdge / size.height).clamp(0.0, 0.45);
      return ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent
          ],
          stops: [0.0, fy, 1 - fy, 1.0],
        ).createShader(bounds),
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent
            ],
            stops: [0.0, fx, 1 - fx, 1.0],
          ).createShader(bounds),
          child: child,
        ),
      );
    case ImageShape.heart:
      return child;
  }
}
