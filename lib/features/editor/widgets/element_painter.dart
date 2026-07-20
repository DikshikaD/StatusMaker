import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';

/// Draws a single decorative [ElementShape] in code — no image assets needed.
/// Everything is painted inside a unit box (the given [Size]) so the element
/// scales cleanly with the object's transform.
class ElementPainter extends CustomPainter {
  final ElementShape shape;
  final Color color;

  /// Thickness multiplier for stroked shapes (ring, line, arrow). 1.0 = default.
  final double strokeWidth;

  const ElementPainter({
    required this.shape,
    required this.color,
    this.strokeWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h / 2);
    final r = math.min(w, h) / 2;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = (r * 0.16 * strokeWidth).clamp(1.0, r)
      ..isAntiAlias = true;

    switch (shape) {
      case ElementShape.heart:
        canvas.drawPath(_heartPath(size), fill);
        break;
      case ElementShape.star:
        canvas.drawPath(_starPath(c, r, 5, r * 0.45), fill);
        break;
      case ElementShape.circle:
        canvas.drawCircle(c, r, fill);
        break;
      case ElementShape.ring:
        canvas.drawCircle(c, r - stroke.strokeWidth / 2, stroke);
        break;
      case ElementShape.sparkle:
        canvas.drawPath(_sparklePath(c, r), fill);
        break;
      case ElementShape.flower:
        _drawFlower(canvas, c, r, fill);
        break;
      case ElementShape.diamond:
        canvas.drawPath(_diamondPath(c, r), fill);
        break;
      case ElementShape.triangle:
        canvas.drawPath(_trianglePath(c, r), fill);
        break;
      case ElementShape.line:
        canvas.drawLine(
          Offset(w * 0.1, h / 2),
          Offset(w * 0.9, h / 2),
          stroke,
        );
        break;
      case ElementShape.arrow:
        _drawArrow(canvas, size, stroke);
        break;
    }
  }

  Path _heartPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.5, h * 0.88);
    path.cubicTo(w * 0.05, h * 0.58, w * 0.08, h * 0.16, w * 0.32, h * 0.16);
    path.cubicTo(w * 0.44, h * 0.16, w * 0.5, h * 0.28, w * 0.5, h * 0.33);
    path.cubicTo(w * 0.5, h * 0.28, w * 0.56, h * 0.16, w * 0.68, h * 0.16);
    path.cubicTo(w * 0.92, h * 0.16, w * 0.95, h * 0.58, w * 0.5, h * 0.88);
    path.close();
    return path;
  }

  Path _starPath(Offset c, double outer, int points, double inner) {
    final path = Path();
    final step = math.pi / points;
    double a = -math.pi / 2;
    for (int i = 0; i < points * 2; i++) {
      final rad = i.isEven ? outer : inner;
      final p = Offset(c.dx + rad * math.cos(a), c.dy + rad * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
      a += step;
    }
    path.close();
    return path;
  }

  Path _sparklePath(Offset c, double r) {
    // A four-point twinkle (concave diamond).
    final path = Path();
    final k = r * 0.32; // waist
    path.moveTo(c.dx, c.dy - r);
    path.quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy);
    path.quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r);
    path.quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy);
    path.quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r);
    path.close();
    return path;
  }

  void _drawFlower(Canvas canvas, Offset c, double r, Paint fill) {
    const petals = 6;
    final petalR = r * 0.5;
    final dist = r * 0.5;
    for (int i = 0; i < petals; i++) {
      final a = (2 * math.pi / petals) * i;
      final pc = Offset(c.dx + dist * math.cos(a), c.dy + dist * math.sin(a));
      canvas.drawCircle(pc, petalR, fill);
    }
    final center = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..isAntiAlias = true;
    canvas.drawCircle(c, r * 0.42, center);
  }

  Path _diamondPath(Offset c, double r) {
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.75, c.dy)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r * 0.75, c.dy)
      ..close();
  }

  Path _trianglePath(Offset c, double r) {
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.87, c.dy + r * 0.5)
      ..lineTo(c.dx - r * 0.87, c.dy + r * 0.5)
      ..close();
  }

  void _drawArrow(Canvas canvas, Size size, Paint stroke) {
    final w = size.width;
    final h = size.height;
    final y = h / 2;
    canvas.drawLine(Offset(w * 0.12, y), Offset(w * 0.85, y), stroke);
    final head = Path()
      ..moveTo(w * 0.65, y - h * 0.18)
      ..lineTo(w * 0.88, y)
      ..lineTo(w * 0.65, y + h * 0.18);
    canvas.drawPath(head, stroke);
  }

  @override
  bool shouldRepaint(covariant ElementPainter old) =>
      old.shape != shape ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
