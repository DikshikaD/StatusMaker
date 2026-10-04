import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:status_maker/studio/models/background_config.dart';
import 'package:status_maker/studio/shaders/studio_shaders.dart';

/// Paints a [BackgroundConfig] into any canvas: the live editor, a template
/// preview card, the thumbnail cache and the 3x PNG export all go through
/// this one function, so they can't drift apart.
///
/// Every layer is a *static* draw — no tickers, no animation. The gradient
/// is painted first and unconditionally, so the picture is never blank while
/// a shader is still compiling (or if one never loads on a weak GPU).
void paintBackgroundConfig(Canvas canvas, Size size, BackgroundConfig config) {
  final rect = Offset.zero & size;

  // 1. Base gradient (also the fallback).
  final begin = config.gradientBegin.alongSize(size);
  final end = config.gradientEnd.alongSize(size);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(
        begin,
        end,
        config.gradient,
        _evenStops(config.gradient.length),
      ),
  );

  // 2. Layers, in order.
  for (final layer in config.layers) {
    switch (layer) {
      case ShaderLayer():
        _paintShader(canvas, rect, layer);
      case VignetteLayer():
        _paintVignette(canvas, rect, layer);
      case ShapeLayer():
        _paintShape(canvas, size, layer);
    }
  }
}

List<double>? _evenStops(int n) {
  if (n <= 2) return null;
  return [for (var i = 0; i < n; i++) i / (n - 1)];
}

void _paintShader(Canvas canvas, Rect rect, ShaderLayer layer) {
  final shader = StudioShaders.shaderFor(layer.asset);
  if (shader == null) return; // not compiled yet — repaint arrives via revision
  var i = 0;
  shader.setFloat(i++, rect.width);
  shader.setFloat(i++, rect.height);
  shader.setFloat(i++, layer.time);
  for (final u in layer.uniforms) {
    shader.setFloat(i++, u);
  }
  canvas.drawRect(
    rect,
    Paint()
      ..shader = shader
      ..blendMode = layer.blend.mode,
  );
}

void _paintVignette(Canvas canvas, Rect rect, VignetteLayer v) {
  final center = rect.center;
  final radius = math.sqrt(rect.width * rect.width + rect.height * rect.height) / 2;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          v.color.withValues(alpha: 0),
          v.color.withValues(alpha: v.strength.clamp(0.0, 1.0)),
        ],
        [v.inner.clamp(0.0, 0.99), 1.0],
      ),
  );
}

void _paintShape(Canvas canvas, Size size, ShapeLayer s) {
  final w = size.width;
  final c = Offset(s.center.dx * w, s.center.dy * size.height);
  final r = s.size * w;
  final stroke = Paint()
    ..color = s.color
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(0.5, s.stroke * w)
    ..isAntiAlias = true;
  final fill = Paint()
    ..color = s.color
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  switch (s.kind) {
    case ShapeKind.ring:
      canvas.drawCircle(c, r, stroke);
    case ShapeKind.disc:
      canvas.drawCircle(c, r, fill);
    case ShapeKind.halfDisc:
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(s.rotation);
      canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), 0,
          math.pi, true, fill);
      canvas.restore();
    case ShapeKind.arc:
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(s.rotation);
      stroke.strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r),
          -math.pi * 0.85, math.pi * 0.7, false, stroke);
      canvas.restore();
    case ShapeKind.diagonalBand:
      // A long rectangle through the anchor, rotated — wide enough to span
      // the canvas at any angle.
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(s.rotation);
      final len = (w + size.height) * 1.5;
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: len, height: r),
          fill);
      canvas.restore();
    case ShapeKind.cornerBrackets:
      // Thin L-shaped marks in all four corners, inset by `center`-independent
      // margin derived from size.
      final m = r; // margin
      final l = r * 1.6; // arm length
      final h = size.height;
      stroke.strokeCap = StrokeCap.square;
      final path = Path()
        ..moveTo(m, m + l)
        ..lineTo(m, m)
        ..lineTo(m + l, m)
        ..moveTo(w - m - l, m)
        ..lineTo(w - m, m)
        ..lineTo(w - m, m + l)
        ..moveTo(w - m, h - m - l)
        ..lineTo(w - m, h - m)
        ..lineTo(w - m - l, h - m)
        ..moveTo(m + l, h - m)
        ..lineTo(m, h - m)
        ..lineTo(m, h - m - l);
      canvas.drawPath(path, stroke);
    case ShapeKind.insetFrame:
      final m = r;
      canvas.drawRect(
          Rect.fromLTWH(m, m, w - 2 * m, size.height - 2 * m), stroke);
    case ShapeKind.horizontalRule:
      stroke.strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), stroke);
    case ShapeKind.dotRow:
      // Seven small dots centred on the anchor, spanning `size`.
      const n = 7;
      final dotR = math.max(1.0, s.stroke * w * 1.5);
      for (var i = 0; i < n; i++) {
        final t = n == 1 ? 0.5 : i / (n - 1);
        canvas.drawCircle(Offset(c.dx - r + 2 * r * t, c.dy), dotR, fill);
      }
  }
}

/// `CustomPainter` wrapper around [paintBackgroundConfig]. Subscribes to
/// [StudioShaders.revision] so it repaints when a program finishes loading,
/// and otherwise only when the recipe itself changes.
class BackgroundConfigPainter extends CustomPainter {
  final BackgroundConfig config;

  BackgroundConfigPainter(this.config) : super(repaint: StudioShaders.revision);

  @override
  void paint(Canvas canvas, Size size) =>
      paintBackgroundConfig(canvas, size, config);

  @override
  bool shouldRepaint(covariant BackgroundConfigPainter old) =>
      old.config.signature != config.signature;
}
