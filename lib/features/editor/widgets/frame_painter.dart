import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';

/// Draws a decorative frame around the whole status canvas. Rendered as a
/// non-interactive top overlay so it frames text, photos and elements alike.
///
/// Two families live here:
///  * the plain borders ([StatusFrame.thin] … [StatusFrame.inset]), and
///  * the decorative ones ([StatusFrame.musicPlayer] onwards) — little scenes
///    (a player bar, a story progress row, film sprockets, a phone screen)
///    in the spirit of what people share as reels/pins.
///
/// Every measurement is a fraction of the canvas' short edge, never a raw
/// pixel count, so one painter renders identically in the ~100px picker tile
/// and on the 1080px export. [width] scales line weights only.
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
    final k = size.shortestSide;

    switch (frame) {
      case StatusFrame.none:
        return;
      case StatusFrame.thin:
        canvas.drawRect(_pad(size, k * 0.035), _line(k * 0.008));
        break;
      case StatusFrame.thick:
        canvas.drawRect(_pad(size, k * 0.048), _line(k * 0.028));
        break;
      case StatusFrame.doubleLine:
        canvas.drawRect(_pad(size, k * 0.035), _line(k * 0.007));
        canvas.drawRect(_pad(size, k * 0.058), _line(k * 0.007));
        break;
      case StatusFrame.rounded:
        canvas.drawRRect(
          _rr(_pad(size, k * 0.04), k * 0.08),
          _line(k * 0.014),
        );
        break;
      case StatusFrame.inset:
        canvas.drawRRect(
          _rr(_pad(size, k * 0.065), k * 0.05),
          _line(k * 0.011),
        );
        break;
      case StatusFrame.dashed:
        _dashed(canvas, Path()..addRect(_pad(size, k * 0.04)),
            _line(k * 0.011), k * 0.046, k * 0.028);
        break;
      case StatusFrame.corners:
        _corners(canvas, _pad(size, k * 0.046), k);
        break;
      case StatusFrame.musicPlayer:
        _musicPlayer(canvas, size, k);
        break;
      case StatusFrame.waveform:
        _waveform(canvas, size, k);
        break;
      case StatusFrame.phoneScreen:
        _phoneScreen(canvas, size, k);
        break;
      case StatusFrame.storyBars:
        _storyBars(canvas, size, k);
        break;
      case StatusFrame.polaroid:
        _polaroid(canvas, size, k);
        break;
      case StatusFrame.filmStrip:
        _filmStrip(canvas, size, k);
        break;
      case StatusFrame.neonGlow:
        _neonGlow(canvas, size, k);
        break;
      case StatusFrame.tape:
        _tape(canvas, size, k);
        break;
      case StatusFrame.scallop:
        _scallop(canvas, size, k);
        break;
      case StatusFrame.arch:
        _arch(canvas, size, k);
        break;
      case StatusFrame.ticket:
        _ticket(canvas, size, k);
        break;
      case StatusFrame.flourish:
        _flourish(canvas, size, k);
        break;
      case StatusFrame.dots:
        _dots(canvas, size, k);
        break;
      case StatusFrame.vignette:
        _vignette(canvas, size, k);
        break;
      case StatusFrame.sparkle:
        _sparkle(canvas, size, k);
        break;
      case StatusFrame.gradientRing:
        _gradientRing(canvas, size, k);
        break;
    }
  }

  // ── shared helpers ─────────────────────────────────────────────────────────

  Rect _pad(Size size, double d) =>
      Rect.fromLTWH(d, d, size.width - 2 * d, size.height - 2 * d);

  RRect _rr(Rect r, double radius) =>
      RRect.fromRectAndRadius(r, Radius.circular(radius));

  /// Stroke paint. [w] is the *base* weight — the user's width multiplier is
  /// applied here so every style reacts to the slider consistently.
  Paint _line(double w, {double opacity = 1, StrokeCap cap = StrokeCap.butt}) =>
      Paint()
        ..color = color.withValues(alpha: color.a * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * width
        ..strokeCap = cap
        ..isAntiAlias = true;

  Paint _fill([double opacity = 1]) => Paint()
    ..color = color.withValues(alpha: color.a * opacity)
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  void _dashed(Canvas canvas, Path path, Paint paint, double dash, double gap) {
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

  void _corners(Canvas canvas, Rect rect, double k) {
    final paint = _line(k * 0.014, cap: StrokeCap.round);
    final len = rect.shortestSide * 0.18;
    void bracket(Offset o, double dx, double dy) {
      canvas.drawLine(o, o + Offset(dx * len, 0), paint);
      canvas.drawLine(o, o + Offset(0, dy * len), paint);
    }

    bracket(rect.topLeft, 1, 1);
    bracket(rect.topRight, -1, 1);
    bracket(rect.bottomLeft, 1, -1);
    bracket(rect.bottomRight, -1, -1);
  }

  /// Rounded "pill" glyphs shared by the player/story frames.
  void _pill(Canvas canvas, Rect r, Paint paint) =>
      canvas.drawRRect(_rr(r, r.shortestSide / 2), paint);

  // ── decorative frames ─────────────────────────────────────────────────────

  /// A now-playing bar pinned to the bottom: play glyph, progress track with a
  /// knob, and a music note — plus a hairline border to tie it to the edges.
  void _musicPlayer(Canvas canvas, Size size, double k) {
    canvas.drawRRect(_rr(_pad(size, k * 0.035), k * 0.07), _line(k * 0.006, opacity: 0.75));

    final barH = k * 0.115;
    final bar = Rect.fromLTWH(
      k * 0.09,
      size.height - k * 0.085 - barH,
      size.width - k * 0.18,
      barH,
    );
    _pill(canvas, bar, _fill(0.16));
    _pill(canvas, bar, _line(k * 0.005, opacity: 0.55));

    final cy = bar.center.dy;
    // play triangle
    final px = bar.left + barH * 0.55;
    final ph = barH * 0.30;
    canvas.drawPath(
      Path()
        ..moveTo(px - ph * 0.5, cy - ph)
        ..lineTo(px + ph * 0.9, cy)
        ..lineTo(px - ph * 0.5, cy + ph)
        ..close(),
      _fill(0.9),
    );

    // progress track + played portion + knob
    final trackL = px + barH * 0.7;
    final trackR = bar.right - barH * 0.95;
    final played = trackL + (trackR - trackL) * 0.62;
    canvas.drawLine(Offset(trackL, cy), Offset(trackR, cy),
        _line(k * 0.006, opacity: 0.35, cap: StrokeCap.round));
    canvas.drawLine(Offset(trackL, cy), Offset(played, cy),
        _line(k * 0.009, opacity: 0.95, cap: StrokeCap.round));
    canvas.drawCircle(Offset(played, cy), k * 0.016, _fill());

    // music note at the right end
    final nx = bar.right - barH * 0.5;
    final ny = cy;
    canvas.drawLine(Offset(nx + k * 0.012, ny - k * 0.032),
        Offset(nx + k * 0.012, ny + k * 0.014), _line(k * 0.007, cap: StrokeCap.round));
    canvas.drawCircle(Offset(nx + k * 0.002, ny + k * 0.016), k * 0.013, _fill(0.9));
  }

  /// Audio bars marching along the bottom edge, mirrored faintly at the top.
  void _waveform(Canvas canvas, Size size, double k) {
    // Fixed pattern rather than random so the frame is stable across repaints
    // (and identical in the picker and on the export).
    const pattern = <double>[
      0.35, 0.70, 1.00, 0.55, 0.28, 0.62, 0.95, 0.45, 0.75, 0.30,
      0.58, 0.88, 0.42, 0.68, 1.00, 0.36, 0.80, 0.50, 0.26, 0.64,
    ];
    canvas.drawRRect(_rr(_pad(size, k * 0.035), k * 0.06), _line(k * 0.006, opacity: 0.7));

    final left = k * 0.085;
    final right = size.width - k * 0.085;
    final step = (right - left) / pattern.length;
    final maxH = k * 0.115;
    final paint = _line(step * 0.34, cap: StrokeCap.round);
    final ghost = _line(step * 0.34, opacity: 0.3, cap: StrokeCap.round);

    for (var i = 0; i < pattern.length; i++) {
      final x = left + step * (i + 0.5);
      final h = maxH * pattern[i];
      final baseY = size.height - k * 0.075;
      canvas.drawLine(Offset(x, baseY), Offset(x, baseY - h), paint);
      // Sparser, shorter echo at the top: mirroring the bottom row one-for-one
      // made the top edge read as a ruler instead of a second waveform.
      if (i.isEven) {
        final topY = k * 0.072;
        final gh = maxH * pattern[pattern.length - 1 - i] * 0.34;
        canvas.drawLine(Offset(x, topY), Offset(x, topY + gh), ghost);
      }
    }
  }

  /// The outline of a phone display — big corner radius, notch pill, and the
  /// home indicator at the bottom.
  void _phoneScreen(Canvas canvas, Size size, double k) {
    final r = _pad(size, k * 0.03);
    canvas.drawRRect(_rr(r, k * 0.16), _line(k * 0.016));
    canvas.drawRRect(_rr(r.deflate(k * 0.022), k * 0.14),
        _line(k * 0.004, opacity: 0.4));

    final notchW = k * 0.30;
    final notchH = k * 0.048;
    _pill(
      canvas,
      Rect.fromLTWH(r.center.dx - notchW / 2, r.top + k * 0.028, notchW, notchH),
      _fill(0.9),
    );

    final homeW = k * 0.34;
    _pill(
      canvas,
      Rect.fromLTWH(r.center.dx - homeW / 2, r.bottom - k * 0.05, homeW, k * 0.014),
      _fill(0.85),
    );
  }

  /// Segmented story progress row at the top — a couple of watched segments,
  /// one mid-play, the rest still waiting.
  void _storyBars(Canvas canvas, Size size, double k) {
    const count = 5;
    const watched = 2;
    const progress = 0.45; // of the segment after the watched ones

    final left = k * 0.06;
    final right = size.width - k * 0.06;
    final gap = k * 0.022;
    final segW = (right - left - gap * (count - 1)) / count;
    final h = k * 0.016;
    final y = k * 0.055;

    for (var i = 0; i < count; i++) {
      final x = left + i * (segW + gap);
      final track = Rect.fromLTWH(x, y, segW, h);
      _pill(canvas, track, _fill(0.28));
      if (i < watched) {
        _pill(canvas, track, _fill(0.95));
      } else if (i == watched) {
        _pill(canvas, Rect.fromLTWH(x, y, segW * progress, h), _fill(0.95));
      }
    }

    canvas.drawRRect(
      _rr(Rect.fromLTRB(left, y + h + k * 0.05, right, size.height - k * 0.06),
          k * 0.05),
      _line(k * 0.007, opacity: 0.8),
    );
  }

  /// Photo-print look: even border with the wide caption strip at the bottom.
  void _polaroid(Canvas canvas, Size size, double k) {
    final pad = k * 0.055;
    final stripH = k * 0.17;
    final band = _fill(0.92);

    // Four bands instead of one big fill so the middle stays fully visible.
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, pad), band);
    canvas.drawRect(Rect.fromLTWH(0, 0, pad, size.height), band);
    canvas.drawRect(
        Rect.fromLTWH(size.width - pad, 0, pad, size.height), band);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - stripH, size.width, stripH),
      band,
    );
    // Hairline where the print meets the photo.
    canvas.drawRect(
      Rect.fromLTRB(pad, pad, size.width - pad, size.height - stripH),
      _line(k * 0.004, opacity: 0.35),
    );
  }

  /// Cinema strip: opaque bands top and bottom with sprocket holes punched
  /// through them, so whatever is behind shows through each hole.
  void _filmStrip(Canvas canvas, Size size, double k) {
    final bandH = k * 0.115;
    final bands = [
      Rect.fromLTWH(0, 0, size.width, bandH),
      Rect.fromLTWH(0, size.height - bandH, size.width, bandH),
    ];

    // saveLayer so BlendMode.clear punches the holes out of the band only,
    // instead of erasing the canvas underneath it.
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final b in bands) {
      canvas.drawRect(b, _fill(0.9));
    }
    final hole = Paint()..blendMode = BlendMode.clear;
    final holeW = k * 0.052;
    final holeH = bandH * 0.42;
    final step = holeW * 2.1;
    for (var x = step * 0.35; x < size.width - holeW; x += step) {
      for (final b in bands) {
        canvas.drawRRect(
          _rr(Rect.fromLTWH(x, b.center.dy - holeH / 2, holeW, holeH),
              holeW * 0.28),
          hole,
        );
      }
    }
    canvas.restore();
  }

  /// Layered blurred strokes so the border reads as a lit neon tube.
  void _neonGlow(Canvas canvas, Size size, double k) {
    final rr = _rr(_pad(size, k * 0.06), k * 0.09);
    for (final spec in const [[0.055, 0.18], [0.032, 0.28], [0.016, 0.45]]) {
      canvas.drawRRect(
        rr,
        _line(k * spec[0], opacity: spec[1])
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, k * spec[0] * 0.9),
      );
    }
    canvas.drawRRect(rr, _line(k * 0.008));
    canvas.drawRRect(rr, _line(k * 0.003, opacity: 0.9)
      ..color = Colors.white.withValues(alpha: 0.75));
  }

  /// Four strips of washi tape holding the status down at the corners.
  void _tape(Canvas canvas, Size size, double k) {
    final w = k * 0.34;
    final h = k * 0.080;
    // Centred well inside the corner, not on it: a strip pinned to the exact
    // corner gets clipped down to a solid triangle and stops reading as tape.
    final d = k * 0.125;
    final corners = <(Offset, double)>[
      (Offset(d, d), -math.pi / 4),
      (Offset(size.width - d, d), math.pi / 4),
      (Offset(d, size.height - d), math.pi / 4),
      (Offset(size.width - d, size.height - d), -math.pi / 4),
    ];
    for (final (at, angle) in corners) {
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(angle);
      final r = Rect.fromCenter(center: Offset.zero, width: w, height: h);
      canvas.drawRect(r, _fill(0.46));
      // Brighter lip along the long edges reads as the sheen on real tape.
      canvas.drawRect(r, _line(k * 0.005, opacity: 0.75));
      canvas.restore();
    }
  }

  /// Scalloped edge — a ring of little outward arcs, like a doily or a stamp.
  void _scallop(Canvas canvas, Size size, double k) {
    final r = _pad(size, k * 0.07);
    final d = k * 0.075; // scallop diameter
    final path = Path();

    void edge(Offset from, Offset to) {
      final len = (to - from).distance;
      final n = math.max(2, (len / d).round());
      final stepV = (to - from) / n.toDouble();
      for (var i = 0; i < n; i++) {
        final a = from + stepV * i.toDouble();
        final b = from + stepV * (i + 1).toDouble();
        path.moveTo(a.dx, a.dy);
        path.arcToPoint(b, radius: Radius.circular(stepV.distance * 0.62));
      }
    }

    edge(r.topLeft, r.topRight);
    edge(r.topRight, r.bottomRight);
    edge(r.bottomRight, r.bottomLeft);
    edge(r.bottomLeft, r.topLeft);
    canvas.drawPath(path, _line(k * 0.009));
  }

  /// A window arch — flat sides, rounded top, hairline echo inside.
  void _arch(Canvas canvas, Size size, double k) {
    final r = _pad(size, k * 0.06);
    Path arch(Rect b) {
      final radius = b.width / 2;
      final springY = b.top + radius;
      return Path()
        ..moveTo(b.left, b.bottom)
        ..lineTo(b.left, springY)
        ..arcToPoint(Offset(b.right, springY),
            radius: Radius.circular(radius), clockwise: true)
        ..lineTo(b.right, b.bottom)
        ..close();
    }

    canvas.drawPath(arch(r), _line(k * 0.013));
    canvas.drawPath(arch(r.deflate(k * 0.028)), _line(k * 0.004, opacity: 0.45));
  }

  /// Event-ticket stub: rounded card, a notch bitten out of each side, and a
  /// dashed tear line running between them.
  void _ticket(Canvas canvas, Size size, double k) {
    final r = _pad(size, k * 0.05);
    final tearY = r.top + r.height * 0.76;
    final notch = k * 0.055;

    final path = Path()
      ..moveTo(r.left + k * 0.06, r.top)
      ..lineTo(r.right - k * 0.06, r.top)
      ..arcToPoint(Offset(r.right, r.top + k * 0.06),
          radius: Radius.circular(k * 0.06))
      ..lineTo(r.right, tearY - notch)
      ..arcToPoint(Offset(r.right, tearY + notch),
          radius: Radius.circular(notch), clockwise: false)
      ..lineTo(r.right, r.bottom - k * 0.06)
      ..arcToPoint(Offset(r.right - k * 0.06, r.bottom),
          radius: Radius.circular(k * 0.06))
      ..lineTo(r.left + k * 0.06, r.bottom)
      ..arcToPoint(Offset(r.left, r.bottom - k * 0.06),
          radius: Radius.circular(k * 0.06))
      ..lineTo(r.left, tearY + notch)
      ..arcToPoint(Offset(r.left, tearY - notch),
          radius: Radius.circular(notch), clockwise: false)
      ..lineTo(r.left, r.top + k * 0.06)
      ..arcToPoint(Offset(r.left + k * 0.06, r.top),
          radius: Radius.circular(k * 0.06));

    canvas.drawPath(path, _line(k * 0.011));
    _dashed(
      canvas,
      Path()
        ..moveTo(r.left + notch * 1.6, tearY)
        ..lineTo(r.right - notch * 1.6, tearY),
      _line(k * 0.007, cap: StrokeCap.round),
      k * 0.030,
      k * 0.024,
    );
  }

  /// Ornate corner curls — one flourish drawn once, then mirrored into the
  /// other three corners with a flip transform.
  void _flourish(Canvas canvas, Size size, double k) {
    canvas.drawRect(_pad(size, k * 0.055), _line(k * 0.005, opacity: 0.55));

    final paint = _line(k * 0.010, cap: StrokeCap.round);
    final s = k * 0.20; // flourish extent

    final curl = Path()
      ..moveTo(0, s)
      ..cubicTo(0, s * 0.25, s * 0.25, 0, s, 0)
      ..moveTo(s * 0.16, s * 0.16)
      ..cubicTo(s * 0.16, s * 0.62, s * 0.52, s * 0.72, s * 0.62, s * 0.40)
      ..cubicTo(s * 0.68, s * 0.22, s * 0.46, s * 0.18, s * 0.40, s * 0.34);

    for (final flip in const [(1.0, 1.0), (-1.0, 1.0), (1.0, -1.0), (-1.0, -1.0)]) {
      canvas.save();
      canvas.translate(
        flip.$1 > 0 ? k * 0.055 : size.width - k * 0.055,
        flip.$2 > 0 ? k * 0.055 : size.height - k * 0.055,
      );
      canvas.scale(flip.$1, flip.$2);
      canvas.drawPath(curl, paint);
      canvas.restore();
    }
  }

  /// A beaded border: small dots all the way round, larger ones at the corners.
  void _dots(Canvas canvas, Size size, double k) {
    final r = _pad(size, k * 0.055);
    final gap = k * 0.055;
    final dot = _fill(0.9);
    final radius = k * 0.011;

    void run(Offset from, Offset to) {
      final len = (to - from).distance;
      final n = math.max(1, (len / gap).round());
      final stepV = (to - from) / n.toDouble();
      for (var i = 0; i < n; i++) {
        canvas.drawCircle(from + stepV * i.toDouble(), radius, dot);
      }
    }

    run(r.topLeft, r.topRight);
    run(r.topRight, r.bottomRight);
    run(r.bottomRight, r.bottomLeft);
    run(r.bottomLeft, r.topLeft);
    for (final c in [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]) {
      canvas.drawCircle(c, radius * 2.1, dot);
    }
  }

  /// Soft edge fade — the frame is the light itself rather than a line.
  void _vignette(Canvas canvas, Size size, double k) {
    final rect = Offset.zero & size;
    // The width slider deepens the fade here instead of thickening a line, so
    // it has to be clamped — alpha above 1.0 is an assertion failure.
    final w = width.clamp(0.4, 1.8);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.85,
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: 0.12 * w),
            color.withValues(alpha: 0.55 * w),
          ],
          stops: const [0.45, 0.75, 1.0],
        ).createShader(rect),
    );
    canvas.drawRRect(
      _rr(_pad(size, k * 0.05), k * 0.06),
      _line(k * 0.004, opacity: 0.5),
    );
  }

  /// Hairline border studded with four-point sparkles of varying size.
  void _sparkle(Canvas canvas, Size size, double k) {
    canvas.drawRRect(
      _rr(_pad(size, k * 0.045), k * 0.055),
      _line(k * 0.005, opacity: 0.7),
    );

    void star(Offset c, double r, double opacity) {
      final p = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx + r * 0.18, c.dy - r * 0.18, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx + r * 0.18, c.dy + r * 0.18, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx - r * 0.18, c.dy + r * 0.18, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx - r * 0.18, c.dy - r * 0.18, c.dx, c.dy - r)
        ..close();
      canvas.drawPath(p, _fill(opacity));
    }

    final r = _pad(size, k * 0.045);
    star(r.topLeft, k * 0.055, 0.95);
    star(r.topLeft + Offset(k * 0.075, k * 0.085), k * 0.022, 0.6);
    star(r.topRight, k * 0.038, 0.9);
    star(r.topRight + Offset(-k * 0.085, k * 0.06), k * 0.020, 0.55);
    star(r.bottomRight, k * 0.055, 0.95);
    star(r.bottomRight + Offset(-k * 0.08, -k * 0.09), k * 0.024, 0.6);
    star(r.bottomLeft, k * 0.036, 0.9);
    star(Offset(r.center.dx, r.top), k * 0.020, 0.5);
    star(Offset(r.center.dx, r.bottom), k * 0.024, 0.5);
  }

  /// Thick ring stroked with a sweep gradient built by rotating the picked
  /// colour's hue, so it stays on-palette whatever the user chose.
  void _gradientRing(Canvas canvas, Size size, double k) {
    final hsl = HSLColor.fromColor(color);
    final ramp = [
      for (final shift in const [0.0, 45.0, 110.0, 200.0, 300.0, 360.0])
        hsl
            .withHue((hsl.hue + shift) % 360)
            .withSaturation(math.max(0.55, hsl.saturation))
            .withLightness(hsl.lightness.clamp(0.45, 0.75))
            .toColor(),
    ];
    final rect = _pad(size, k * 0.045);
    canvas.drawRRect(
      _rr(rect, k * 0.075),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = k * 0.030 * width
        ..isAntiAlias = true
        ..shader = SweepGradient(colors: ramp).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant FramePainter old) =>
      old.frame != frame || old.color != color || old.width != width;
}

/// Short label shown under each swatch in the frames picker. Kept next to the
/// painter so adding a frame in one place is a compile-time nudge here too.
String frameLabelKey(StatusFrame f) => switch (f) {
      StatusFrame.none => 'none',
      StatusFrame.thin => 'frame_thin',
      StatusFrame.thick => 'frame_thick',
      StatusFrame.doubleLine => 'frame_double',
      StatusFrame.dashed => 'frame_dashed',
      StatusFrame.rounded => 'frame_rounded',
      StatusFrame.corners => 'frame_corners',
      StatusFrame.inset => 'frame_inset',
      StatusFrame.musicPlayer => 'frame_music',
      StatusFrame.waveform => 'frame_waveform',
      StatusFrame.phoneScreen => 'frame_screen',
      StatusFrame.storyBars => 'frame_story',
      StatusFrame.polaroid => 'frame_polaroid',
      StatusFrame.filmStrip => 'frame_film',
      StatusFrame.neonGlow => 'frame_neon',
      StatusFrame.tape => 'frame_tape',
      StatusFrame.scallop => 'frame_scallop',
      StatusFrame.arch => 'frame_arch',
      StatusFrame.ticket => 'frame_ticket',
      StatusFrame.flourish => 'frame_flourish',
      StatusFrame.dots => 'frame_dots',
      StatusFrame.vignette => 'frame_vignette',
      StatusFrame.sparkle => 'frame_sparkle',
      StatusFrame.gradientRing => 'frame_gradient',
    };
