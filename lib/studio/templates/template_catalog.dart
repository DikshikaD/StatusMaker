import 'package:flutter/material.dart';

import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/fixed_templates.dart';
import 'package:status_maker/studio/background/background_presets.dart';
import 'package:status_maker/studio/models/language_model.dart';
import 'package:status_maker/studio/models/template_config.dart';
import 'package:status_maker/studio/presets/category_presets.dart';
import 'package:status_maker/studio/templates/template_generator.dart';

/// The generated catalogue: for each category, a deterministic list of
/// [TemplateConfig] recipes (background × layout × quote index × options),
/// and the built templates memoised per language.
///
/// Why deterministic rather than random: a user who liked "the third
/// Morning card" yesterday should find the same card today, and two devices
/// should show the same catalogue. Variety comes from the pairing scheme,
/// not from a dice roll.
class TemplateCatalog {
  TemplateCatalog._();

  static final Map<String, List<TemplateConfig>> _configs = {};
  static final Map<String, List<FixedTemplate>> _built = {};

  /// Recipes for [category]. Backgrounds and layouts are paired so every
  /// (background, layout) combination appears before any repeats, and
  /// neighbours never share either.
  static List<TemplateConfig> configsFor(String category) {
    final hit = _configs[category];
    if (hit != null) return hit;

    final preset = categoryPreset(category);
    final bgs = backgroundPresetsForCategory(category);
    if (bgs.isEmpty) return _configs[category] = const [];
    final layouts = preset.layouts;
    final count = (bgs.length * layouts.length).clamp(8, 16);

    // Festival backgrounds each carry an occasion tag; keep a per-tag quote
    // cursor so each occasion walks through its own lines.
    final tagCursor = <String?, int>{};

    final out = <TemplateConfig>[];
    for (var i = 0; i < count; i++) {
      final k = i % bgs.length; // background index within this pass
      final pass = i ~/ bgs.length;
      final bg = bgs[k];
      // layout = (k + pass) mod L: within a pass neighbours differ in both;
      // across passes each background meets every layout once before any
      // pair repeats, whatever the two list lengths are (unlike schemes that
      // only work when the lengths are coprime).
      final layout = layouts[(k + pass) % layouts.length];
      final tag = bg.tag;
      final q = tagCursor.update(tag, (v) => v + 1, ifAbsent: () => 0);
      final spec = _frameFor(preset, bg.config.textColor, bg.config.accentColor);
      out.add(TemplateConfig(
        id: 'st_${category}_$i',
        category: category,
        backgroundId: bg.id,
        layout: layout,
        imageFrame: spec,
        namePosition: _namePositionFor(layout),
        nameStyle: preset.nameStyle,
        capabilities: capabilitiesFor(layout, i ~/ layouts.length),
        quoteTag: tag,
        quoteIndex: q,
      ));
    }
    return _configs[category] = List.unmodifiable(out);
  }

  /// Built templates for [category] in [language] (default: app language).
  static List<FixedTemplate> templatesFor(String category,
      {AppLanguage? language}) {
    final lang = language ?? AppLanguage.current;
    final key = '$category|${lang.code}';
    return _built[key] ??= List.unmodifiable([
      for (final cfg in configsFor(category))
        TemplateGenerator.build(cfg, language: lang),
    ]);
  }

  /// Backgrounds of [category] as editor states, for the background pickers.
  static List<BackgroundState> backgroundsFor(String category) => [
        for (final p in backgroundPresetsForCategory(category)) p.toState(),
      ];

  /// Drops every built template (quotes or presets changed at runtime).
  static void invalidate() {
    _configs.clear();
    _built.clear();
  }

  static PhotoFrameSpec _frameFor(CategoryPreset p, Color text, Color accent) =>
      PhotoFrameSpec(
        shape: p.photoShape,
        width: 130,
        top: 300,
        framed: p.photoFramed,
        frameStyle: p.frameStyle,
        // Gold frames are self-coloured; others take the design's text or
        // accent colour so the ring never fights the palette.
        frameColor: p.frameStyle == PhotoFrameStyle.glow ? accent : text,
        softEdge: p.softEdge,
      );

  static NamePosition _namePositionFor(LayoutType l) => switch (l) {
        LayoutType.largeQuoteSmallPhoto => NamePosition.bottomRight,
        LayoutType.fullImageQuoteOverlay => NamePosition.bottomCenter,
        LayoutType.quoteOnly => NamePosition.none,
        LayoutType.circlePhotoCenterQuote => NamePosition.underQuote,
        LayoutType.minimalText => NamePosition.underQuote,
        LayoutType.photoQuoteSignature => NamePosition.signature,
        LayoutType.traditional => NamePosition.bottomCenter,
        LayoutType.modernPremium => NamePosition.underQuote,
      };
}
