import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/data/template_motif.dart';

/// Draws the decorative background motif for a template. Kept subtle and mostly
/// around the edges so the quote stays readable. [color] echoes the template's
/// text colour so decorations always contrast the background.
class MotifPainter extends CustomPainter {
  final TemplateMotif motif;
  final Color color;

  MotifPainter(this.motif, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    switch (motif) {
      case TemplateMotif.sun:
        _sun(canvas, size);
        break;
      case TemplateMotif.confetti:
        _confetti(canvas, size);
        break;
      case TemplateMotif.sparkles:
        _sparkles(canvas, size);
        break;
      case TemplateMotif.hearts:
        _hearts(canvas, size);
        break;
      case TemplateMotif.geometric:
        _geometric(canvas, size);
        break;
      case TemplateMotif.dots:
        _dots(canvas, size);
        break;
      case TemplateMotif.diya:
        _diya(canvas, size);
        break;
      case TemplateMotif.holi:
        _holi(canvas, size);
        break;
      case TemplateMotif.rakhi:
        _rakhi(canvas, size);
        break;
      case TemplateMotif.ganesh:
        _ganesh(canvas, size);
        break;
      case TemplateMotif.eid:
        _eid(canvas, size);
        break;
      case TemplateMotif.navratri:
        _navratri(canvas, size);
        break;
      case TemplateMotif.sunrise:
        _sunrise(canvas, size);
        break;
      case TemplateMotif.coffee:
        _coffee(canvas, size);
        break;
      case TemplateMotif.botanical:
        _botanical(canvas, size);
        break;
      case TemplateMotif.balloons:
        _balloons(canvas, size);
        break;
      case TemplateMotif.cake:
        _cake(canvas, size);
        break;
      case TemplateMotif.couple:
        _couple(canvas, size);
        break;
      case TemplateMotif.roses:
        _roses(canvas, size);
        break;
      case TemplateMotif.skyline:
        _skyline(canvas, size);
        break;
      case TemplateMotif.growth:
        _growth(canvas, size);
        break;
      case TemplateMotif.mountain:
        _mountain(canvas, size);
        break;
      case TemplateMotif.arrow:
        _arrow(canvas, size);
        break;
      case TemplateMotif.om:
        _om(canvas, size);
        break;
      case TemplateMotif.moonStars:
        _moonStars(canvas, size);
        break;
      case TemplateMotif.lotus:
        _lotus(canvas, size);
        break;
      case TemplateMotif.mandala:
        _mandala(canvas, size);
        break;
      case TemplateMotif.none:
        break;
    }
  }

  // ---- Devotional: glowing Om (ॐ) with halo + lotus + sparkles --------------
  void _om(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final c = Offset(w * 0.5, h * 0.2);
    // soft radial halo behind the symbol
    for (var i = 3; i >= 1; i--) {
      canvas.drawCircle(c, w * 0.10 * i, _fill(0.05 + (3 - i) * 0.03));
    }
    // radiating rays
    final ray = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..strokeWidth = w * 0.006
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi * 2 / 12;
      canvas.drawLine(
        c + Offset(math.cos(a) * w * 0.30, math.sin(a) * w * 0.30),
        c + Offset(math.cos(a) * w * 0.37, math.sin(a) * w * 0.37),
        ray,
      );
    }
    // the Om glyph, drawn as text so it always looks authentic
    _glyph(canvas, 'ॐ', c, w * 0.34, color.withValues(alpha: 0.9));
    // a small lotus resting at the base
    _lotusBloom(canvas, Offset(w * 0.5, h * 0.92), w * 0.16,
        color.withValues(alpha: 0.4));
    // scattered sparkles
    for (final s in const [
      [0.16, 0.5],
      [0.86, 0.46],
      [0.24, 0.7],
      [0.8, 0.72]
    ]) {
      _sparkle(canvas, Offset(s[0] * w, s[1] * h), w * 0.025, _fill(0.5));
    }
  }

  // ---- Good Night: crescent moon + stars + soft clouds ----------------------
  void _moonStars(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const glow = Color(0xFFFFF3B0);
    // crescent moon top-right
    final oc = Offset(w * 0.78, h * 0.16);
    final r = w * 0.13;
    final outer = Path()..addOval(Rect.fromCircle(center: oc, radius: r));
    final inner = Path()
      ..addOval(Rect.fromCircle(
          center: oc + Offset(r * 0.5, -r * 0.18), radius: r * 0.9));
    canvas.drawPath(Path.combine(PathOperation.difference, outer, inner),
        Paint()..color = glow.withValues(alpha: 0.85));
    // stars scattered across the sky
    const stars = [
      [0.14, 0.14, 0.9],
      [0.30, 0.24, 0.7],
      [0.5, 0.10, 0.8],
      [0.20, 0.42, 0.6],
      [0.62, 0.30, 0.7],
      [0.10, 0.70, 0.7],
      [0.44, 0.60, 0.6],
      [0.86, 0.66, 0.8],
      [0.70, 0.80, 0.6],
    ];
    for (final s in stars) {
      _star(canvas, Offset(s[0] * w, s[1] * h), w * 0.018,
          glow.withValues(alpha: s[2]));
    }
    // soft clouds low down
    final cloud = _fill(0.10);
    for (final cx in const [0.28, 0.72]) {
      final cc = Offset(cx * w, h * 0.9);
      canvas.drawOval(
          Rect.fromCenter(center: cc, width: w * 0.30, height: w * 0.10), cloud);
      canvas.drawOval(
          Rect.fromCenter(
              center: cc + Offset(-w * 0.1, w * 0.02),
              width: w * 0.18,
              height: w * 0.08),
          cloud);
    }
  }

  void _star(Canvas canvas, Offset c, double s, Color col) {
    final p = Paint()
      ..color = col
      ..strokeWidth = s * 0.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx - s, c.dy), Offset(c.dx + s, c.dy), p);
    canvas.drawLine(Offset(c.dx, c.dy - s), Offset(c.dx, c.dy + s), p);
    canvas.drawCircle(c, s * 0.18, Paint()..color = col);
  }

  // ---- Traditional: lotus flower over water ---------------------------------
  void _lotus(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _lotusBloom(canvas, Offset(w * 0.5, h * 0.86), w * 0.24,
        color.withValues(alpha: 0.4));
    // gentle water ripples
    final ripple = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.006;
    for (var i = 1; i <= 3; i++) {
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.94),
            width: w * (0.4 + i * 0.18),
            height: w * (0.12 + i * 0.05)),
        math.pi,
        math.pi,
        false,
        ripple,
      );
    }
  }

  void _lotusBloom(Canvas canvas, Offset c, double s, Color col) {
    final petal = Paint()..color = col;
    // back petals
    for (var i = -3; i <= 3; i++) {
      final a = i * 0.32;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(a);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, -s * 0.55), width: s * 0.28, height: s * 1.1),
        Paint()..color = col.withValues(alpha: col.a * 0.7),
      );
      canvas.restore();
    }
    // front petals
    for (var i = -2; i <= 2; i++) {
      final a = i * 0.4;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(a);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, -s * 0.4), width: s * 0.26, height: s * 0.85),
        petal,
      );
      canvas.restore();
    }
  }

  // ---- Devotional/Suvichar: mandala rings + radiating petals ----------------
  void _mandala(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final c = Offset(w * 0.5, h * 0.5);
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.005;
    for (final rf in const [0.22, 0.33, 0.44]) {
      canvas.drawCircle(c, w * rf, stroke);
    }
    // radiating petals on the outer ring
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi * 2 / 16;
      final pc = c + Offset(math.cos(a) * w * 0.44, math.sin(a) * w * 0.44);
      canvas.save();
      canvas.translate(pc.dx, pc.dy);
      canvas.rotate(a + math.pi / 2);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: w * 0.03, height: w * 0.075),
        _fill(0.10),
      );
      canvas.restore();
    }
    // inner dot rosette
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawCircle(
          c + Offset(math.cos(a) * w * 0.10, math.sin(a) * w * 0.10),
          w * 0.014,
          _fill(0.16));
    }
    canvas.drawCircle(c, w * 0.03, _fill(0.18));
  }

  /// Draws a text [glyph] centred at [c], sized to [fontSize], in [col].
  void _glyph(Canvas canvas, String glyph, Offset c, double fontSize, Color col) {
    final tp = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          fontSize: fontSize,
          color: col,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
  }

  // ---- Indian festival: string lights + diyas + rangoli ---------------------
  void _diya(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const gold = Color(0xFFFFD54F);
    const glow = Color(0xFFFFA000);
    const flame = Color(0xFFFF7043);
    const green = Color(0xFF66BB6A);

    // String lights across the top
    final topY = h * 0.05;
    canvas.drawLine(
      Offset(0, topY),
      Offset(w, topY),
      Paint()
        ..color = gold.withValues(alpha: 0.5)
        ..strokeWidth = 1.5,
    );
    const bulbs = 9;
    for (var i = 0; i < bulbs; i++) {
      final x = (i + 0.5) / bulbs * w;
      final by = topY + (i.isEven ? 0.035 : 0.055) * h;
      canvas.drawLine(
        Offset(x, topY),
        Offset(x, by - 4),
        Paint()
          ..color = gold.withValues(alpha: 0.4)
          ..strokeWidth = 1,
      );
      final c = i % 3 == 0 ? gold : (i % 3 == 1 ? flame : green);
      canvas.drawCircle(
          Offset(x, by), w * 0.014, Paint()..color = c.withValues(alpha: 0.9));
    }

    // Diyas along the bottom
    final diyaY = h * 0.9;
    for (final fx in const [0.3, 0.5, 0.7]) {
      _drawDiya(canvas, Offset(fx * w, diyaY), w * 0.11, glow, flame);
    }

    // Rangoli dot-flowers on the sides
    _rangoli(canvas, Offset(w * 0.12, h * 0.5), w * 0.05, gold);
    _rangoli(canvas, Offset(w * 0.88, h * 0.5), w * 0.05, gold);
  }

  void _drawDiya(Canvas canvas, Offset c, double s, Color body, Color flame) {
    // lamp base — filled lower half-ellipse
    final rect = Rect.fromCenter(center: c, width: s * 2, height: s);
    canvas.drawArc(
        rect, 0, 3.14159, true, Paint()..color = body.withValues(alpha: 0.85));
    canvas.drawLine(
      Offset(c.dx - s, c.dy),
      Offset(c.dx + s, c.dy),
      Paint()
        ..color = body
        ..strokeWidth = 2,
    );
    // flame teardrop
    final path = Path()
      ..moveTo(c.dx, c.dy - s * 0.95)
      ..quadraticBezierTo(c.dx + s * 0.3, c.dy - s * 0.2, c.dx, c.dy - s * 0.05)
      ..quadraticBezierTo(c.dx - s * 0.3, c.dy - s * 0.2, c.dx, c.dy - s * 0.95)
      ..close();
    canvas.drawPath(path, Paint()..color = flame.withValues(alpha: 0.9));
    // soft glow
    canvas.drawCircle(Offset(c.dx, c.dy - s * 0.45), s * 0.5,
        Paint()..color = flame.withValues(alpha: 0.15));
  }

  void _rangoli(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()..color = color.withValues(alpha: 0.22);
    for (var i = 0; i < 8; i++) {
      final a = i * 3.14159 / 4;
      canvas.drawCircle(
          c + Offset(r * math.cos(a), r * math.sin(a)), r * 0.18, p);
    }
    canvas.drawCircle(c, r * 0.22, p);
  }

  Paint _fill(double alpha) => Paint()..color = color.withValues(alpha: alpha);

  // Fixed fractional positions keep the layout stable across repaints.
  static const List<List<double>> _dotSpots = [
    [0.14, 0.10, 0.030],
    [0.82, 0.16, 0.050],
    [0.70, 0.07, 0.020],
    [0.20, 0.86, 0.044],
    [0.88, 0.80, 0.028],
    [0.52, 0.94, 0.020],
    [0.08, 0.52, 0.018],
    [0.92, 0.48, 0.024],
  ];

  void _dots(Canvas canvas, Size size) {
    final p = _fill(0.16);
    for (final s in _dotSpots) {
      canvas.drawCircle(
        Offset(s[0] * size.width, s[1] * size.height),
        s[2] * size.width,
        p,
      );
    }
  }

  void _sun(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.5, size.height * 0.17);
    canvas.drawCircle(c, size.width * 0.12, _fill(0.28));
    final ray = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi * 2 / 12;
      final r1 = size.width * 0.16;
      final r2 = size.width * 0.22;
      canvas.drawLine(
        c + Offset(math.cos(a) * r1, math.sin(a) * r1),
        c + Offset(math.cos(a) * r2, math.sin(a) * r2),
        ray,
      );
    }
    // a few soft dots near the base
    final p = _fill(0.12);
    canvas.drawCircle(Offset(size.width * 0.16, size.height * 0.85), size.width * 0.03, p);
    canvas.drawCircle(Offset(size.width * 0.84, size.height * 0.88), size.width * 0.025, p);
  }

  void _hearts(Canvas canvas, Size size) {
    const spots = [
      [0.16, 0.12, 0.13, 0.22],
      [0.82, 0.18, 0.16, 0.16],
      [0.70, 0.08, 0.09, 0.14],
      [0.22, 0.82, 0.15, 0.20],
      [0.86, 0.78, 0.11, 0.16],
      [0.50, 0.92, 0.10, 0.14],
      [0.10, 0.48, 0.08, 0.12],
    ];
    for (final s in spots) {
      _heart(
        canvas,
        Offset(s[0] * size.width, s[1] * size.height),
        s[2] * size.width,
        _fill(s[3]),
      );
    }
  }

  void _heart(Canvas canvas, Offset c, double s, Paint paint) {
    final r = s * 0.30;
    canvas.drawCircle(Offset(c.dx - r * 0.85, c.dy - r * 0.25), r, paint);
    canvas.drawCircle(Offset(c.dx + r * 0.85, c.dy - r * 0.25), r, paint);
    final path = Path()
      ..moveTo(c.dx - s * 0.62, c.dy)
      ..lineTo(c.dx, c.dy + s * 0.62)
      ..lineTo(c.dx + s * 0.62, c.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _sparkles(Canvas canvas, Size size) {
    const spots = [
      [0.16, 0.12, 0.055, 0.28],
      [0.82, 0.16, 0.070, 0.24],
      [0.68, 0.07, 0.035, 0.20],
      [0.24, 0.80, 0.060, 0.24],
      [0.86, 0.78, 0.045, 0.20],
      [0.50, 0.92, 0.040, 0.18],
      [0.10, 0.50, 0.035, 0.16],
      [0.92, 0.46, 0.030, 0.16],
    ];
    for (final s in spots) {
      _sparkle(
        canvas,
        Offset(s[0] * size.width, s[1] * size.height),
        s[2] * size.width,
        _fill(s[3]),
      );
    }
  }

  void _sparkle(Canvas canvas, Offset c, double s, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy - s)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + s, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + s)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - s, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - s)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _confetti(Canvas canvas, Size size) {
    const colors = [
      Colors.white,
      Color(0xFFFFE082),
      Color(0xFFF48FB1),
      Color(0xFF80DEEA),
      Color(0xFFA5D6A7),
    ];
    const spots = [
      [0.12, 0.10], [0.30, 0.06], [0.80, 0.12], [0.90, 0.28],
      [0.15, 0.40], [0.85, 0.50], [0.20, 0.70], [0.75, 0.72],
      [0.50, 0.14], [0.60, 0.86], [0.35, 0.90], [0.08, 0.60],
    ];
    for (var i = 0; i < spots.length; i++) {
      final p = Offset(spots[i][0] * size.width, spots[i][1] * size.height);
      final paint = Paint()..color = colors[i % colors.length].withValues(alpha: 0.7);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate((i * 37 % 360) * math.pi / 180);
      if (i.isEven) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: size.width * 0.03,
            height: size.width * 0.055,
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, size.width * 0.017, paint);
      }
      canvas.restore();
    }
  }

  void _geometric(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02;
    canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.14), size.width * 0.22, stroke);
    canvas.drawCircle(Offset(size.width * 0.10, size.height * 0.82), size.width * 0.16, stroke);
    final fill = Paint()..color = color.withValues(alpha: 0.10);
    final tri = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.45, size.height)
      ..lineTo(0, size.height * 0.68)
      ..close();
    canvas.drawPath(tri, fill);
  }

  // ---- Holi: powder splashes ------------------------------------------------
  void _holi(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const cols = [
      Color(0xFFE91E63), Color(0xFF9C27B0), Color(0xFF3F51B5),
      Color(0xFF00BCD4), Color(0xFF4CAF50), Color(0xFFFFEB3B), Color(0xFFFF5722),
    ];
    const spots = [
      [0.16, 0.18, 0.14], [0.84, 0.14, 0.16], [0.78, 0.82, 0.15],
      [0.20, 0.84, 0.12], [0.52, 0.08, 0.10], [0.92, 0.5, 0.10], [0.08, 0.55, 0.11],
    ];
    for (var i = 0; i < spots.length; i++) {
      final s = spots[i];
      final c = Offset(s[0] * w, s[1] * h);
      final col = cols[i % cols.length];
      canvas.drawCircle(
        c,
        s[2] * w,
        Paint()
          ..color = col.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      for (var j = 0; j < 6; j++) {
        final a = j * math.pi / 3;
        canvas.drawCircle(
          c + Offset(math.cos(a) * s[2] * w * 1.4, math.sin(a) * s[2] * w * 1.4),
          w * 0.008,
          Paint()..color = col.withValues(alpha: 0.6),
        );
      }
    }
  }

  // ---- Raksha Bandhan: thread + rakhi medallion -----------------------------
  void _rakhi(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cy = h * 0.15;
    const gold = Color(0xFFFFD54F), red = Color(0xFFD32F2F);
    canvas.drawLine(Offset(0, cy), Offset(w, cy),
        Paint()..color = red.withValues(alpha: 0.5)..strokeWidth = 3);
    final c = Offset(w * 0.5, cy);
    canvas.drawCircle(c, w * 0.06, Paint()..color = gold.withValues(alpha: 0.8));
    canvas.drawCircle(c, w * 0.032, Paint()..color = red.withValues(alpha: 0.8));
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawCircle(
        c + Offset(math.cos(a) * w * 0.08, math.sin(a) * w * 0.08),
        w * 0.013,
        Paint()..color = gold.withValues(alpha: 0.7),
      );
    }
  }

  // ---- Ganesh: lotus bloom --------------------------------------------------
  void _ganesh(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final c = Offset(w * 0.5, h * 0.9);
    const pink = Color(0xFFF06292), gold = Color(0xFFFFD54F);
    for (var i = -3; i <= 3; i++) {
      final a = i * 0.34;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(a);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, -w * 0.1), width: w * 0.05, height: w * 0.2),
        Paint()..color = pink.withValues(alpha: 0.45),
      );
      canvas.restore();
    }
    canvas.drawCircle(c, w * 0.04, Paint()..color = gold.withValues(alpha: 0.7));
  }

  // ---- Eid: crescent + lanterns + stars -------------------------------------
  void _eid(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const gold = Color(0xFFFFE082);
    final oc = Offset(w * 0.8, h * 0.16);
    final r = w * 0.11;
    final outer = Path()..addOval(Rect.fromCircle(center: oc, radius: r));
    final inner = Path()
      ..addOval(Rect.fromCircle(center: oc + Offset(r * 0.4, -r * 0.15), radius: r * 0.85));
    canvas.drawPath(Path.combine(PathOperation.difference, outer, inner),
        Paint()..color = gold.withValues(alpha: 0.85));
    for (final s in const [[0.2, 0.12], [0.5, 0.08], [0.62, 0.22], [0.15, 0.32]]) {
      _sparkle(canvas, Offset(s[0] * w, s[1] * h), w * 0.02,
          Paint()..color = gold.withValues(alpha: 0.7));
    }
    for (final lx in const [0.3, 0.68]) {
      _lantern(canvas, Offset(lx * w, h * 0.08), w * 0.05, gold);
    }
  }

  void _lantern(Canvas canvas, Offset top, double s, Color color) {
    canvas.drawLine(top, top + Offset(0, s * 0.4),
        Paint()..color = color.withValues(alpha: 0.4)..strokeWidth = 1.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: top + Offset(0, s * 1.1), width: s * 0.9, height: s * 1.2),
        Radius.circular(s * 0.3),
      ),
      Paint()..color = color.withValues(alpha: 0.5),
    );
  }

  // ---- Navratri: dandiya + garba ring ---------------------------------------
  void _navratri(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const cols = [Color(0xFFFF7043), Color(0xFFAB47BC), Color(0xFF26C6DA), Color(0xFFFFCA28)];
    final c = Offset(w * 0.5, h * 0.14);
    for (final rot in const [0.5, -0.5]) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w * 0.02, height: w * 0.16),
          Radius.circular(w * 0.01),
        ),
        Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.7),
      );
      canvas.restore();
    }
    final rc = Offset(w * 0.5, h * 0.85);
    final rr = w * 0.18;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      canvas.drawCircle(
        rc + Offset(math.cos(a) * rr, math.sin(a) * rr * 0.6),
        w * 0.012,
        Paint()..color = cols[i % cols.length].withValues(alpha: 0.7),
      );
    }
  }

  // ---- Morning: sunrise over mountains --------------------------------------
  void _sunrise(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const sun = Color(0xFFFFF3B0);
    final c = Offset(w * 0.5, h * 0.6);
    canvas.drawCircle(c, w * 0.16, Paint()..color = sun.withValues(alpha: 0.35));
    canvas.drawCircle(c, w * 0.11, Paint()..color = sun.withValues(alpha: 0.6));
    canvas.drawPath(
      Path()..moveTo(0, h)..lineTo(w * 0.35, h * 0.62)..lineTo(w * 0.62, h)..close(),
      Paint()..color = color.withValues(alpha: 0.25),
    );
    canvas.drawPath(
      Path()..moveTo(w * 0.45, h)..lineTo(w * 0.78, h * 0.7)..lineTo(w, h)..close(),
      Paint()..color = color.withValues(alpha: 0.18),
    );
  }

  // ---- Morning: coffee cup + steam ------------------------------------------
  void _coffee(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final c = Offset(w * 0.5, h * 0.76);
    final p = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.014
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - w * 0.11, c.dy)
        ..lineTo(c.dx - w * 0.09, c.dy + h * 0.11)
        ..lineTo(c.dx + w * 0.09, c.dy + h * 0.11)
        ..lineTo(c.dx + w * 0.11, c.dy)
        ..close(),
      p,
    );
    canvas.drawArc(
        Rect.fromCircle(center: Offset(c.dx + w * 0.14, c.dy + h * 0.05), radius: w * 0.045),
        -1.2, 2.4, false, p);
    canvas.drawLine(Offset(c.dx - w * 0.15, c.dy + h * 0.13),
        Offset(c.dx + w * 0.15, c.dy + h * 0.13), p);
    for (final dx in const [-0.04, 0.0, 0.04]) {
      final x = c.dx + dx * w;
      canvas.drawPath(
        Path()
          ..moveTo(x, c.dy - h * 0.02)
          ..quadraticBezierTo(x + w * 0.03, c.dy - h * 0.05, x, c.dy - h * 0.08)
          ..quadraticBezierTo(x - w * 0.03, c.dy - h * 0.11, x, c.dy - h * 0.14),
        p,
      );
    }
  }

  // ---- Morning/nature: botanical branches -----------------------------------
  void _botanical(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final leaf = Paint()..color = color.withValues(alpha: 0.3);
    final stem = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.008;
    _branch(canvas, Offset(w * 0.05, h * 0.04), Offset(w * 0.3, h * 0.3), leaf, stem, w);
    _branch(canvas, Offset(w * 0.96, h * 0.96), Offset(w * 0.7, h * 0.7), leaf, stem, w);
  }

  void _branch(Canvas canvas, Offset a, Offset b, Paint leaf, Paint stem, double w) {
    canvas.drawLine(a, b, stem);
    for (var i = 1; i <= 5; i++) {
      final t = i / 6;
      final pt = Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
      final side = i.isEven ? 1.0 : -1.0;
      canvas.drawOval(
        Rect.fromCenter(center: pt + Offset(side * w * 0.03, 0), width: w * 0.055, height: w * 0.022),
        leaf,
      );
    }
  }

  // ---- Birthday: balloons ---------------------------------------------------
  void _balloons(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const cols = [
      Color(0xFFEF5350), Color(0xFF42A5F5), Color(0xFFFFCA28), Color(0xFF66BB6A), Color(0xFFAB47BC),
    ];
    const spots = [[0.18, 0.2], [0.32, 0.11], [0.8, 0.16], [0.88, 0.34], [0.12, 0.4]];
    for (var i = 0; i < spots.length; i++) {
      final c = Offset(spots[i][0] * w, spots[i][1] * h);
      final col = cols[i % cols.length].withValues(alpha: 0.7);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w * 0.09, height: w * 0.11),
        Paint()..color = col,
      );
      canvas.drawLine(Offset(c.dx, c.dy + w * 0.055), Offset(c.dx, c.dy + w * 0.16),
          Paint()..color = col..strokeWidth = 1);
    }
  }

  // ---- Birthday: cake -------------------------------------------------------
  void _cake(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final c = Offset(w * 0.5, h * 0.85);
    const cream = Color(0xFFFFF3E0), pink = Color(0xFFF48FB1), flame = Color(0xFFFFB300);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: w * 0.34, height: h * 0.09),
          const Radius.circular(6)),
      Paint()..color = cream.withValues(alpha: 0.7),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: c + Offset(0, -h * 0.075), width: w * 0.24, height: h * 0.06),
          const Radius.circular(6)),
      Paint()..color = pink.withValues(alpha: 0.7),
    );
    for (final dx in const [-0.06, 0.0, 0.06]) {
      final x = c.dx + dx * w;
      canvas.drawLine(Offset(x, c.dy - h * 0.105), Offset(x, c.dy - h * 0.145),
          Paint()..color = cream..strokeWidth = 3);
      canvas.drawCircle(Offset(x, c.dy - h * 0.155), w * 0.01,
          Paint()..color = flame.withValues(alpha: 0.9));
    }
  }

  // ---- Love: couple silhouette ----------------------------------------------
  void _couple(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final base = h * 0.92;
    final p = Paint()..color = color.withValues(alpha: 0.5);
    _person(canvas, Offset(w * 0.42, base), w * 0.14, p);
    _person(canvas, Offset(w * 0.57, base), w * 0.15, p);
  }

  void _person(Canvas canvas, Offset feet, double s, Paint p) {
    canvas.drawCircle(Offset(feet.dx, feet.dy - s * 1.6), s * 0.35, p);
    canvas.drawPath(
      Path()
        ..moveTo(feet.dx - s * 0.35, feet.dy)
        ..lineTo(feet.dx, feet.dy - s * 1.25)
        ..lineTo(feet.dx + s * 0.35, feet.dy)
        ..close(),
      p,
    );
  }

  // ---- Love: roses ----------------------------------------------------------
  void _roses(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const rose = Color(0xFFEC407A), leaf = Color(0xFF66BB6A);
    for (final s in const [[0.14, 0.16], [0.86, 0.2], [0.8, 0.84]]) {
      final c = Offset(s[0] * w, s[1] * h);
      final p = Paint()
        ..color = rose.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.011;
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(c, w * 0.06 * (1 - i * 0.28), p);
      }
      canvas.drawOval(
        Rect.fromCenter(center: c + Offset(w * 0.05, w * 0.045), width: w * 0.05, height: w * 0.02),
        Paint()..color = leaf.withValues(alpha: 0.5),
      );
    }
  }

  // ---- Business: city skyline -----------------------------------------------
  void _skyline(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()..color = color.withValues(alpha: 0.22);
    const heights = [0.16, 0.26, 0.2, 0.34, 0.24, 0.3, 0.18, 0.28, 0.22];
    final bw = w / heights.length;
    for (var i = 0; i < heights.length; i++) {
      final bh = heights[i] * h;
      canvas.drawRect(Rect.fromLTWH(i * bw + bw * 0.1, h - bh, bw * 0.8, bh), p);
      for (var y = h - bh + 8; y < h - 8; y += 14) {
        canvas.drawRect(Rect.fromLTWH(i * bw + bw * 0.3, y, 3, 3),
            Paint()..color = color.withValues(alpha: 0.3));
      }
    }
  }

  // ---- Business: growth chart -----------------------------------------------
  void _growth(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final base = h * 0.9;
    final bar = Paint()..color = color.withValues(alpha: 0.2);
    const vals = [0.1, 0.16, 0.13, 0.22, 0.28];
    final bw = w * 0.1;
    for (var i = 0; i < vals.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.14 + i * bw * 1.25, base - vals[i] * h, bw, vals[i] * h),
            const Radius.circular(4)),
        bar,
      );
    }
    final line = Paint()
      ..color = const Color(0xFF66BB6A).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.15, base - 0.12 * h)
        ..lineTo(w * 0.4, base - 0.2 * h)
        ..lineTo(w * 0.62, base - 0.16 * h)
        ..lineTo(w * 0.86, base - 0.34 * h),
      line,
    );
    final ah = Offset(w * 0.86, base - 0.34 * h);
    canvas.drawLine(ah, ah + Offset(-w * 0.045, 0), line);
    canvas.drawLine(ah, ah + Offset(0, w * 0.045), line);
  }

  // ---- Motivation: mountain peak --------------------------------------------
  void _mountain(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawPath(
      Path()..moveTo(w * 0.1, h)..lineTo(w * 0.5, h * 0.35)..lineTo(w * 0.9, h)..close(),
      Paint()..color = color.withValues(alpha: 0.22),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.42, h * 0.46)
        ..lineTo(w * 0.5, h * 0.35)
        ..lineTo(w * 0.58, h * 0.46)
        ..lineTo(w * 0.53, h * 0.44)
        ..lineTo(w * 0.5, h * 0.48)
        ..lineTo(w * 0.47, h * 0.44)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );
    canvas.drawLine(Offset(w * 0.5, h * 0.35), Offset(w * 0.5, h * 0.28),
        Paint()..color = color.withValues(alpha: 0.5)..strokeWidth = 2);
    canvas.drawPath(
      Path()..moveTo(w * 0.5, h * 0.28)..lineTo(w * 0.56, h * 0.30)..lineTo(w * 0.5, h * 0.32)..close(),
      Paint()..color = const Color(0xFFEF5350).withValues(alpha: 0.7),
    );
  }

  // ---- Motivation: ascending arrows -----------------------------------------
  void _arrow(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    for (var i = 0; i < 3; i++) {
      final y = h * (0.32 + i * 0.13);
      canvas.drawPath(
        Path()..moveTo(w * 0.35, y)..lineTo(w * 0.5, y - h * 0.06)..lineTo(w * 0.65, y),
        Paint()
          ..color = color.withValues(alpha: 0.1 + (2 - i) * 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.028
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MotifPainter old) =>
      old.motif != motif || old.color != color;
}
