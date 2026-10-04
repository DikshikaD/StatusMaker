// The studio: generated backgrounds, quotes and templates. These pin down the
// contracts the UI relies on — recipes survive a JSON round trip, every
// category has quotes in both languages, the catalogue is genuinely varied,
// and no layout places text where it can't fit.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/fixed_templates.dart';
import 'package:status_maker/features/editor/data/status_design.dart';
import 'package:status_maker/features/editor/widgets/fixed_template_canvas.dart';
import 'package:status_maker/studio/background/background_presets.dart';
import 'package:status_maker/studio/models/background_config.dart';
import 'package:status_maker/studio/models/category_model.dart';
import 'package:status_maker/studio/models/language_model.dart';
import 'package:status_maker/studio/models/template_config.dart';
import 'package:status_maker/studio/presets/category_presets.dart';
import 'package:status_maker/studio/quotes/quote_repository.dart';
import 'package:status_maker/studio/templates/template_catalog.dart';

void main() {
  group('BackgroundConfig', () {
    test('every preset survives a JSON round trip unchanged', () {
      for (final p in kBackgroundPresets) {
        final json = p.config.toJson();
        final back = BackgroundConfig.fromJson(
            Map<String, dynamic>.from(json));
        expect(back.signature, p.config.signature, reason: p.id);
        expect(back, p.config);
      }
    });

    test('preset ids are unique and each category has at least three', () {
      final ids = kBackgroundPresets.map((p) => p.id).toSet();
      expect(ids.length, kBackgroundPresets.length);
      for (final c in kStudioCategories) {
        expect(backgroundPresetsForCategory(c.id).length,
            greaterThanOrEqualTo(3),
            reason: c.id);
      }
    });

    test('unknown layer kinds are skipped, not fatal', () {
      final cfg = BackgroundConfig.fromJson({
        'id': 'x',
        'category': 'any',
        'gradient': [0xFF000000, 0xFFFFFFFF],
        'layers': [
          {'type': 'hologram', 'foo': 1},
          {'type': 'vignette', 'strength': 0.3},
        ],
        'text': 0xFFFFFFFF,
      });
      expect(cfg.layers.length, 1);
      expect(cfg.layers.first, isA<VignetteLayer>());
    });
  });

  group('StatusDesign JSON', () {
    test('generated background, frame style and soft edge round-trip', () {
      final preset = kBackgroundPresets.first;
      final design = StatusDesign(
        background: preset.toState(),
        texts: const [],
        images: [
          ImageObject(
            id: 'p',
            path: '',
            frameStyle: PhotoFrameStyle.gold,
            softEdge: 18,
          ),
        ],
        elements: const [],
      );
      final back = StatusDesign.fromJson(design.toJson());
      expect(back.background.generated, preset.config);
      expect(back.background.motif, preset.motif);
      expect(back.images.single.frameStyle, PhotoFrameStyle.gold);
      expect(back.images.single.softEdge, 18);
    });

    test('a design saved before the studio existed loads with defaults', () {
      final back = StatusDesign.fromJson({
        'schema': 1,
        'background': {'gradient': [0xFF111111, 0xFF222222]},
        'texts': [],
        'images': [
          {
            'id': 'i',
            'path': '',
            'shape': 'circle',
            'pos': {'dx': 0, 'dy': 0},
          }
        ],
        'elements': [],
      });
      expect(back.background.isGenerated, isFalse);
      expect(back.background.isGradient, isTrue);
      expect(back.images.single.frameStyle, PhotoFrameStyle.classic);
      expect(back.images.single.softEdge, 0);
    });
  });

  group('QuoteRepository', () {
    test('every category has quotes in both languages', () {
      for (final c in kStudioCategories) {
        for (final lang in AppLanguage.values) {
          final q = QuoteRepository.forCategory(c.id, lang);
          expect(q, isNotEmpty, reason: '${c.id}/${lang.code}');
          for (final m in q) {
            expect(m.language, lang);
            expect(m.text.trim(), isNotEmpty);
          }
        }
      }
    });

    test('festival occasions are isolated from each other', () {
      final tags = backgroundPresetsForCategory('festival')
          .map((p) => p.tag)
          .whereType<String>()
          .toSet();
      expect(tags, isNotEmpty);
      for (final tag in tags) {
        for (final lang in AppLanguage.values) {
          final q = QuoteRepository.forCategory('festival', lang, tag: tag);
          expect(q, isNotEmpty, reason: '$tag/${lang.code}');
          expect(q.every((m) => m.tag == tag), isTrue);
        }
      }
      // The untagged pool must not leak an occasion-specific line.
      final generic = QuoteRepository.forCategory('festival', AppLanguage.en);
      expect(generic.every((m) => m.tag == null), isTrue);
    });

    test('pick wraps and never throws', () {
      final q = QuoteRepository.pick('minimal', AppLanguage.hi, 1000);
      expect(q.text, isNotEmpty);
    });
  });

  group('TemplateCatalog', () {
    test('neighbouring templates never share background or layout', () {
      for (final c in kStudioCategories) {
        final cfgs = TemplateCatalog.configsFor(c.id);
        expect(cfgs.length, greaterThanOrEqualTo(8), reason: c.id);
        expect(cfgs.map((e) => e.id).toSet().length, cfgs.length);
        for (var i = 1; i < cfgs.length; i++) {
          expect(cfgs[i].backgroundId, isNot(cfgs[i - 1].backgroundId),
              reason: '${c.id}#$i');
          expect(cfgs[i].layout, isNot(cfgs[i - 1].layout),
              reason: '${c.id}#$i');
        }
        // Every (background, layout) pairing is distinct within the first
        // full pass over both lists.
        final preset = categoryPreset(c.id);
        final n = backgroundPresetsForCategory(c.id).length * preset.layouts.length;
        final pairs = <String>{};
        for (final cfg in cfgs.take(n)) {
          expect(pairs.add('${cfg.backgroundId}|${cfg.layout.name}'), isTrue,
              reason: '${c.id} repeats ${cfg.backgroundId}/${cfg.layout.name}');
        }
      }
    });

    test('categories use different layout vocabularies', () {
      final sets = kCategoryPresets
          .map((p) => (p.layouts.map((l) => l.name).toList()..sort()).join(','))
          .toSet();
      expect(sets.length, kCategoryPresets.length);
    });

    test('festival templates only ever offer their own occasion', () {
      for (final cfg in TemplateCatalog.configsFor('festival')) {
        final bg = backgroundPresetById(cfg.backgroundId)!;
        expect(cfg.quoteTag, bg.tag);
      }
    });

    test('built templates carry both languages and fit their slots', () {
      for (final c in kStudioCategories) {
        for (final lang in AppLanguage.values) {
          final templates = TemplateCatalog.templatesFor(c.id, language: lang);
          expect(templates, isNotEmpty);
          for (final t in templates) {
            _checkTemplate(t, lang);
          }
        }
      }
    });

    test('an empty name slot exports blank, not a placeholder', () {
      S.lang.value = 'en';
      final t = TemplateCatalog.templatesFor('morning')
          .firstWhere((t) => t.hasNameSlot);
      final d = t.design();
      final name = d.texts.firstWhere((x) => x.id == t.nameSlotId);
      expect(name.text, '');
      expect(t.nameFormat!('Raj'), '— Raj');
      expect(NameStyle.strip('— Raj'), 'Raj');
      expect(NameStyle.by.format('Raj', AppLanguage.en), 'By Raj');
      expect(NameStyle.by.format('राज', AppLanguage.hi), '— राज');
    });
  });

  test('a template built in Hindi shows Hindi even in an English UI', () {
    S.lang.value = 'en';
    final t = TemplateCatalog.templatesFor('minimal', language: AppLanguage.hi)
        .first;
    final quote = t.previewDesign().texts
        .firstWhere((x) => x.id == (t.quoteSlotId ?? t.texts.first.id));
    expect(quote.text, t.hiText[quote.id]);
    final en = TemplateCatalog.templatesFor('minimal', language: AppLanguage.en)
        .first;
    final enQuote = en.previewDesign().texts
        .firstWhere((x) => x.id == (en.quoteSlotId ?? en.texts.first.id));
    expect(enQuote.text, en.enText[enQuote.id]);
  });

  testWidgets('a generated template renders in the locked canvas',
      (tester) async {
    final t = TemplateCatalog.templatesFor('premium_dark').first;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 270,
            height: 480,
            child: FixedTemplateCanvas(
              design: t.previewDesign(),
              lineLimits: t.lineLimits,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(FixedTemplateCanvas), findsOneWidget);
  });
}

/// Per-slot sanity: quote in both languages, sensible font sizes, every text
/// band inside the canvas, and no two text bands overlapping (except the
/// full-photo layout, whose quote sits over the photo by design).
void _checkTemplate(FixedTemplate t, AppLanguage lang) {
  expect(t.studioCategory, isNotNull);
  final quoteId = t.quoteSlotId ?? t.texts.first.id;
  expect(t.textFor(quoteId, hindi: true), isNotNull, reason: t.id);
  expect(t.textFor(quoteId, hindi: false), isNotNull, reason: t.id);
  expect(t.showNamePlaceholder, isFalse);

  final bands = <(String, double, double)>[];
  for (final x in t.texts) {
    expect(x.fontSize, greaterThanOrEqualTo(11), reason: '${t.id}/${x.id}');
    final lines = t.maxLines[x.id] ?? 1;
    final h = textSlotHeight(
        fontSize: x.fontSize, lineHeight: x.lineHeight, lines: lines);
    final top = x.position.dy;
    final bottom = top + h;
    expect(top, greaterThanOrEqualTo(0), reason: '${t.id}/${x.id}');
    expect(bottom, lessThanOrEqualTo(640), reason: '${t.id}/${x.id} $bottom');
    bands.add((x.id, top, bottom));
  }
  for (var i = 0; i < bands.length; i++) {
    for (var j = i + 1; j < bands.length; j++) {
      final a = bands[i], b = bands[j];
      final overlap = a.$2 < b.$3 && b.$2 < a.$3;
      expect(overlap, isFalse,
          reason: '${t.id}: ${a.$1} (${a.$2}-${a.$3}) overlaps ${b.$1} (${b.$2}-${b.$3})');
    }
  }
}
