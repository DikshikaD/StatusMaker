import 'dart:convert';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Colour (de)serialisation — same int encoding status_design.dart uses.
// ---------------------------------------------------------------------------
// ignore: deprecated_member_use
int colorToInt(Color c) => c.value;
Color colorFromInt(dynamic v) => Color((v as num).toInt());

/// How a layer composites onto what's already painted beneath it.
enum LayerBlend {
  srcOver(BlendMode.srcOver),
  softLight(BlendMode.softLight),
  overlay(BlendMode.overlay),
  screen(BlendMode.screen),
  multiply(BlendMode.multiply),
  plus(BlendMode.plus);

  const LayerBlend(this.mode);
  final BlendMode mode;

  static LayerBlend fromName(dynamic name) {
    for (final b in values) {
      if (b.name == name) return b;
    }
    return LayerBlend.srcOver;
  }
}

/// One paint pass of a generated background. Layers are painted in order on
/// top of the config's base gradient. Sealed so the painter's switch is
/// exhaustive — adding a layer kind means teaching the painter about it.
sealed class BackgroundLayer {
  const BackgroundLayer();

  Map<String, dynamic> toJson();

  static BackgroundLayer? fromJson(Map j) {
    switch (j['type']) {
      case 'shader':
        return ShaderLayer.fromJson(j);
      case 'vignette':
        return VignetteLayer.fromJson(j);
      case 'shape':
        return ShapeLayer.fromJson(j);
    }
    // Unknown kinds (from a newer app version) are skipped, not fatal.
    return null;
  }
}

/// A full-rect pass through a fragment shader. [uniforms] are the floats that
/// follow the three standard ones (`uResolution.x/y`, `uTime`) every shader in
/// this system — ours and flutter_shaders_ui's — declares first. [time] is the
/// frozen clock value: these backgrounds are stills, so an animated shader is
/// sampled once at this instant and never ticks.
class ShaderLayer extends BackgroundLayer {
  final String asset;
  final List<double> uniforms;
  final double time;
  final LayerBlend blend;

  const ShaderLayer({
    required this.asset,
    required this.uniforms,
    this.time = 0.0,
    this.blend = LayerBlend.srcOver,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'shader',
        'asset': asset,
        'u': uniforms,
        'time': time,
        'blend': blend.name,
      };

  factory ShaderLayer.fromJson(Map j) => ShaderLayer(
        asset: j['asset'] as String,
        uniforms: ((j['u'] as List?) ?? const [])
            .map((e) => (e as num).toDouble())
            .toList(),
        time: (j['time'] as num?)?.toDouble() ?? 0.0,
        blend: LayerBlend.fromName(j['blend']),
      );
}

/// Darkens (or tints) the edges so the centre reads as the lit area.
class VignetteLayer extends BackgroundLayer {
  final Color color;

  /// Edge opacity, 0..1.
  final double strength;

  /// Where the fade begins, as a fraction of the half-diagonal (0.3 = starts
  /// close to the centre, 0.8 = only the very corners darken).
  final double inner;

  const VignetteLayer({
    this.color = Colors.black,
    this.strength = 0.45,
    this.inner = 0.55,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'vignette',
        'color': colorToInt(color),
        'strength': strength,
        'inner': inner,
      };

  factory VignetteLayer.fromJson(Map j) => VignetteLayer(
        color: j['color'] == null ? Colors.black : colorFromInt(j['color']),
        strength: (j['strength'] as num?)?.toDouble() ?? 0.45,
        inner: (j['inner'] as num?)?.toDouble() ?? 0.55,
      );
}

/// The minimal geometric shapes drawn in Dart (no shader needed): a thin ring
/// behind a photo, a diagonal colour band, hairline corner brackets, …
enum ShapeKind {
  ring,
  disc,
  arc,
  diagonalBand,
  cornerBrackets,
  insetFrame,
  horizontalRule,
  dotRow,
  halfDisc,
}

/// A single vector decoration. Positions and sizes are *normalised to the
/// canvas width* (0..1) so one config renders identically at any size.
class ShapeLayer extends BackgroundLayer {
  final ShapeKind kind;
  final Color color;

  /// Centre (or anchor) point, normalised: x by width, y by height.
  final Offset center;

  /// Main dimension as a fraction of the canvas width (ring/disc radius, band
  /// thickness, bracket length, rule width, …).
  final double size;

  /// Stroke thickness in canvas-width fractions, for stroked kinds.
  final double stroke;

  /// Rotation in radians (bands, arcs).
  final double rotation;

  const ShapeLayer({
    required this.kind,
    required this.color,
    this.center = const Offset(0.5, 0.5),
    this.size = 0.3,
    this.stroke = 0.004,
    this.rotation = 0.0,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'shape',
        'kind': kind.name,
        'color': colorToInt(color),
        'cx': center.dx,
        'cy': center.dy,
        'size': size,
        'stroke': stroke,
        'rot': rotation,
      };

  factory ShapeLayer.fromJson(Map j) {
    var kind = ShapeKind.ring;
    for (final k in ShapeKind.values) {
      if (k.name == j['kind']) kind = k;
    }
    return ShapeLayer(
      kind: kind,
      color: j['color'] == null ? Colors.white : colorFromInt(j['color']),
      center: Offset(
        (j['cx'] as num?)?.toDouble() ?? 0.5,
        (j['cy'] as num?)?.toDouble() ?? 0.5,
      ),
      size: (j['size'] as num?)?.toDouble() ?? 0.3,
      stroke: (j['stroke'] as num?)?.toDouble() ?? 0.004,
      rotation: (j['rot'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// A complete, reproducible background: a base gradient plus an ordered stack
/// of layers. Small enough to live inside a saved design's JSON, which is what
/// lets a status made from a generated background reopen anywhere — there is
/// no image file to fetch, the device simply repaints it.
///
/// A config is a *recipe*, not a picture: ~50 recipes × a seed each give a
/// catalogue of distinct backgrounds for less storage than one JPEG.
class BackgroundConfig {
  /// Stable id, unique across the catalogue (`'morning_golden_rays'`).
  final String id;

  /// Owning studio category id. `'any'` for backgrounds offered everywhere.
  final String category;

  /// Base gradient, painted first and always available — it's also the
  /// fallback shown for the few frames before a shader program has compiled.
  final List<Color> gradient;
  final Alignment gradientBegin;
  final Alignment gradientEnd;

  final List<BackgroundLayer> layers;

  /// The text colour this background was designed to carry. Templates use it
  /// so a quote never ends up dark-on-dark when a background is swapped.
  final Color textColor;

  /// A second, muted text colour for names and captions.
  final Color mutedTextColor;

  /// Accent for dividers, rings and highlights.
  final Color accentColor;

  // Not const: [signature] is memoised in a mutable field below.
  BackgroundConfig({
    required this.id,
    required this.category,
    required this.gradient,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.layers = const [],
    required this.textColor,
    Color? mutedTextColor,
    Color? accentColor,
  })  : mutedTextColor = mutedTextColor ?? textColor,
        accentColor = accentColor ?? textColor;

  /// True when the design expects light text (dark background).
  bool get isDark => textColor.computeLuminance() > 0.5;

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'gradient': gradient.map(colorToInt).toList(),
        'bx': gradientBegin.x,
        'by': gradientBegin.y,
        'ex': gradientEnd.x,
        'ey': gradientEnd.y,
        'layers': layers.map((l) => l.toJson()).toList(),
        'text': colorToInt(textColor),
        'muted': colorToInt(mutedTextColor),
        'accent': colorToInt(accentColor),
      };

  factory BackgroundConfig.fromJson(Map<String, dynamic> j) {
    final layers = <BackgroundLayer>[];
    for (final l in (j['layers'] as List?) ?? const []) {
      final parsed = BackgroundLayer.fromJson(l as Map);
      if (parsed != null) layers.add(parsed);
    }
    final gradient =
        ((j['gradient'] as List?) ?? const []).map(colorFromInt).toList();
    return BackgroundConfig(
      id: j['id'] as String? ?? 'unknown',
      category: j['category'] as String? ?? 'any',
      gradient: gradient.length >= 2
          ? gradient
          : const [Color(0xFF1E293B), Color(0xFF0F172A)],
      gradientBegin: Alignment(
        (j['bx'] as num?)?.toDouble() ?? -1,
        (j['by'] as num?)?.toDouble() ?? -1,
      ),
      gradientEnd: Alignment(
        (j['ex'] as num?)?.toDouble() ?? 1,
        (j['ey'] as num?)?.toDouble() ?? 1,
      ),
      layers: layers,
      textColor: j['text'] == null ? Colors.white : colorFromInt(j['text']),
      mutedTextColor: j['muted'] == null ? null : colorFromInt(j['muted']),
      accentColor: j['accent'] == null ? null : colorFromInt(j['accent']),
    );
  }

  /// Every shader asset this config paints with, for pre-loading.
  Iterable<String> get shaderAssets sync* {
    for (final l in layers) {
      if (l is ShaderLayer) yield l.asset;
    }
  }

  /// Stable fingerprint of the whole recipe — two configs with equal
  /// signatures paint identical pixels. Used as the thumbnail-cache key and by
  /// the painter's `shouldRepaint`. Computed lazily and kept: configs are
  /// immutable, and the catalogue asks for this on every card build.
  String get signature => _signature ??= jsonEncode(toJson());
  String? _signature;

  @override
  bool operator ==(Object other) =>
      other is BackgroundConfig && other.signature == signature;

  @override
  int get hashCode => signature.hashCode;
}
