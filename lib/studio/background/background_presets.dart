import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/template_motif.dart';
import 'package:status_maker/studio/models/background_config.dart';
import 'package:status_maker/studio/models/category_model.dart';
import 'package:status_maker/studio/shaders/shader_layers.dart';

/// A catalogue entry: the painted recipe plus the optional hand-drawn motif
/// (`MotifPainter`) that sits on top of it, and a sub-theme tag for
/// categories whose occasions must not mix (Festival).
class BackgroundPreset {
  final BackgroundConfig config;
  final TemplateMotif motif;
  final Color? motifColor;
  final String? tag;

  const BackgroundPreset(
    this.config, {
    this.motif = TemplateMotif.none,
    this.motifColor,
    this.tag,
  });

  String get id => config.id;
  String get category => config.category;

  /// The editor-side background state this preset produces.
  BackgroundState toState() => BackgroundState(
        generated: config,
        motif: motif,
        motifColor: motifColor ?? config.accentColor,
      );
}

// Shorthand for mesh control points.
(Offset, Color) _pt(double x, double y, int argb) => (Offset(x, y), Color(argb));

const Color _white = Colors.white;

/// Every generated background, grouped by category in the comments below.
/// Each category has its own vocabulary of layers — Morning is rays and warm
/// mesh, Good Night is stars and aurora, Business is hairlines and gold,
/// Heartbreak is grain and vignette — so no two categories share a look.
final List<BackgroundPreset> kBackgroundPresets = [
  // =========================================================================
  // MORNING — sunrise, golden light, soft sky, peace
  // =========================================================================
  BackgroundPreset(
    BackgroundConfig(
      id: 'morning_golden_rays',
      category: 'morning',
      gradient: const [Color(0xFFFFF4D6), Color(0xFFFFC266), Color(0xFFFF8A5B)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.2, 0.1, 0xFFFFF7E0),
          _pt(0.85, 0.25, 0xFFFFD27F),
          _pt(0.3, 0.8, 0xFFFFA86B),
          _pt(0.9, 0.95, 0xFFF26D5B),
        ], warp: 0.3, seed: 1.0, softness: 2.0),
        Layers.rays(
            origin: const Offset(0.5, 0.06),
            color: const Color(0xFFFFF3C4),
            intensity: 0.7,
            count: 16,
            falloff: 2.0,
            seed: 0.3),
        Layers.grain(strength: 0.12, seed: 1),
      ],
      textColor: const Color(0xFF5A3300),
      mutedTextColor: const Color(0xFF8A5A1F),
      accentColor: const Color(0xFFB8741F),
    ),
    motif: TemplateMotif.sunrise,
    motifColor: const Color(0x66B8741F),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'morning_sky_mist',
      category: 'morning',
      gradient: const [Color(0xFFDDEBFF), Color(0xFFFFE7D1)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.05, 0xFFCFE3FF),
          _pt(0.9, 0.2, 0xFFFFFFFF),
          _pt(0.2, 0.7, 0xFFFFE0CC),
          _pt(0.85, 0.95, 0xFFE6D8FF),
        ], warp: 0.25, seed: 2.0, softness: 1.8),
        Layers.waves(
            color: _white,
            baseY: 0.78,
            amplitude: 0.035,
            frequency: 0.9,
            alpha: 0.25,
            seed: 1.2),
        Layers.bokeh(
            color: const Color(0xFFFFF8E1),
            density: 0.25,
            size: 0.3,
            softness: 0.9,
            yBias: 0.4,
            seed: 3),
        Layers.paper(strength: 0.2, seed: 2),
      ],
      textColor: const Color(0xFF2E4A6B),
      mutedTextColor: const Color(0xFF5E7A9B),
      accentColor: const Color(0xFFE0956B),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'morning_meadow',
      category: 'morning',
      gradient: const [Color(0xFFF3F9E3), Color(0xFFBFE0A3)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.15, 0.1, 0xFFFFFBE6),
          _pt(0.8, 0.15, 0xFFEAF5C8),
          _pt(0.2, 0.85, 0xFF9CCB7E),
          _pt(0.9, 0.9, 0xFF6FAE64),
        ], warp: 0.35, seed: 4.0),
        Layers.rays(
            origin: const Offset(0.08, 0.0),
            color: const Color(0xFFFFFBE6),
            intensity: 0.45,
            count: 12,
            falloff: 2.0,
            seed: 2.2),
        Layers.waves(
            color: const Color(0xFF5F9E52),
            baseY: 0.8,
            amplitude: 0.03,
            frequency: 1.1,
            alpha: 0.18,
            seed: 3.1),
        Layers.grain(strength: 0.1, seed: 4),
      ],
      textColor: const Color(0xFF28502A),
      mutedTextColor: const Color(0xFF4E7A4E),
      accentColor: const Color(0xFF3F6B3A),
    ),
    motif: TemplateMotif.botanical,
    motifColor: const Color(0x803F6B3A),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'morning_dawn_rose',
      category: 'morning',
      gradient: const [Color(0xFFFFE1E6), Color(0xFFFFC89A), Color(0xFFFFF3D1)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.2, 0.05, 0xFFFFD6DE),
          _pt(0.85, 0.3, 0xFFFFC2A8),
          _pt(0.3, 0.7, 0xFFFFE6C2),
          _pt(0.8, 1.0, 0xFFFFD98A),
        ], warp: 0.4, seed: 5.0, softness: 1.8),
        Layers.glow(
            position: const Offset(0.5, 0.98),
            color: const Color(0xFFFFD27F),
            radius: 0.45,
            intensity: 0.6),
        Layers.grain(strength: 0.1, seed: 5),
      ],
      textColor: const Color(0xFF6B2E3A),
      mutedTextColor: const Color(0xFF9A5A66),
      accentColor: const Color(0xFFC46A52),
    ),
  ),

  // =========================================================================
  // GOOD NIGHT — stars, moon glow, aurora, deep velvet
  // =========================================================================
  BackgroundPreset(
    BackgroundConfig(
      id: 'night_starfield',
      category: 'goodnight',
      gradient: const [Color(0xFF0B1026), Color(0xFF1B2A5A)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFF0A0F2A),
          _pt(0.9, 0.2, 0xFF1D2B5C),
          _pt(0.3, 0.8, 0xFF2A1F5E),
          _pt(0.8, 0.95, 0xFF101A3F),
        ], warp: 0.2, seed: 6.0),
        Layers.bokeh(
            color: _white,
            density: 0.55,
            size: 0.12,
            softness: 0.0,
            yBias: 0.6,
            seed: 6),
        Layers.glow(
            position: const Offset(0.78, 0.18),
            color: const Color(0xFFFFF4C2),
            radius: 0.18,
            intensity: 0.5),
        const VignetteLayer(strength: 0.35, inner: 0.6),
      ],
      textColor: _white,
      mutedTextColor: const Color(0xFFB8C2E0),
      accentColor: const Color(0xFFF6E7B0),
    ),
    motif: TemplateMotif.moonStars,
    motifColor: const Color(0x80F6E7B0),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'night_aurora',
      category: 'goodnight',
      gradient: const [Color(0xFF060B1E), Color(0xFF0F2235)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.aurora(
            color1: const Color(0xFF2DD4BF),
            color2: const Color(0xFF7C3AED),
            intensity: 0.5,
            time: 3.7),
        Layers.bokeh(
            color: _white,
            density: 0.3,
            size: 0.1,
            softness: 0.0,
            yBias: 0.3,
            seed: 7),
        Layers.grain(strength: 0.1, seed: 7),
      ],
      textColor: _white,
      mutedTextColor: const Color(0xFFA7C4CF),
      accentColor: const Color(0xFF5EEAD4),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'night_moonlit_sea',
      category: 'goodnight',
      gradient: const [Color(0xFF101A3A), Color(0xFF223A7A)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.5, 0.0, 0xFF0C1430),
          _pt(0.1, 0.4, 0xFF1A2A5C),
          _pt(0.9, 0.5, 0xFF24407F),
          _pt(0.5, 1.0, 0xFF0A1230),
        ], warp: 0.2, seed: 8.0, softness: 1.8),
        Layers.glow(
            position: const Offset(0.5, 0.3),
            color: const Color(0xFFE9F1FF),
            radius: 0.22,
            intensity: 0.55),
        Layers.waves(
            color: const Color(0xFF0A1230),
            baseY: 0.66,
            amplitude: 0.03,
            frequency: 1.4,
            alpha: 0.3,
            seed: 8.5),
      ],
      textColor: const Color(0xFFF1F5FF),
      mutedTextColor: const Color(0xFFAFC0E8),
      accentColor: const Color(0xFFE9F1FF),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'night_velvet',
      category: 'goodnight',
      gradient: const [Color(0xFF1A1033), Color(0xFF2B1B4F), Color(0xFF0E0A1F)],
      layers: [
        Layers.mesh(points: [
          _pt(0.2, 0.2, 0xFF2E1D5A),
          _pt(0.8, 0.1, 0xFF1A1033),
          _pt(0.2, 0.9, 0xFF0E0A1F),
          _pt(0.85, 0.75, 0xFF3A2466),
        ], warp: 0.3, seed: 9.0, softness: 2.2),
        Layers.bokeh(
            color: const Color(0xFFC8B6FF),
            density: 0.3,
            size: 0.35,
            softness: 0.9,
            seed: 9),
        const VignetteLayer(strength: 0.4, inner: 0.55),
      ],
      textColor: const Color(0xFFF3EEFF),
      mutedTextColor: const Color(0xFFB9A9E6),
      accentColor: const Color(0xFFC8B6FF),
    ),
  ),

  // =========================================================================
  // BHAKTI — saffron, gold, temple patterns, diyas, light
  // =========================================================================
  BackgroundPreset(
    BackgroundConfig(
      id: 'bhakti_saffron_light',
      category: 'bhakti',
      gradient: const [Color(0xFFFFB347), Color(0xFFE8641B)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.5, 0.0, 0xFFFFD27F),
          _pt(0.1, 0.5, 0xFFFF9F3D),
          _pt(0.9, 0.55, 0xFFF07A20),
          _pt(0.5, 1.0, 0xFFC94E12),
        ], warp: 0.25, seed: 10.0),
        Layers.rays(
            origin: const Offset(0.5, 0.0),
            color: const Color(0xFFFFF1C9),
            intensity: 0.8,
            count: 20,
            falloff: 1.8,
            seed: 1.1),
        Layers.bokeh(
            color: const Color(0xFFFFE49A),
            density: 0.35,
            size: 0.25,
            softness: 0.6,
            yBias: -0.5,
            seed: 10),
        Layers.grain(strength: 0.12, seed: 10),
      ],
      textColor: const Color(0xFF4A1E00),
      mutedTextColor: const Color(0xFF7A3F10),
      accentColor: const Color(0xFFFFF1C9),
    ),
    motif: TemplateMotif.mandala,
    motifColor: const Color(0x668A3A00),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'bhakti_temple_maroon',
      category: 'bhakti',
      gradient: const [Color(0xFF4A0E0E), Color(0xFF8B1E1E)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.2, 0.1, 0xFF3A0A0A),
          _pt(0.8, 0.2, 0xFF6A1414),
          _pt(0.5, 0.6, 0xFF8B1E1E),
          _pt(0.5, 1.0, 0xFF5A2A10),
        ], warp: 0.2, seed: 11.0),
        Layers.glow(
            position: const Offset(0.5, 0.84),
            color: const Color(0xFFFFB347),
            radius: 0.32,
            intensity: 0.7),
        Layers.bokeh(
            color: const Color(0xFFFFD27F),
            density: 0.3,
            size: 0.14,
            softness: 0.3,
            yBias: -0.4,
            seed: 11),
        const VignetteLayer(strength: 0.45, inner: 0.5),
      ],
      textColor: const Color(0xFFFFE9B0),
      mutedTextColor: const Color(0xFFE8C080),
      accentColor: const Color(0xFFF2C14E),
    ),
    motif: TemplateMotif.diya,
    motifColor: const Color(0xCCF2C14E),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'bhakti_golden_dawn',
      category: 'bhakti',
      gradient: const [Color(0xFFFFF3DC), Color(0xFFF7C873)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.5, 0.05, 0xFFFFF8E8),
          _pt(0.1, 0.5, 0xFFFBE2B0),
          _pt(0.9, 0.5, 0xFFF9D48F),
          _pt(0.5, 1.0, 0xFFE9A94A),
        ], warp: 0.2, seed: 12.0, softness: 1.8),
        Layers.rays(
            origin: const Offset(0.5, 0.12),
            color: _white,
            intensity: 0.5,
            count: 24,
            falloff: 2.0,
            seed: 2.4),
        Layers.paper(strength: 0.3, seed: 12),
        const ShapeLayer(
            kind: ShapeKind.ring,
            color: Color(0x80B8741F),
            center: Offset(0.5, 0.36),
            size: 0.3,
            stroke: 0.003),
      ],
      textColor: const Color(0xFF5A2E00),
      mutedTextColor: const Color(0xFF8A5A24),
      accentColor: const Color(0xFFB8741F),
    ),
    motif: TemplateMotif.lotus,
    motifColor: const Color(0x80A5285C),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'bhakti_peacock_blue',
      category: 'bhakti',
      gradient: const [Color(0xFF0B3C5D), Color(0xFF1F6F8B)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFF082C45),
          _pt(0.9, 0.2, 0xFF11536F),
          _pt(0.3, 0.8, 0xFF1F6F8B),
          _pt(0.9, 0.95, 0xFF0B3C5D),
        ], warp: 0.3, seed: 13.0),
        Layers.glow(
            position: const Offset(0.5, 0.25),
            color: const Color(0xFFFFE08A),
            radius: 0.2,
            intensity: 0.5),
        Layers.bokeh(
            color: const Color(0xFFFFE08A),
            density: 0.3,
            size: 0.14,
            softness: 0.4,
            seed: 13),
        Layers.grain(strength: 0.1, seed: 13),
      ],
      textColor: const Color(0xFFFFF6D5),
      mutedTextColor: const Color(0xFFC9DDE6),
      accentColor: const Color(0xFFFFE08A),
    ),
    motif: TemplateMotif.sparkles,
    motifColor: const Color(0x99FFE08A),
  ),

  // =========================================================================
  // MOTIVATION — dark, bold, glow, geometry. No flowers.
  // =========================================================================
  BackgroundPreset(
    BackgroundConfig(
      id: 'motiv_obsidian_ember',
      category: 'motivation',
      gradient: const [Color(0xFF0F0F12), Color(0xFF2A1A12)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFF0B0B0E),
          _pt(0.9, 0.1, 0xFF1C1A1E),
          _pt(0.2, 0.9, 0xFF141214),
          _pt(0.95, 0.9, 0xFF3A1E12),
        ], warp: 0.15, seed: 14.0),
        const ShapeLayer(
            kind: ShapeKind.diagonalBand,
            color: Color(0x2EFF6B2C),
            center: Offset(0.5, 0.5),
            size: 0.12,
            rotation: -0.5),
        Layers.glow(
            position: const Offset(0.85, 0.15),
            color: const Color(0xFFFF6B2C),
            radius: 0.35,
            intensity: 0.7),
        Layers.grain(strength: 0.2, seed: 14),
      ],
      textColor: _white,
      mutedTextColor: const Color(0xFFB8B2AE),
      accentColor: const Color(0xFFFF6B2C),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'motiv_electric_blue',
      category: 'motivation',
      gradient: const [Color(0xFF0A0F2C), Color(0xFF112A6B)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.0, 0xFF070B22),
          _pt(0.9, 0.3, 0xFF0F1F55),
          _pt(0.2, 0.9, 0xFF14307A),
          _pt(0.9, 1.0, 0xFF0A0F2C),
        ], warp: 0.2, seed: 15.0),
        Layers.pinstripes(color: _white, strength: 0.06),
        Layers.glow(
            position: const Offset(0.2, 0.9),
            color: const Color(0xFF3B82F6),
            radius: 0.4,
            intensity: 0.6),
        const ShapeLayer(
            kind: ShapeKind.cornerBrackets,
            color: Color(0xCC60A5FA),
            size: 0.05,
            stroke: 0.004),
      ],
      textColor: _white,
      mutedTextColor: const Color(0xFFA9BDE8),
      accentColor: const Color(0xFF60A5FA),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'motiv_gold_black',
      category: 'motivation',
      gradient: const [Color(0xFF111111), Color(0xFF222222)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFF0D0D0D),
          _pt(0.9, 0.1, 0xFF1E1E1E),
          _pt(0.1, 0.9, 0xFF262626),
          _pt(0.9, 0.9, 0xFF2A2415),
        ], warp: 0.1, seed: 16.0),
        Layers.halftone(color: const Color(0xFFD4AF37), strength: 0.35),
        const ShapeLayer(
            kind: ShapeKind.ring,
            color: Color(0xCCD4AF37),
            center: Offset(0.5, 0.42),
            size: 0.3,
            stroke: 0.003),
        const VignetteLayer(strength: 0.35, inner: 0.6),
      ],
      textColor: const Color(0xFFF5F5F5),
      mutedTextColor: const Color(0xFFB3B3B3),
      accentColor: const Color(0xFFD4AF37),
    ),
    motif: TemplateMotif.geometric,
    motifColor: const Color(0x33D4AF37),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'motiv_crimson_focus',
      category: 'motivation',
      gradient: const [Color(0xFF1C0B0B), Color(0xFF4A0F1F)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.5, 0.0, 0xFF140808),
          _pt(0.1, 0.6, 0xFF2E0C14),
          _pt(0.9, 0.6, 0xFF3A0F1A),
          _pt(0.5, 1.0, 0xFF5A1426),
        ], warp: 0.2, seed: 17.0),
        Layers.rays(
            origin: const Offset(0.5, 1.05),
            color: const Color(0xFFFF4D6D),
            intensity: 0.45,
            count: 10,
            falloff: 2.4,
            seed: 3.3),
        Layers.grain(strength: 0.18, seed: 17),
      ],
      textColor: _white,
      mutedTextColor: const Color(0xFFE0B3BD),
      accentColor: const Color(0xFFFF4D6D),
    ),
    motif: TemplateMotif.mountain,
    motifColor: const Color(0x66FF4D6D),
  ),

  // =========================================================================
  // SUCCESS — champagne, gold, emerald; celebratory but restrained
  // =========================================================================
  BackgroundPreset(
    BackgroundConfig(
      id: 'success_champagne',
      category: 'success',
      gradient: const [Color(0xFFFDF6E3), Color(0xFFEAD9B0)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFFFFFBF0),
          _pt(0.9, 0.2, 0xFFF6E7C8),
          _pt(0.2, 0.9, 0xFFEAD9B0),
          _pt(0.9, 0.9, 0xFFF9EBCF),
        ], warp: 0.2, seed: 18.0, softness: 1.8),
        Layers.bokeh(
            color: const Color(0xFFFFD970),
            density: 0.4,
            size: 0.3,
            softness: 0.3,
            yBias: 0.5,
            seed: 18,
            blend: LayerBlend.srcOver),
        Layers.paper(strength: 0.25, seed: 18),
      ],
      textColor: const Color(0xFF4A3714),
      mutedTextColor: const Color(0xFF8A6E3A),
      accentColor: const Color(0xFFB8860B),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'success_midnight_gold',
      category: 'success',
      gradient: const [Color(0xFF0B1220), Color(0xFF1C2A44)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.5, 0.0, 0xFF0A101C),
          _pt(0.1, 0.5, 0xFF16213A),
          _pt(0.9, 0.5, 0xFF1C2A44),
          _pt(0.5, 1.0, 0xFF0E1526),
        ], warp: 0.15, seed: 19.0),
        Layers.glow(
            position: const Offset(0.5, 0.0),
            color: const Color(0xFFF5D06F),
            radius: 0.5,
            intensity: 0.6),
        Layers.dotGrid(color: const Color(0xFFF5D06F), strength: 0.18),
        const VignetteLayer(strength: 0.35, inner: 0.6),
      ],
      textColor: const Color(0xFFFFF8E7),
      mutedTextColor: const Color(0xFFC9C2AE),
      accentColor: const Color(0xFFF5D06F),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'success_emerald',
      category: 'success',
      gradient: const [Color(0xFF063B2E), Color(0xFF0E6B52)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFF042A21),
          _pt(0.9, 0.2, 0xFF0A5A44),
          _pt(0.2, 0.9, 0xFF0E6B52),
          _pt(0.9, 0.9, 0xFF063B2E),
        ], warp: 0.2, seed: 20.0),
        Layers.rays(
            origin: const Offset(0.1, 0.0),
            color: const Color(0xFFB9F5D8),
            intensity: 0.4,
            count: 12,
            falloff: 2.2,
            seed: 4.1),
        Layers.pinstripes(color: _white, strength: 0.05),
      ],
      textColor: const Color(0xFFECFDF5),
      mutedTextColor: const Color(0xFFA7D7C5),
      accentColor: const Color(0xFFF5D06F),
    ),
    motif: TemplateMotif.growth,
    motifColor: const Color(0x66F5D06F),
  ),

  // =========================================================================
  // BUSINESS — premium, minimal, professional; dark + gold hairlines
  // =========================================================================
  BackgroundPreset(
    BackgroundConfig(
      id: 'biz_slate',
      category: 'business',
      gradient: const [Color(0xFF1F2937), Color(0xFF0F172A)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFF243041),
          _pt(0.9, 0.1, 0xFF1A2433),
          _pt(0.1, 0.9, 0xFF111827),
          _pt(0.9, 0.9, 0xFF0F172A),
        ], warp: 0.1, seed: 21.0),
        const ShapeLayer(
            kind: ShapeKind.insetFrame,
            color: Color(0xCCD4AF37),
            size: 0.045,
            stroke: 0.0025),
        Layers.grain(strength: 0.12, seed: 21),
      ],
      textColor: const Color(0xFFF9FAFB),
      mutedTextColor: const Color(0xFFCBD5E1),
      accentColor: const Color(0xFFD4AF37),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'biz_navy_gold_rule',
      category: 'business',
      gradient: const [Color(0xFF0B1F3A), Color(0xFF123A66)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.5, 0.0, 0xFF081A30),
          _pt(0.1, 0.5, 0xFF0F2C50),
          _pt(0.9, 0.5, 0xFF123A66),
          _pt(0.5, 1.0, 0xFF0B1F3A),
        ], warp: 0.15, seed: 22.0),
        Layers.halftone(color: _white, strength: 0.08),
        const ShapeLayer(
            kind: ShapeKind.diagonalBand,
            color: Color(0xE6D4AF37),
            center: Offset(0.5, 0.86),
            size: 0.005,
            rotation: -0.35),
      ],
      textColor: _white,
      mutedTextColor: const Color(0xFFB7C6DC),
      accentColor: const Color(0xFFD4AF37),
    ),
    motif: TemplateMotif.skyline,
    motifColor: const Color(0x40D4AF37),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'biz_ivory_clean',
      category: 'business',
      gradient: const [Color(0xFFFAFAF7), Color(0xFFECEAE2)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFFFFFFFF),
          _pt(0.9, 0.1, 0xFFF6F5F0),
          _pt(0.1, 0.9, 0xFFECEAE2),
          _pt(0.9, 0.9, 0xFFF3F1EA),
        ], warp: 0.1, seed: 23.0, softness: 1.6),
        Layers.paper(strength: 0.25, seed: 23),
        const ShapeLayer(
            kind: ShapeKind.horizontalRule,
            color: Color(0xFF111827),
            center: Offset(0.5, 0.84),
            size: 0.12,
            stroke: 0.002),
      ],
      textColor: const Color(0xFF111827),
      mutedTextColor: const Color(0xFF6B7280),
      accentColor: const Color(0xFFB8860B),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'biz_charcoal_mesh',
      category: 'business',
      gradient: const [Color(0xFF121212), Color(0xFF2B2B2B)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFF161616),
          _pt(0.9, 0.2, 0xFF2E2E2E),
          _pt(0.2, 0.9, 0xFF262320),
          _pt(0.9, 0.9, 0xFF0F0F0F),
        ], warp: 0.2, seed: 24.0),
        Layers.pinstripes(color: _white, strength: 0.05),
        Layers.glow(
            position: const Offset(0.9, 0.95),
            color: const Color(0xFF94A3B8),
            radius: 0.35,
            intensity: 0.35),
      ],
      textColor: _white,
      mutedTextColor: const Color(0xFFB0B0B0),
      accentColor: const Color(0xFFD4AF37),
    ),
  ),

  // =========================================================================
  // BIRTHDAY — festive confetti bokeh, pastel and midnight party
  // =========================================================================
  BackgroundPreset(
    BackgroundConfig(
      id: 'bday_pastel_confetti',
      category: 'birthday',
      gradient: const [Color(0xFFFFE6F0), Color(0xFFE6F0FF)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFFFFD9E8),
          _pt(0.9, 0.1, 0xFFE9DBFF),
          _pt(0.1, 0.9, 0xFFD9F5EC),
          _pt(0.9, 0.9, 0xFFFFF5D6),
        ], warp: 0.3, seed: 25.0, softness: 1.8),
        Layers.bokeh(
            color: const Color(0xFFFF7AB6),
            density: 0.45,
            size: 0.18,
            softness: 0.0,
            seed: 25,
            blend: LayerBlend.srcOver),
        Layers.bokeh(
            color: const Color(0xFF7AB6FF),
            density: 0.35,
            size: 0.14,
            softness: 0.0,
            seed: 29,
            blend: LayerBlend.srcOver),
        Layers.paper(strength: 0.15, seed: 25),
      ],
      textColor: const Color(0xFF5B2A4A),
      mutedTextColor: const Color(0xFF8E5B7C),
      accentColor: const Color(0xFFFF4F9A),
    ),
    motif: TemplateMotif.balloons,
    motifColor: const Color(0x80FF4F9A),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'bday_midnight_party',
      category: 'birthday',
      gradient: const [Color(0xFF1B1035), Color(0xFF3A1C6B)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFF150C2A),
          _pt(0.9, 0.2, 0xFF2D1757),
          _pt(0.2, 0.9, 0xFF3A1C6B),
          _pt(0.9, 0.9, 0xFF1B1035),
        ], warp: 0.25, seed: 26.0),
        Layers.bokeh(
            color: const Color(0xFFFFD166),
            density: 0.5,
            size: 0.25,
            softness: 0.4,
            seed: 26),
        Layers.bokeh(
            color: const Color(0xFFFF66B3),
            density: 0.3,
            size: 0.3,
            softness: 0.5,
            seed: 33),
        const VignetteLayer(strength: 0.35, inner: 0.6),
      ],
      textColor: _white,
      mutedTextColor: const Color(0xFFD7C9F0),
      accentColor: const Color(0xFFFFD166),
    ),
    motif: TemplateMotif.confetti,
    motifColor: const Color(0x99FFD166),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'bday_peach_cream',
      category: 'birthday',
      gradient: const [Color(0xFFFFF1E6), Color(0xFFFFD6C2)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.5, 0.0, 0xFFFFF6EE),
          _pt(0.1, 0.5, 0xFFFFE4D1),
          _pt(0.9, 0.5, 0xFFFFD6C2),
          _pt(0.5, 1.0, 0xFFFFC2A8),
        ], warp: 0.2, seed: 27.0, softness: 1.8),
        Layers.waves(
            color: const Color(0xFFFF9F80),
            baseY: 0.74,
            amplitude: 0.04,
            frequency: 1.1,
            alpha: 0.2,
            seed: 2.7),
        Layers.dotGrid(
            color: const Color(0xFFFF9F80), strength: 0.25, scale: 0.8),
      ],
      textColor: const Color(0xFF7A2E1F),
      mutedTextColor: const Color(0xFFA85A48),
      accentColor: const Color(0xFFE8613C),
    ),
    motif: TemplateMotif.cake,
    motifColor: const Color(0x80E8613C),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'bday_teal_gold',
      category: 'birthday',
      gradient: const [Color(0xFF0F766E), Color(0xFF134E4A)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFF0D6B63),
          _pt(0.9, 0.1, 0xFF157F75),
          _pt(0.1, 0.9, 0xFF134E4A),
          _pt(0.9, 0.9, 0xFF0B3F3B),
        ], warp: 0.2, seed: 28.0),
        Layers.glow(
            position: const Offset(0.5, 0.1),
            color: const Color(0xFFFFE08A),
            radius: 0.4,
            intensity: 0.55),
        Layers.bokeh(
            color: const Color(0xFFFFE08A),
            density: 0.4,
            size: 0.15,
            softness: 0.1,
            seed: 28),
      ],
      textColor: const Color(0xFFFFFBEB),
      mutedTextColor: const Color(0xFFBFE3DC),
      accentColor: const Color(0xFFFFE08A),
    ),
  ),

  // =========================================================================
  // FESTIVAL — every festival its own scene
  // =========================================================================
  BackgroundPreset(
    BackgroundConfig(
      id: 'fest_diwali_lights',
      category: 'festival',
      gradient: const [Color(0xFF2A0A3C), Color(0xFF5A1B2E), Color(0xFF1A0A2C)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.5, 0.0, 0xFF1E0830),
          _pt(0.1, 0.5, 0xFF3C1040),
          _pt(0.9, 0.5, 0xFF5A1B2E),
          _pt(0.5, 1.0, 0xFF2A0A3C),
        ], warp: 0.2, seed: 30.0),
        Layers.glow(
            position: const Offset(0.5, 0.92),
            color: const Color(0xFFFFB347),
            radius: 0.42,
            intensity: 0.8),
        Layers.bokeh(
            color: const Color(0xFFFFD27F),
            density: 0.6,
            size: 0.25,
            softness: 0.3,
            yBias: -0.6,
            seed: 30),
        Layers.grain(strength: 0.12, seed: 30),
      ],
      textColor: const Color(0xFFFFE9B0),
      mutedTextColor: const Color(0xFFE6C9A0),
      accentColor: const Color(0xFFFFB347),
    ),
    motif: TemplateMotif.diya,
    motifColor: const Color(0xCCFFB347),
    tag: 'diwali',
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'fest_holi_colors',
      category: 'festival',
      gradient: const [Color(0xFFFFF7E6), Color(0xFFFFE9F3)],
      layers: [
        Layers.mesh(points: [
          _pt(0.15, 0.15, 0xFFFF4FA3),
          _pt(0.85, 0.1, 0xFFFFD23F),
          _pt(0.2, 0.9, 0xFF3FD2FF),
          _pt(0.85, 0.85, 0xFF9CE24A),
        ], warp: 0.8, seed: 31.0, softness: 3.0),
        Layers.bokeh(
            color: _white,
            density: 0.3,
            size: 0.3,
            softness: 0.8,
            seed: 31,
            blend: LayerBlend.srcOver),
        Layers.grain(strength: 0.15, seed: 31),
      ],
      textColor: const Color(0xFF3A1140),
      mutedTextColor: const Color(0xFF5E3A66),
      accentColor: const Color(0xFFFF2E88),
    ),
    motif: TemplateMotif.holi,
    motifColor: const Color(0xB3FF2E88),
    tag: 'holi',
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'fest_rakhi_tradition',
      category: 'festival',
      gradient: const [Color(0xFFFFF3D6), Color(0xFFF6C977)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.5, 0.0, 0xFFFFF8E6),
          _pt(0.1, 0.5, 0xFFFBD9A6),
          _pt(0.9, 0.5, 0xFFF7C78B),
          _pt(0.5, 1.0, 0xFFE9A95A),
        ], warp: 0.15, seed: 32.0, softness: 1.8),
        Layers.paper(strength: 0.35, seed: 32),
        const ShapeLayer(
            kind: ShapeKind.ring,
            color: Color(0xFFA3302A),
            center: Offset(0.5, 0.5),
            size: 0.36,
            stroke: 0.004),
        const ShapeLayer(
            kind: ShapeKind.ring,
            color: Color(0x99A3302A),
            center: Offset(0.5, 0.5),
            size: 0.40,
            stroke: 0.0015),
        const ShapeLayer(
            kind: ShapeKind.dotRow,
            color: Color(0xFFA3302A),
            center: Offset(0.5, 0.09),
            size: 0.12,
            stroke: 0.003),
      ],
      textColor: const Color(0xFF7A1E1A),
      mutedTextColor: const Color(0xFF9A4A3A),
      accentColor: const Color(0xFFA3302A),
    ),
    motif: TemplateMotif.rakhi,
    motifColor: const Color(0xCCA3302A),
    tag: 'rakhi',
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'fest_independence',
      category: 'festival',
      gradient: const [Color(0xFFFFFFFF), Color(0xFFF4F4F4)],
      layers: [
        Layers.waves(
            color: const Color(0xFFFF9933),
            baseY: 0.18,
            amplitude: 0.025,
            frequency: 0.8,
            alpha: 0.33,
            seed: 1.0,
            fromTop: true),
        Layers.waves(
            color: const Color(0xFF138808),
            baseY: 0.82,
            amplitude: 0.025,
            frequency: 0.8,
            alpha: 0.33,
            seed: 2.0),
        const ShapeLayer(
            kind: ShapeKind.ring,
            color: Color(0xFF000080),
            center: Offset(0.5, 0.5),
            size: 0.16,
            stroke: 0.004),
        Layers.grain(strength: 0.08, seed: 33),
      ],
      textColor: const Color(0xFF0B1C4F),
      mutedTextColor: const Color(0xFF4A5A80),
      accentColor: const Color(0xFFFF9933),
    ),
    tag: 'independence',
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'fest_ganesh',
      category: 'festival',
      gradient: const [Color(0xFFFFEDD5), Color(0xFFFDBA74)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.5, 0.0, 0xFFFFF4E6),
          _pt(0.1, 0.5, 0xFFFFD6A8),
          _pt(0.9, 0.5, 0xFFFDBA74),
          _pt(0.5, 1.0, 0xFFF08A3C),
        ], warp: 0.2, seed: 34.0),
        Layers.rays(
            origin: const Offset(0.5, 0.22),
            color: const Color(0xFFFFF7E0),
            intensity: 0.55,
            count: 24,
            falloff: 2.2,
            seed: 3.4),
        Layers.bokeh(
            color: const Color(0xFFFFE08A),
            density: 0.3,
            size: 0.14,
            softness: 0.4,
            seed: 34),
      ],
      textColor: const Color(0xFF6B2A06),
      mutedTextColor: const Color(0xFF9A4F1A),
      accentColor: const Color(0xFFC2410C),
    ),
    motif: TemplateMotif.ganesh,
    motifColor: const Color(0xB3C2410C),
    tag: 'ganesh',
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'fest_eid_night',
      category: 'festival',
      gradient: const [Color(0xFF0A1F3A), Color(0xFF163B64)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.5, 0.0, 0xFF08182E),
          _pt(0.1, 0.5, 0xFF102E52),
          _pt(0.9, 0.5, 0xFF163B64),
          _pt(0.5, 1.0, 0xFF0A1F3A),
        ], warp: 0.15, seed: 35.0),
        Layers.glow(
            position: const Offset(0.72, 0.16),
            color: const Color(0xFFFFF3C4),
            radius: 0.2,
            intensity: 0.6),
        Layers.bokeh(
            color: _white,
            density: 0.45,
            size: 0.1,
            softness: 0.0,
            yBias: 0.7,
            seed: 35),
      ],
      textColor: const Color(0xFFFFF8E7),
      mutedTextColor: const Color(0xFFBFD0E6),
      accentColor: const Color(0xFFF5D06F),
    ),
    motif: TemplateMotif.eid,
    motifColor: const Color(0xCCF5D06F),
    tag: 'eid',
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'fest_navratri',
      category: 'festival',
      gradient: const [Color(0xFF3B0764), Color(0xFFBE185D), Color(0xFFF59E0B)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.05, 0xFF3B0764),
          _pt(0.9, 0.2, 0xFF7E22CE),
          _pt(0.2, 0.8, 0xFFBE185D),
          _pt(0.9, 0.95, 0xFFF59E0B),
        ], warp: 0.35, seed: 36.0),
        Layers.bokeh(
            color: _white,
            density: 0.35,
            size: 0.12,
            softness: 0.0,
            seed: 36),
        Layers.dotGrid(color: _white, strength: 0.12),
      ],
      textColor: _white,
      mutedTextColor: const Color(0xFFF5D7E8),
      accentColor: const Color(0xFFFDE68A),
    ),
    motif: TemplateMotif.navratri,
    motifColor: const Color(0xCCFDE68A),
    tag: 'navratri',
  ),

  // =========================================================================
  // LOVE — romantic, soft, bokeh, warm. No cartoon.
  // =========================================================================
  BackgroundPreset(
    BackgroundConfig(
      id: 'love_rose_bokeh',
      category: 'love',
      gradient: const [Color(0xFFFFE4EC), Color(0xFFFFB6C1), Color(0xFFFF8FA3)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFFFFE9F0),
          _pt(0.9, 0.2, 0xFFFFC4D1),
          _pt(0.2, 0.9, 0xFFFF9FB2),
          _pt(0.9, 0.9, 0xFFFFD9C2),
        ], warp: 0.45, seed: 37.0, softness: 1.8),
        Layers.bokeh(
            color: _white,
            density: 0.5,
            size: 0.4,
            softness: 0.55,
            seed: 37,
            blend: LayerBlend.srcOver),
        Layers.grain(strength: 0.1, seed: 37),
      ],
      textColor: const Color(0xFF6D1F3A),
      mutedTextColor: const Color(0xFF9A4F66),
      accentColor: const Color(0xFFE0245E),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'love_wine_night',
      category: 'love',
      gradient: const [Color(0xFF2A0A14), Color(0xFF5A1230)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFF20080F),
          _pt(0.9, 0.2, 0xFF4A1028),
          _pt(0.2, 0.9, 0xFF5A1230),
          _pt(0.9, 0.9, 0xFF2A0A14),
        ], warp: 0.3, seed: 38.0),
        Layers.glow(
            position: const Offset(0.5, 0.5),
            color: const Color(0xFFFF9EBB),
            radius: 0.5,
            intensity: 0.3),
        Layers.bokeh(
            color: const Color(0xFFFF6B9D),
            density: 0.45,
            size: 0.35,
            softness: 0.5,
            seed: 38),
        const VignetteLayer(strength: 0.4, inner: 0.55),
      ],
      textColor: const Color(0xFFFFE4EC),
      mutedTextColor: const Color(0xFFE6A9BD),
      accentColor: const Color(0xFFFF6B9D),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'love_sunset_hearts',
      category: 'love',
      gradient: const [Color(0xFFFFD1A1), Color(0xFFFF8C8C), Color(0xFFC85C9C)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.5, 0.0, 0xFFFFDDB0),
          _pt(0.1, 0.5, 0xFFFF9E8E),
          _pt(0.9, 0.5, 0xFFF07A96),
          _pt(0.5, 1.0, 0xFFB44E92),
        ], warp: 0.25, seed: 39.0),
        Layers.rays(
            origin: const Offset(0.5, 1.02),
            color: const Color(0xFFFFE7C2),
            intensity: 0.45,
            count: 12,
            falloff: 2.4,
            seed: 3.9),
        Layers.grain(strength: 0.1, seed: 39),
      ],
      textColor: const Color(0xFF4A1030),
      mutedTextColor: const Color(0xFF7A3A5A),
      accentColor: const Color(0xFFFFE7C2),
    ),
    motif: TemplateMotif.hearts,
    motifColor: const Color(0x40FFFFFF),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'love_soft_lavender',
      category: 'love',
      gradient: const [Color(0xFFEDE9FE), Color(0xFFFBCFE8)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFFF3F0FF),
          _pt(0.9, 0.1, 0xFFE4DAFF),
          _pt(0.1, 0.9, 0xFFFBCFE8),
          _pt(0.9, 0.9, 0xFFFFE4F1),
        ], warp: 0.3, seed: 40.0, softness: 1.8),
        Layers.waves(
            color: const Color(0xFFC4B5FD),
            baseY: 0.76,
            amplitude: 0.035,
            frequency: 1.0,
            alpha: 0.22,
            seed: 4.0),
        Layers.paper(strength: 0.2, seed: 40),
      ],
      textColor: const Color(0xFF4C1D95),
      mutedTextColor: const Color(0xFF7C5AB8),
      accentColor: const Color(0xFFDB2777),
    ),
    motif: TemplateMotif.roses,
    motifColor: const Color(0x66DB2777),
  ),

  // =========================================================================
  // HEARTBREAK — muted, grainy, faded, moody blue-gray
  // =========================================================================
  BackgroundPreset(
    BackgroundConfig(
      id: 'hb_rain_gray',
      category: 'heartbreak',
      gradient: const [Color(0xFF2B2F3A), Color(0xFF4B5563)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.5, 0.0, 0xFF262A34),
          _pt(0.1, 0.5, 0xFF3A4150),
          _pt(0.9, 0.5, 0xFF4B5563),
          _pt(0.5, 1.0, 0xFF2B2F3A),
        ], warp: 0.2, seed: 41.0),
        Layers.grain(strength: 0.3, scale: 1.4, seed: 41),
        const VignetteLayer(strength: 0.5, inner: 0.45),
      ],
      textColor: const Color(0xFFE5E7EB),
      mutedTextColor: const Color(0xFF9CA3AF),
      accentColor: const Color(0xFF93C5FD),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'hb_faded_ink',
      category: 'heartbreak',
      gradient: const [Color(0xFFF3F4F6), Color(0xFFD1D5DB)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFFF9FAFB),
          _pt(0.9, 0.1, 0xFFE5E7EB),
          _pt(0.1, 0.9, 0xFFD1D5DB),
          _pt(0.9, 0.9, 0xFFE9EBEF),
        ], warp: 0.15, seed: 42.0, softness: 1.6),
        Layers.paper(strength: 0.4, seed: 42),
        Layers.halftone(color: const Color(0xFF374151), strength: 0.18),
      ],
      textColor: const Color(0xFF1F2937),
      mutedTextColor: const Color(0xFF6B7280),
      accentColor: const Color(0xFF374151),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'hb_midnight_blue',
      category: 'heartbreak',
      gradient: const [Color(0xFF0B1324), Color(0xFF1E293B)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.5, 0.0, 0xFF0A1020),
          _pt(0.1, 0.5, 0xFF151E33),
          _pt(0.9, 0.5, 0xFF1E293B),
          _pt(0.5, 1.0, 0xFF0B1324),
        ], warp: 0.15, seed: 43.0),
        Layers.glow(
            position: const Offset(0.5, 0.1),
            color: const Color(0xFF64748B),
            radius: 0.5,
            intensity: 0.35),
        Layers.waves(
            color: const Color(0xFF020617),
            baseY: 0.7,
            amplitude: 0.02,
            frequency: 1.3,
            alpha: 0.3,
            seed: 4.3),
        Layers.grain(strength: 0.18, seed: 43),
      ],
      textColor: const Color(0xFFCBD5E1),
      mutedTextColor: const Color(0xFF7F8CA3),
      accentColor: const Color(0xFF94A3B8),
    ),
  ),

  // =========================================================================
  // FRIENDSHIP — bright, warm, playful, clean
  // =========================================================================
  BackgroundPreset(
    BackgroundConfig(
      id: 'friend_sunny',
      category: 'friendship',
      gradient: const [Color(0xFFFFF4C2), Color(0xFFFFD56A)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFFFFF8D6),
          _pt(0.9, 0.1, 0xFFFFE28A),
          _pt(0.1, 0.9, 0xFFFFD56A),
          _pt(0.9, 0.9, 0xFFFFC8A6),
        ], warp: 0.3, seed: 44.0, softness: 1.8),
        Layers.bokeh(
            color: _white,
            density: 0.35,
            size: 0.3,
            softness: 0.2,
            seed: 44,
            blend: LayerBlend.srcOver),
        Layers.grain(strength: 0.1, seed: 44),
      ],
      textColor: const Color(0xFF4A3000),
      mutedTextColor: const Color(0xFF7A5A20),
      accentColor: const Color(0xFFF97316),
    ),
    motif: TemplateMotif.sun,
    motifColor: const Color(0x80F97316),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'friend_teal_coral',
      category: 'friendship',
      gradient: const [Color(0xFFCCFBF1), Color(0xFFFDE68A)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFF99F6E4),
          _pt(0.9, 0.1, 0xFFCCFBF1),
          _pt(0.1, 0.9, 0xFFFDE68A),
          _pt(0.9, 0.9, 0xFFFDBA74),
        ], warp: 0.5, seed: 45.0, softness: 2.0),
        Layers.waves(
            color: const Color(0xFF14B8A6),
            baseY: 0.74,
            amplitude: 0.04,
            frequency: 1.2,
            alpha: 0.2,
            seed: 4.5),
      ],
      textColor: const Color(0xFF134E4A),
      mutedTextColor: const Color(0xFF3F7F78),
      accentColor: const Color(0xFFF97316),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'friend_polaroid_cream',
      category: 'friendship',
      gradient: const [Color(0xFFFAF5EB), Color(0xFFEADDC5)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFFFFFBF2),
          _pt(0.9, 0.1, 0xFFF4ECDC),
          _pt(0.1, 0.9, 0xFFEADDC5),
          _pt(0.9, 0.9, 0xFFF0E4CE),
        ], warp: 0.1, seed: 46.0, softness: 1.6),
        Layers.paper(strength: 0.4, seed: 46),
        const ShapeLayer(
            kind: ShapeKind.cornerBrackets,
            color: Color(0xFF6B4F2A),
            size: 0.05,
            stroke: 0.003),
      ],
      textColor: const Color(0xFF3F2E14),
      mutedTextColor: const Color(0xFF7A6646),
      accentColor: const Color(0xFF6B4F2A),
    ),
  ),

  // =========================================================================
  // WISHES — congratulations, anniversaries, thank-you; elegant
  // =========================================================================
  BackgroundPreset(
    BackgroundConfig(
      id: 'wish_gold_sparkle',
      category: 'wishes',
      gradient: const [Color(0xFF1A1030), Color(0xFF3A2460)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFF140C26),
          _pt(0.9, 0.2, 0xFF2E1C50),
          _pt(0.2, 0.9, 0xFF3A2460),
          _pt(0.9, 0.9, 0xFF1A1030),
        ], warp: 0.2, seed: 47.0),
        Layers.glow(
            position: const Offset(0.5, 0.0),
            color: const Color(0xFFFFE08A),
            radius: 0.45,
            intensity: 0.45),
        Layers.bokeh(
            color: const Color(0xFFFFE08A),
            density: 0.5,
            size: 0.2,
            softness: 0.1,
            seed: 47),
      ],
      textColor: const Color(0xFFFFF8E7),
      mutedTextColor: const Color(0xFFCFC3E6),
      accentColor: const Color(0xFFFFE08A),
    ),
    motif: TemplateMotif.sparkles,
    motifColor: const Color(0x99FFE08A),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'wish_blush_ivory',
      category: 'wishes',
      gradient: const [Color(0xFFFFF8F3), Color(0xFFF9E0D9)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFFFFFCF9),
          _pt(0.9, 0.1, 0xFFFBEDE7),
          _pt(0.1, 0.9, 0xFFF9E0D9),
          _pt(0.9, 0.9, 0xFFFCE9E2),
        ], warp: 0.1, seed: 48.0, softness: 1.6),
        Layers.paper(strength: 0.3, seed: 48),
        const ShapeLayer(
            kind: ShapeKind.ring,
            color: Color(0xCCC98B6E),
            center: Offset(0.5, 0.5),
            size: 0.42,
            stroke: 0.002),
      ],
      textColor: const Color(0xFF5C3A2E),
      mutedTextColor: const Color(0xFF9A7A6E),
      accentColor: const Color(0xFFC98B6E),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'wish_royal_blue',
      category: 'wishes',
      gradient: const [Color(0xFF0F2A6B), Color(0xFF2E4FA3)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.5, 0.0, 0xFF0C2158),
          _pt(0.1, 0.5, 0xFF1B3A86),
          _pt(0.9, 0.5, 0xFF2E4FA3),
          _pt(0.5, 1.0, 0xFF0F2A6B),
        ], warp: 0.15, seed: 49.0),
        Layers.rays(
            origin: const Offset(0.5, -0.05),
            color: const Color(0xFFBFD3FF),
            intensity: 0.45,
            count: 18,
            falloff: 2.0,
            seed: 4.9),
        Layers.pinstripes(color: _white, strength: 0.05),
      ],
      textColor: _white,
      mutedTextColor: const Color(0xFFBFD3FF),
      accentColor: const Color(0xFFFFD166),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'wish_mint_fresh',
      category: 'wishes',
      gradient: const [Color(0xFFE8FFF4), Color(0xFFB8F0D6)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFFF0FFF8),
          _pt(0.9, 0.1, 0xFFD6F8E8),
          _pt(0.1, 0.9, 0xFFB8F0D6),
          _pt(0.9, 0.9, 0xFFCFF5E2),
        ], warp: 0.2, seed: 50.0, softness: 1.8),
        Layers.bokeh(
            color: _white,
            density: 0.3,
            size: 0.2,
            softness: 0.1,
            seed: 50,
            blend: LayerBlend.srcOver),
        Layers.dotGrid(color: const Color(0xFF10B981), strength: 0.2),
      ],
      textColor: const Color(0xFF064E3B),
      mutedTextColor: const Color(0xFF3F8A72),
      accentColor: const Color(0xFF10B981),
    ),
  ),

  // =========================================================================
  // NATURE — mist, hills, sea, sand, dusk
  // =========================================================================
  BackgroundPreset(
    BackgroundConfig(
      id: 'nature_forest_mist',
      category: 'nature',
      gradient: const [Color(0xFFDCEFE3), Color(0xFF7FB899), Color(0xFF2F6B4F)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.5, 0.0, 0xFFE8F5EC),
          _pt(0.1, 0.5, 0xFFA7D1B6),
          _pt(0.9, 0.5, 0xFF7FB899),
          _pt(0.5, 1.0, 0xFF2F6B4F),
        ], warp: 0.25, seed: 51.0, softness: 1.8),
        Layers.waves(
            color: const Color(0xFF2F6B4F),
            baseY: 0.62,
            amplitude: 0.05,
            frequency: 0.9,
            alpha: 0.22,
            seed: 5.1),
        Layers.rays(
            origin: const Offset(0.3, 0.0),
            color: _white,
            intensity: 0.35,
            count: 10,
            falloff: 2.0,
            seed: 5.1),
        Layers.grain(strength: 0.1, seed: 51),
      ],
      textColor: const Color(0xFF0F3B2A),
      mutedTextColor: const Color(0xFF2F6B4F),
      accentColor: const Color(0xFFE8F5EC),
    ),
    motif: TemplateMotif.botanical,
    motifColor: const Color(0x662F6B4F),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'nature_ocean_calm',
      category: 'nature',
      gradient: const [Color(0xFFE0F2FE), Color(0xFF38BDF8), Color(0xFF0C4A6E)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.5, 0.0, 0xFFEAF6FF),
          _pt(0.1, 0.5, 0xFF7DD3FC),
          _pt(0.9, 0.5, 0xFF38BDF8),
          _pt(0.5, 1.0, 0xFF0C4A6E),
        ], warp: 0.2, seed: 52.0, softness: 1.8),
        Layers.glow(
            position: const Offset(0.5, 0.2),
            color: _white,
            radius: 0.3,
            intensity: 0.3),
        Layers.waves(
            color: const Color(0xFF0C4A6E),
            baseY: 0.7,
            amplitude: 0.035,
            frequency: 1.5,
            alpha: 0.25,
            seed: 5.2),
      ],
      textColor: const Color(0xFF082F49),
      mutedTextColor: const Color(0xFF0C4A6E),
      accentColor: const Color(0xFFEAF6FF),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'nature_earth_sand',
      category: 'nature',
      gradient: const [Color(0xFFF5EBDD), Color(0xFFD9BFA0)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.5, 0.0, 0xFFFAF3E8),
          _pt(0.1, 0.5, 0xFFEBD9C0),
          _pt(0.9, 0.5, 0xFFE2CBAC),
          _pt(0.5, 1.0, 0xFFD9BFA0),
        ], warp: 0.15, seed: 53.0, softness: 1.6),
        Layers.paper(strength: 0.4, seed: 53),
        ShapeLayer(
            kind: ShapeKind.halfDisc,
            color: const Color(0x66C98B5A),
            center: const Offset(0.5, 0.98),
            size: 0.75,
            rotation: math.pi),
      ],
      textColor: const Color(0xFF4A2E14),
      mutedTextColor: const Color(0xFF8A6A48),
      accentColor: const Color(0xFFC98B5A),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'nature_mountain_dusk',
      category: 'nature',
      gradient: const [Color(0xFF2B1B4F), Color(0xFFE36D6D), Color(0xFFF6B580)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.mesh(points: [
          _pt(0.5, 0.0, 0xFF221540),
          _pt(0.1, 0.45, 0xFF7A3F7A),
          _pt(0.9, 0.5, 0xFFE36D6D),
          _pt(0.5, 1.0, 0xFFF6B580),
        ], warp: 0.2, seed: 54.0, softness: 1.8),
        Layers.bokeh(
            color: _white,
            density: 0.35,
            size: 0.1,
            softness: 0.0,
            yBias: 0.8,
            seed: 54),
        Layers.waves(
            color: const Color(0xFF1B1033),
            baseY: 0.72,
            amplitude: 0.06,
            frequency: 0.7,
            alpha: 0.35,
            seed: 5.4),
      ],
      textColor: const Color(0xFFFFF5E6),
      mutedTextColor: const Color(0xFFE8C9C2),
      accentColor: const Color(0xFFF6B580),
    ),
  ),

  // =========================================================================
  // MINIMAL — white space, one quiet texture, one accent shape
  // =========================================================================
  BackgroundPreset(
    BackgroundConfig(
      id: 'min_paper_white',
      category: 'minimal',
      gradient: const [Color(0xFFFDFCF9), Color(0xFFF2EFE8)],
      layers: [
        Layers.paper(strength: 0.45, seed: 55),
        const ShapeLayer(
            kind: ShapeKind.horizontalRule,
            color: Color(0xFF111111),
            center: Offset(0.5, 0.62),
            size: 0.08,
            stroke: 0.0015),
      ],
      textColor: const Color(0xFF1A1A1A),
      mutedTextColor: const Color(0xFF777777),
      accentColor: const Color(0xFF111111),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'min_warm_gray',
      category: 'minimal',
      gradient: const [Color(0xFFEDEAE4), Color(0xFFDAD5CC)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFFF1EEE8),
          _pt(0.9, 0.1, 0xFFE4E0D8),
          _pt(0.1, 0.9, 0xFFDAD5CC),
          _pt(0.9, 0.9, 0xFFE8E3DA),
        ], warp: 0.1, seed: 56.0, softness: 1.6),
        Layers.grain(strength: 0.2, seed: 56),
        const ShapeLayer(
            kind: ShapeKind.ring,
            color: Color(0xFF8A8378),
            center: Offset(0.72, 0.3),
            size: 0.3,
            stroke: 0.002),
      ],
      textColor: const Color(0xFF2B2724),
      mutedTextColor: const Color(0xFF6F6962),
      accentColor: const Color(0xFF8A8378),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'min_black',
      category: 'minimal',
      gradient: const [Color(0xFF0D0D0D), Color(0xFF171717)],
      layers: [
        Layers.grain(strength: 0.25, seed: 57),
        const ShapeLayer(
            kind: ShapeKind.disc,
            color: Color(0x0FFFFFFF),
            center: Offset(0.5, 0.5),
            size: 0.35),
      ],
      textColor: const Color(0xFFF5F5F5),
      mutedTextColor: const Color(0xFFA3A3A3),
      accentColor: const Color(0xFFF5F5F5),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'min_sage',
      category: 'minimal',
      gradient: const [Color(0xFFE9EFE6), Color(0xFFCFDBC8)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFFEEF3EB),
          _pt(0.9, 0.1, 0xFFE0E8DC),
          _pt(0.1, 0.9, 0xFFCFDBC8),
          _pt(0.9, 0.9, 0xFFDCE5D6),
        ], warp: 0.1, seed: 58.0, softness: 1.6),
        Layers.dotGrid(
            color: const Color(0xFF5B6B55), strength: 0.22, scale: 0.7),
      ],
      textColor: const Color(0xFF2F3A2B),
      mutedTextColor: const Color(0xFF6B7A66),
      accentColor: const Color(0xFF5B6B55),
    ),
  ),

  // =========================================================================
  // PREMIUM DARK — deep blacks, glass gradients, aurora, gold / cyan
  // =========================================================================
  BackgroundPreset(
    BackgroundConfig(
      id: 'pd_aurora_black',
      category: 'premium_dark',
      gradient: const [Color(0xFF050507), Color(0xFF0B0F1A)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      layers: [
        Layers.aurora(
            color1: const Color(0xFF22D3EE),
            color2: const Color(0xFFA855F7),
            intensity: 0.45,
            time: 5.2),
        Layers.grain(strength: 0.18, seed: 59),
        const VignetteLayer(strength: 0.3, inner: 0.6),
      ],
      textColor: _white,
      mutedTextColor: const Color(0xFFA5B4C8),
      accentColor: const Color(0xFF22D3EE),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'pd_gold_mesh',
      category: 'premium_dark',
      gradient: const [Color(0xFF0A0A0A), Color(0xFF1A1410)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFF080808),
          _pt(0.9, 0.1, 0xFF161210),
          _pt(0.1, 0.9, 0xFF1A1410),
          _pt(0.9, 0.9, 0xFF2A2012),
        ], warp: 0.2, seed: 60.0),
        Layers.glow(
            position: const Offset(0.8, 0.85),
            color: const Color(0xFFD4AF37),
            radius: 0.45,
            intensity: 0.45),
        Layers.pinstripes(color: const Color(0xFFD4AF37), strength: 0.07),
      ],
      textColor: const Color(0xFFFAF3E0),
      mutedTextColor: const Color(0xFFBFB08A),
      accentColor: const Color(0xFFD4AF37),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'pd_glass_blue',
      category: 'premium_dark',
      gradient: const [Color(0xFF0B1020), Color(0xFF101A3A)],
      layers: [
        Layers.mesh(points: [
          _pt(0.1, 0.1, 0xFF0A0F22),
          _pt(0.9, 0.1, 0xFF0F1A3A),
          _pt(0.1, 0.9, 0xFF101A3A),
          _pt(0.9, 0.9, 0xFF070A18),
        ], warp: 0.25, seed: 61.0),
        Layers.glow(
            position: const Offset(0.25, 0.2),
            color: const Color(0xFF3B82F6),
            radius: 0.4,
            intensity: 0.55),
        Layers.glow(
            position: const Offset(0.8, 0.8),
            color: const Color(0xFF8B5CF6),
            radius: 0.4,
            intensity: 0.45),
        Layers.halftone(color: _white, strength: 0.06),
      ],
      textColor: const Color(0xFFEEF2FF),
      mutedTextColor: const Color(0xFFA9B4E0),
      accentColor: const Color(0xFF60A5FA),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'pd_carbon',
      category: 'premium_dark',
      gradient: const [Color(0xFF111111), Color(0xFF1C1C1C)],
      layers: [
        Layers.pinstripes(color: _white, strength: 0.08, scale: 1.6),
        const ShapeLayer(
            kind: ShapeKind.diagonalBand,
            color: Color(0x0AFFFFFF),
            center: Offset(0.5, 0.5),
            size: 0.35,
            rotation: -0.6),
        const ShapeLayer(
            kind: ShapeKind.cornerBrackets,
            color: Color(0xFF9CA3AF),
            size: 0.05,
            stroke: 0.003),
      ],
      textColor: const Color(0xFFF3F4F6),
      mutedTextColor: const Color(0xFF9CA3AF),
      accentColor: const Color(0xFFF59E0B),
    ),
  ),
  BackgroundPreset(
    BackgroundConfig(
      id: 'pd_flow',
      category: 'premium_dark',
      gradient: const [Color(0xFF0F172A), Color(0xFF312E81)],
      layers: [
        Layers.flowingWaves(
            color1: const Color(0xFF0F172A),
            color2: const Color(0xFF312E81),
            amplitude: 0.35,
            frequency: 1.6,
            time: 1.9),
        Layers.grain(strength: 0.15, seed: 63),
      ],
      textColor: const Color(0xFFE0E7FF),
      mutedTextColor: const Color(0xFFA5B4FC),
      accentColor: const Color(0xFFA5B4FC),
    ),
  ),
];

final Map<String, BackgroundPreset> _byId = {
  for (final p in kBackgroundPresets) p.id: p,
};

final Map<String, List<BackgroundPreset>> _byCategory = () {
  final m = <String, List<BackgroundPreset>>{};
  for (final p in kBackgroundPresets) {
    m.putIfAbsent(p.category, () => []).add(p);
  }
  return m;
}();

BackgroundPreset? backgroundPresetById(String id) => _byId[id];

/// Every preset designed for [category], in authoring order.
List<BackgroundPreset> backgroundPresetsForCategory(String category) =>
    _byCategory[category] ?? const [];

/// Maps the app's older category names (used by the free editor's Quotes and
/// Background sheets) onto studio categories, so the Background sheet can
/// surface matching designer backgrounds for whatever the editor was opened
/// with. Unknown / empty → a cross-section of everything.
List<BackgroundPreset> backgroundPresetsForLegacyCategory(String? legacy) {
  final id = studioCategoryForTheme(legacy);
  if (id != null) return backgroundPresetsForCategory(id);
  // One from each category — a varied first row for the general case.
  return [
    for (final list in _byCategory.values)
      if (list.isNotEmpty) list.first,
  ];
}
