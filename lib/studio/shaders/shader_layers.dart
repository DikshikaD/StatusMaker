import 'package:flutter/material.dart';

import 'package:status_maker/studio/models/background_config.dart';
import 'package:status_maker/studio/shaders/studio_shaders.dart';

/// Typed constructors for every shader layer, so presets read like design
/// intent ("golden rays from the top-right") and the uniform order — which the
/// GLSL declares positionally — lives in exactly one place per shader.
///
/// All positions are normalised (0..1, y down). Colours are passed as RGB in
/// 0..1; alpha is ignored because every shader produces its own coverage.
class Layers {
  Layers._();

  static List<double> _rgb(Color c) => [c.r, c.g, c.b];

  // ---- shaders/mesh_gradient.frag ------------------------------------------
  /// Four-point mesh gradient. Usually the first (opaque) layer of a config.
  /// [softness] 1.5 = wide wash, 2 = classic mesh, 3–4 = distinct blobs.
  static ShaderLayer mesh({
    required List<(Offset, Color)> points,
    double warp = 0.35,
    double seed = 1.0,
    double softness = 2.0,
  }) {
    assert(points.length == 4, 'mesh gradient takes exactly 4 points');
    final u = <double>[];
    for (final (p, c) in points) {
      u
        ..add(p.dx)
        ..add(p.dy)
        ..addAll(_rgb(c));
    }
    u
      ..add(warp)
      ..add(seed)
      ..add(softness);
    return ShaderLayer(asset: StudioShaders.mesh, uniforms: u);
  }

  // ---- shaders/light_rays.frag ----------------------------------------------
  static ShaderLayer rays({
    required Offset origin,
    required Color color,
    double intensity = 0.6,
    double count = 14,
    double falloff = 2.2,
    double seed = 0.0,
    LayerBlend blend = LayerBlend.srcOver,
  }) =>
      ShaderLayer(
        asset: StudioShaders.rays,
        blend: blend,
        uniforms: [
          origin.dx,
          origin.dy,
          ..._rgb(color),
          intensity,
          count,
          falloff,
          seed,
        ],
      );

  // ---- shaders/soft_waves.frag ----------------------------------------------
  static ShaderLayer waves({
    required Color color,
    double baseY = 0.72,
    double amplitude = 0.04,
    double frequency = 1.2,
    double alpha = 0.22,
    double seed = 0.0,
    bool fromTop = false,
  }) =>
      ShaderLayer(
        asset: StudioShaders.waves,
        uniforms: [
          ..._rgb(color),
          baseY,
          amplitude,
          frequency,
          alpha,
          seed,
          fromTop ? 1.0 : 0.0,
        ],
      );

  // ---- shaders/bokeh.frag -----------------------------------------------------
  static ShaderLayer bokeh({
    required Color color,
    double density = 0.5,
    double size = 0.6,
    double seed = 0.0,
    double yBias = 0.0,
    double softness = 0.4,
    LayerBlend blend = LayerBlend.plus,
  }) =>
      ShaderLayer(
        asset: StudioShaders.bokeh,
        blend: blend,
        uniforms: [..._rgb(color), density, size, seed, yBias, softness],
      );

  // ---- shaders/texture_overlay.frag -----------------------------------------
  static ShaderLayer grain({double strength = 0.18, double scale = 1.0,
          double seed = 0.0}) =>
      ShaderLayer(
        asset: StudioShaders.texture,
        blend: LayerBlend.softLight,
        uniforms: [0, strength, scale, 0.5, 0.5, 0.5, seed],
      );

  static ShaderLayer paper({double strength = 0.35, double scale = 1.0,
          double seed = 0.0}) =>
      ShaderLayer(
        asset: StudioShaders.texture,
        blend: LayerBlend.softLight,
        uniforms: [1, strength, scale, 0.5, 0.5, 0.5, seed],
      );

  static ShaderLayer halftone(
          {required Color color,
          double strength = 0.25,
          double scale = 1.0}) =>
      ShaderLayer(
        asset: StudioShaders.texture,
        uniforms: [2, strength, scale, ..._rgb(color), 0],
      );

  static ShaderLayer dotGrid(
          {required Color color,
          double strength = 0.25,
          double scale = 1.0}) =>
      ShaderLayer(
        asset: StudioShaders.texture,
        uniforms: [3, strength, scale, ..._rgb(color), 0],
      );

  static ShaderLayer pinstripes(
          {required Color color,
          double strength = 0.12,
          double scale = 1.0}) =>
      ShaderLayer(
        asset: StudioShaders.texture,
        uniforms: [4, strength, scale, ..._rgb(color), 0],
      );

  // ---- flutter_shaders_ui: glow_orb.frag -------------------------------------
  /// A soft volumetric glow spot. Uniform order per the package's GlowOrb:
  /// position(2), radius, glowIntensity, color(3), pulseSpeed. Sampled at
  /// t = 0 so the orb's breathing pulse never moves.
  static ShaderLayer glow({
    required Offset position,
    required Color color,
    double radius = 0.25,
    double intensity = 0.8,
    LayerBlend blend = LayerBlend.srcOver,
  }) =>
      ShaderLayer(
        asset: StudioShaders.glowOrb,
        blend: blend,
        uniforms: [position.dx, position.dy, radius, intensity, ..._rgb(color), 0],
      );

  // ---- flutter_shaders_ui: aurora.frag ---------------------------------------
  /// Northern-lights curtain bands frozen at [time]. Order per AuroraEffect:
  /// intensity, speed, color1(3), color2(3).
  static ShaderLayer aurora({
    required Color color1,
    required Color color2,
    double intensity = 0.55,
    double time = 3.7,
  }) =>
      ShaderLayer(
        asset: StudioShaders.aurora,
        time: time,
        uniforms: [intensity, 1.0, ..._rgb(color1), ..._rgb(color2)],
      );

  // ---- flutter_shaders_ui: wave.frag -----------------------------------------
  /// Opaque flowing two-colour wave gradient (replaces the base mesh). Order
  /// per WaveBackground: amplitude, frequency, speed, color1(3), color2(3).
  static ShaderLayer flowingWaves({
    required Color color1,
    required Color color2,
    double amplitude = 0.3,
    double frequency = 2.0,
    double time = 1.9,
  }) =>
      ShaderLayer(
        asset: StudioShaders.waveBackground,
        time: time,
        uniforms: [amplitude, frequency, 1.0, ..._rgb(color1), ..._rgb(color2)],
      );
}
