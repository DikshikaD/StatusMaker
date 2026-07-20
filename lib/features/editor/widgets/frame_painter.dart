import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';

/// Draws a decorative border around the whole status canvas. Rendered as a
/// non-interactive top overlay so it frames text, photos and elements alike.
class FramePainter extends CustomPainter {
  final StatusFrame frame;
  final Color color;

  /// Thickness multiplier applied to every frame style. 1.0 = default.
  final double width;

  const FramePainter({
    required this.frame,
    required this.color,
    this.width = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (frame == StatusFrame.none) return;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    switch (frame) {
      case StatusFrame.none:
        return;
      case StatusFrame.thin:
        stroke.strokeWidth = 3 * width;
        canvas.drawRect(_inset(size, 12), stroke);
        break;
      case StatusFrame.thick:
        stroke.strokeWidth = 10 * width;
        canvas.drawRect(_inset(size, 16), stroke);
        break;
      case StatusFrame.doubleLine:
        stroke.strokeWidth = 2.5 * width;
        canvas.drawRect(_inset(size, 12), stroke);
        canvas.drawRect(_inset(size, 20), stroke);
        break;
      case StatusFrame.rounded:
        stroke.strokeWidth = 5 * width;
        canvas.drawRRect(
          RRect.fromRectAndRadius(_inset(size, 14), const Radius.circular(28)),
          stroke,
        );
        break;
      case StatusFrame.inset:
        stroke.strokeWidth = 4 * width;
        canvas.drawRRect(
          RRect.fromRectAndRadius(_inset(size, 22), const Radius.circular(18)),
          stroke,
        );
        break;
      case StatusFrame.dashed:
        stroke.strokeWidth = 4 * width;
        _drawDashedRect(canvas, _inset(size, 14), stroke, dash: 16, gap: 10);
        break;
      case StatusFrame.corners:
        stroke.strokeWidth = 5 * width;
        stroke.strokeCap = StrokeCap.round;
        _drawCorners(canvas, _inset(size, 16), stroke);
        break;
    }
  }

  Rect _inset(Size size, double d) =>
      Rect.fromLTWH(d, d, size.width - 2 * d, size.height - 2 * d);

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint,
      {required double dash, required double gap}) {
    final path = Path()..addRect(rect);
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = dist + dash;
        canvas.drawPath(
          metric.extractPath(dist, next.clamp(0, metric.length)),
          paint,
        );
        dist = next + gap;
      }
    }
  }

  void _drawCorners(Canvas canvas, Rect rect, Paint paint) {
    final len = rect.shortestSide * 0.18;
    // top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(len, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, len), paint);
    // top-right
    canvas.drawLine(rect.topRight, rect.topRight + Offset(-len, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, len), paint);
    // bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(len, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(0, -len), paint);
    // bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(-len, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(0, -len), paint);
  }

  @override
  bool shouldRepaint(covariant FramePainter old) =>
      old.frame != frame || old.color != color || old.width != width;
}
