import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';

// Fixed facial-feature colours for the "character" stickers — these stay
// constant regardless of which palette colour the user picks for the body,
// the same way a real sticker's face doesn't recolour with its outfit.
const Color _ink = Color(0xFF4A3F3F);
const Color _blush = Color(0xFFFF8FA3);
const Color _heartEyeColor = Color(0xFFFF5177);

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
      case ElementShape.balloon:
        _drawBalloon(canvas, size, fill, color);
        break;
      case ElementShape.gift:
        _drawGift(canvas, size, fill, color);
        break;
      case ElementShape.crown:
        _drawCrown(canvas, size, fill);
        break;
      case ElementShape.moon:
        canvas.drawPath(_moonPath(c, r), fill);
        break;
      case ElementShape.cloud:
        canvas.drawPath(_cloudPath(size), fill);
        break;
      case ElementShape.bolt:
        canvas.drawPath(_boltPath(size), fill);
        break;
      case ElementShape.leaf:
        _drawLeaf(canvas, size, fill, color);
        break;
      case ElementShape.musicNote:
        _drawMusicNote(canvas, size, fill, color);
        break;
      case ElementShape.ribbon:
        _drawRibbon(canvas, size, fill, color);
        break;
      case ElementShape.confetti:
        _drawConfetti(canvas, size, fill);
        break;
      case ElementShape.happySun:
        _drawHappySun(canvas, size, fill);
        break;
      case ElementShape.winkStar:
        _drawWinkStar(canvas, c, r, fill);
        break;
      case ElementShape.blushHeart:
        _drawBlushHeart(canvas, size, fill);
        break;
      case ElementShape.sleepyMoon:
        _drawSleepyMoon(canvas, c, r, fill);
        break;
      case ElementShape.waveHand:
        _drawWaveHand(canvas, size, fill);
        break;
      case ElementShape.partyPopper:
        _drawPartyPopper(canvas, size, fill);
        break;
      case ElementShape.catFace:
        _drawCatFace(canvas, size, fill);
        break;
      case ElementShape.heartEyesFace:
        _drawHeartEyesFace(canvas, size, fill);
        break;
      case ElementShape.imageSticker:
        // Never actually painted — EditableElementWidget renders
        // element.assetPath as an Image instead of using this painter.
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

  void _drawBalloon(Canvas canvas, Size size, Paint fill, Color color) {
    final w = size.width, h = size.height;
    final path = Path()
      ..addOval(Rect.fromLTWH(w * 0.2, h * 0.04, w * 0.6, h * 0.62))
      ..moveTo(w * 0.45, h * 0.64)
      ..lineTo(w * 0.55, h * 0.64)
      ..lineTo(w * 0.5, h * 0.72)
      ..close();
    canvas.drawPath(path, fill);
    final string = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..isAntiAlias = true;
    final stringPath = Path()
      ..moveTo(w * 0.5, h * 0.72)
      ..quadraticBezierTo(w * 0.35, h * 0.82, w * 0.5, h * 0.9)
      ..quadraticBezierTo(w * 0.62, h * 0.97, w * 0.5, h * 1.0);
    canvas.drawPath(stringPath, string);
  }

  void _drawGift(Canvas canvas, Size size, Paint fill, Color color) {
    final w = size.width, h = size.height;
    final box = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.14, h * 0.38, w * 0.72, h * 0.5),
        Radius.circular(w * 0.04),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.26, w * 0.84, h * 0.14),
        Radius.circular(w * 0.03),
      ));
    canvas.drawPath(box, fill);
    // Ribbon + bow — a lighter tone of the same colour, matching the
    // flower's centre-dot trick, so a single-colour sticker still reads as
    // a two-tone icon.
    final ribbon = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..isAntiAlias = true;
    canvas.drawRect(Rect.fromLTWH(w * 0.44, h * 0.26, w * 0.12, h * 0.62), ribbon);
    final bow = Path()
      ..moveTo(w * 0.5, h * 0.26)
      ..cubicTo(w * 0.28, h * 0.06, w * 0.08, h * 0.14, w * 0.28, h * 0.24)
      ..cubicTo(w * 0.36, h * 0.28, w * 0.45, h * 0.27, w * 0.5, h * 0.26)
      ..cubicTo(w * 0.55, h * 0.27, w * 0.64, h * 0.28, w * 0.72, h * 0.24)
      ..cubicTo(w * 0.92, h * 0.14, w * 0.72, h * 0.06, w * 0.5, h * 0.26)
      ..close();
    canvas.drawPath(bow, ribbon);
  }

  void _drawCrown(Canvas canvas, Size size, Paint fill) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * 0.08, h * 0.8)
      ..lineTo(w * 0.08, h * 0.32)
      ..lineTo(w * 0.28, h * 0.52)
      ..lineTo(w * 0.5, h * 0.15)
      ..lineTo(w * 0.72, h * 0.52)
      ..lineTo(w * 0.92, h * 0.32)
      ..lineTo(w * 0.92, h * 0.8)
      ..close();
    canvas.drawPath(path, fill);
    for (final p in [
      Offset(w * 0.08, h * 0.32),
      Offset(w * 0.5, h * 0.15),
      Offset(w * 0.92, h * 0.32),
    ]) {
      canvas.drawCircle(p, w * 0.045, fill);
    }
  }

  Path _moonPath(Offset c, double r) {
    final full = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final bite = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(c.dx + r * 0.55, c.dy - r * 0.15),
        radius: r * 0.85,
      ));
    return Path.combine(PathOperation.difference, full, bite);
  }

  Path _cloudPath(Size size) {
    final w = size.width, h = size.height;
    return Path()
      ..addOval(Rect.fromCircle(center: Offset(w * 0.32, h * 0.55), radius: h * 0.22))
      ..addOval(Rect.fromCircle(center: Offset(w * 0.52, h * 0.4), radius: h * 0.28))
      ..addOval(Rect.fromCircle(center: Offset(w * 0.74, h * 0.55), radius: h * 0.2))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.5, w * 0.64, h * 0.27),
        Radius.circular(h * 0.13),
      ));
  }

  Path _boltPath(Size size) {
    final w = size.width, h = size.height;
    return Path()
      ..moveTo(w * 0.58, h * 0.04)
      ..lineTo(w * 0.22, h * 0.58)
      ..lineTo(w * 0.44, h * 0.58)
      ..lineTo(w * 0.34, h * 0.96)
      ..lineTo(w * 0.78, h * 0.38)
      ..lineTo(w * 0.56, h * 0.38)
      ..lineTo(w * 0.66, h * 0.04)
      ..close();
  }

  void _drawLeaf(Canvas canvas, Size size, Paint fill, Color color) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.95)
      ..quadraticBezierTo(w * 0.04, h * 0.55, w * 0.5, h * 0.05)
      ..quadraticBezierTo(w * 0.96, h * 0.55, w * 0.5, h * 0.95)
      ..close();
    canvas.drawPath(path, fill);
    final vein = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..isAntiAlias = true;
    canvas.drawLine(Offset(w * 0.5, h * 0.88), Offset(w * 0.5, h * 0.15), vein);
  }

  void _drawMusicNote(Canvas canvas, Size size, Paint fill, Color color) {
    final w = size.width, h = size.height;
    final stem = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.07
      ..isAntiAlias = true;
    canvas.drawLine(Offset(w * 0.62, h * 0.12), Offset(w * 0.62, h * 0.72), stem);
    final flag = Path()
      ..moveTo(w * 0.62, h * 0.12)
      ..quadraticBezierTo(w * 0.95, h * 0.2, w * 0.8, h * 0.42)
      ..quadraticBezierTo(w * 0.7, h * 0.3, w * 0.62, h * 0.34)
      ..close();
    canvas.drawPath(flag, fill);
    canvas.save();
    canvas.translate(w * 0.44, h * 0.78);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.3, height: h * 0.18),
      fill,
    );
    canvas.restore();
  }

  void _drawRibbon(Canvas canvas, Size size, Paint fill, Color color) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.5)
      ..cubicTo(w * 0.12, h * 0.12, w * 0.0, h * 0.35, w * 0.5, h * 0.5)
      ..moveTo(w * 0.5, h * 0.5)
      ..cubicTo(w * 0.88, h * 0.12, w * 1.0, h * 0.35, w * 0.5, h * 0.5)
      ..close();
    canvas.drawPath(path, fill);
    final knot = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.1, knot);
  }

  void _drawConfetti(Canvas canvas, Size size, Paint fill) {
    final w = size.width, h = size.height;
    // Fixed (not random) scatter — deterministic so shouldRepaint stays
    // correct and the sticker never flickers between rebuilds.
    const spots = [
      Offset(0.2, 0.22),
      Offset(0.5, 0.12),
      Offset(0.78, 0.28),
      Offset(0.14, 0.58),
      Offset(0.46, 0.5),
      Offset(0.82, 0.6),
      Offset(0.3, 0.84),
      Offset(0.66, 0.86),
    ];
    for (var i = 0; i < spots.length; i++) {
      final p = Offset(w * spots[i].dx, h * spots[i].dy);
      final s = w * (i.isEven ? 0.09 : 0.065);
      switch (i % 3) {
        case 0:
          canvas.drawRect(Rect.fromCenter(center: p, width: s, height: s), fill);
          break;
        case 1:
          canvas.drawCircle(p, s / 2, fill);
          break;
        default:
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(i * 0.7);
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: s * 1.3, height: s * 0.45),
            fill,
          );
          canvas.restore();
      }
    }
  }

  // ---- expressive "character" stickers --------------------------------------

  /// Shared cute face — dot or wink/closed eyes, a curved smile, optional
  /// blush. Reused by every character sticker so they all read as one family.
  void _drawCuteFace(
    Canvas canvas,
    Offset c,
    double r, {
    bool wink = false,
    bool closedEyes = false,
    bool blush = true,
  }) {
    final ink = Paint()
      ..color = _ink
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final inkStroke = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.09
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final eyeR = r * 0.11;
    final eyeDx = r * 0.32;
    final eyeDy = -r * 0.05;
    final leftEye = Offset(c.dx - eyeDx, c.dy + eyeDy);
    final rightEye = Offset(c.dx + eyeDx, c.dy + eyeDy);

    void drawEye(Offset p, bool closed) {
      if (closed) {
        final path = Path()
          ..moveTo(p.dx - eyeR, p.dy)
          ..quadraticBezierTo(p.dx, p.dy - eyeR * 1.3, p.dx + eyeR, p.dy);
        canvas.drawPath(path, inkStroke);
      } else {
        canvas.drawCircle(p, eyeR, ink);
      }
    }

    drawEye(leftEye, closedEyes || wink);
    drawEye(rightEye, closedEyes);

    final mouth = Path()
      ..moveTo(c.dx - r * 0.22, c.dy + r * 0.28)
      ..quadraticBezierTo(c.dx, c.dy + r * 0.48, c.dx + r * 0.22, c.dy + r * 0.28);
    canvas.drawPath(mouth, inkStroke);

    if (blush) {
      final blushPaint = Paint()
        ..color = _blush.withValues(alpha: 0.7)
        ..isAntiAlias = true;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(c.dx - r * 0.55, c.dy + r * 0.18),
            width: r * 0.32,
            height: r * 0.2),
        blushPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(c.dx + r * 0.55, c.dy + r * 0.18),
            width: r * 0.32,
            height: r * 0.2),
        blushPaint,
      );
    }
  }

  void _drawHappySun(Canvas canvas, Size size, Paint fill) {
    final w = size.width, h = size.height;
    final c = Offset(w / 2, h / 2);
    final bodyR = math.min(w, h) * 0.28;
    final rayInner = bodyR * 1.15;
    final rayOuter = bodyR * 1.55;
    const rayCount = 8;
    final rays = Path();
    for (int i = 0; i < rayCount; i++) {
      final a = (2 * math.pi / rayCount) * i;
      final perp = a + math.pi / 2;
      final baseHalf = bodyR * 0.16;
      final tip = Offset(c.dx + rayOuter * math.cos(a), c.dy + rayOuter * math.sin(a));
      final base1 = Offset(
        c.dx + rayInner * math.cos(a) + baseHalf * math.cos(perp),
        c.dy + rayInner * math.sin(a) + baseHalf * math.sin(perp),
      );
      final base2 = Offset(
        c.dx + rayInner * math.cos(a) - baseHalf * math.cos(perp),
        c.dy + rayInner * math.sin(a) - baseHalf * math.sin(perp),
      );
      rays.moveTo(base1.dx, base1.dy);
      rays.lineTo(tip.dx, tip.dy);
      rays.lineTo(base2.dx, base2.dy);
      rays.close();
    }
    canvas.drawPath(rays, fill);
    canvas.drawCircle(c, bodyR, fill);
    _drawCuteFace(canvas, c, bodyR);
  }

  void _drawWinkStar(Canvas canvas, Offset c, double r, Paint fill) {
    final starR = r * 0.95;
    canvas.drawPath(_starPath(c, starR, 5, starR * 0.45), fill);
    _drawCuteFace(canvas, Offset(c.dx, c.dy + r * 0.05), starR * 0.55,
        wink: true, blush: false);
  }

  void _drawBlushHeart(Canvas canvas, Size size, Paint fill) {
    canvas.drawPath(_heartPath(size), fill);
    final w = size.width, h = size.height;
    _drawCuteFace(canvas, Offset(w * 0.5, h * 0.42), w * 0.22);
  }

  void _drawSleepyMoon(Canvas canvas, Offset c, double r, Paint fill) {
    canvas.drawPath(_moonPath(c, r), fill);
    _drawCuteFace(canvas, Offset(c.dx - r * 0.15, c.dy), r * 0.55,
        closedEyes: true, blush: false);
  }

  void _drawWaveHand(Canvas canvas, Size size, Paint fill) {
    final w = size.width, h = size.height;
    final palm = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.28, h * 0.42, w * 0.44, h * 0.46),
      Radius.circular(w * 0.14),
    );
    canvas.drawRRect(palm, fill);

    final fingerW = w * 0.11;
    final fingerH = h * 0.42;
    const baseYFrac = 0.44;
    const angles = [-0.32, -0.11, 0.11, 0.32];
    for (final a in angles) {
      canvas.save();
      canvas.translate(w * 0.5 + a * w * 0.55, h * baseYFrac);
      canvas.rotate(a * 0.6);
      final finger = RRect.fromRectAndRadius(
        Rect.fromLTWH(-fingerW / 2, -fingerH, fingerW, fingerH),
        Radius.circular(fingerW / 2),
      );
      canvas.drawRRect(finger, fill);
      canvas.restore();
    }

    canvas.save();
    canvas.translate(w * 0.26, h * 0.58);
    canvas.rotate(-0.9);
    final thumb = RRect.fromRectAndRadius(
      Rect.fromLTWH(-w * 0.07, -h * 0.02, w * 0.14, h * 0.32),
      Radius.circular(w * 0.07),
    );
    canvas.drawRRect(thumb, fill);
    canvas.restore();
  }

  void _drawPartyPopper(Canvas canvas, Size size, Paint fill) {
    final w = size.width, h = size.height;
    final cone = Path()
      ..moveTo(w * 0.22, h * 0.92)
      ..lineTo(w * 0.5, h * 0.42)
      ..lineTo(w * 0.62, h * 0.92)
      ..close();
    canvas.drawPath(cone, fill);

    // Confetti bursting from the top — fixed bright colours regardless of the
    // base colour, since confetti is inherently multi-coloured. Fixed (not
    // random) positions so shouldRepaint stays correct.
    const bits = [
      (dx: -0.1, dy: -0.3, c: Color(0xFFFFD54F)),
      (dx: 0.12, dy: -0.36, c: Color(0xFF4FC3F7)),
      (dx: -0.28, dy: -0.15, c: Color(0xFFFF7043)),
      (dx: 0.3, dy: -0.18, c: Color(0xFF81C784)),
      (dx: 0.02, dy: -0.44, c: Color(0xFFBA68C8)),
      (dx: -0.35, dy: -0.35, c: Color(0xFFFF5177)),
    ];
    for (final b in bits) {
      final p = Offset(w * 0.5 + w * b.dx, h * 0.42 + h * b.dy);
      final bitFill = Paint()
        ..color = b.c
        ..isAntiAlias = true;
      canvas.drawCircle(p, w * 0.045, bitFill);
    }
  }

  void _drawCatFace(Canvas canvas, Size size, Paint fill) {
    final w = size.width, h = size.height;
    final c = Offset(w * 0.5, h * 0.55);
    final r = math.min(w, h) * 0.32;

    final leftEar = Path()
      ..moveTo(c.dx - r * 0.9, c.dy - r * 0.6)
      ..lineTo(c.dx - r * 0.35, c.dy - r * 1.35)
      ..lineTo(c.dx - r * 0.15, c.dy - r * 0.55)
      ..close();
    final rightEar = Path()
      ..moveTo(c.dx + r * 0.9, c.dy - r * 0.6)
      ..lineTo(c.dx + r * 0.35, c.dy - r * 1.35)
      ..lineTo(c.dx + r * 0.15, c.dy - r * 0.55)
      ..close();
    canvas.drawPath(leftEar, fill);
    canvas.drawPath(rightEar, fill);
    canvas.drawCircle(c, r, fill);

    final ink = Paint()
      ..color = _ink
      ..isAntiAlias = true;
    final eyeR = r * 0.12;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(c.dx - r * 0.32, c.dy - r * 0.05),
          width: eyeR * 1.3,
          height: eyeR * 1.8),
      ink,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(c.dx + r * 0.32, c.dy - r * 0.05),
          width: eyeR * 1.3,
          height: eyeR * 1.8),
      ink,
    );

    final nose = Paint()
      ..color = _blush
      ..isAntiAlias = true;
    final nosePath = Path()
      ..moveTo(c.dx - r * 0.08, c.dy + r * 0.18)
      ..lineTo(c.dx + r * 0.08, c.dy + r * 0.18)
      ..lineTo(c.dx, c.dy + r * 0.3)
      ..close();
    canvas.drawPath(nosePath, nose);

    final whisker = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.04
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    for (final dy in [-0.04, 0.06, 0.16]) {
      canvas.drawLine(
        Offset(c.dx - r * 0.35, c.dy + r * dy + r * 0.2),
        Offset(c.dx - r * 0.95, c.dy + r * dy + r * 0.12),
        whisker,
      );
      canvas.drawLine(
        Offset(c.dx + r * 0.35, c.dy + r * dy + r * 0.2),
        Offset(c.dx + r * 0.95, c.dy + r * dy + r * 0.12),
        whisker,
      );
    }
  }

  void _drawHeartEyesFace(Canvas canvas, Size size, Paint fill) {
    final w = size.width, h = size.height;
    final c = Offset(w * 0.5, h * 0.5);
    final r = math.min(w, h) * 0.4;
    canvas.drawCircle(c, r, fill);

    final heartPaint = Paint()
      ..color = _heartEyeColor
      ..isAntiAlias = true;
    final eyeSize = Size(r * 0.5, r * 0.5);
    for (final dx in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(
        c.dx + dx * r * 0.38 - eyeSize.width / 2,
        c.dy - r * 0.15 - eyeSize.height / 2,
      );
      canvas.drawPath(_heartPath(eyeSize), heartPaint);
      canvas.restore();
    }

    final mouthPaint = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final mouth = Path()
      ..moveTo(c.dx - r * 0.25, c.dy + r * 0.3)
      ..quadraticBezierTo(c.dx, c.dy + r * 0.5, c.dx + r * 0.25, c.dy + r * 0.3);
    canvas.drawPath(mouth, mouthPaint);

    final blushPaint = Paint()
      ..color = _blush.withValues(alpha: 0.6)
      ..isAntiAlias = true;
    for (final dx in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(c.dx + dx * r * 0.62, c.dy + r * 0.15),
            width: r * 0.3,
            height: r * 0.18),
        blushPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ElementPainter old) =>
      old.shape != shape ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
