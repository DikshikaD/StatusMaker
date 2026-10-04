import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/fixed_templates.dart';
import 'package:status_maker/studio/background/background_presets.dart';
import 'package:status_maker/studio/models/category_model.dart';
import 'package:status_maker/studio/models/language_model.dart';
import 'package:status_maker/studio/models/quote_model.dart';
import 'package:status_maker/studio/models/template_config.dart';
import 'package:status_maker/studio/presets/category_presets.dart';
import 'package:status_maker/studio/presets/layout_presets.dart';
import 'package:status_maker/studio/quotes/quote_repository.dart';

/// Turns a [TemplateConfig] recipe into a concrete, locked [FixedTemplate]:
/// background preset + layout blueprint + quotes in both languages + photo
/// frame + name slot + decorations. The result renders through the existing
/// `FixedTemplateCanvas` and edits through the existing `TemplateFillScreen`
/// — the studio adds content, not a second editor.
class TemplateGenerator {
  TemplateGenerator._();

  /// Builds the template as it should appear in [language] (defaults to the
  /// app language). Both languages' wording is attached regardless, so the
  /// locked editor can switch without rebuilding.
  static FixedTemplate build(TemplateConfig cfg, {AppLanguage? language}) {
    final lang = language ?? AppLanguage.current;
    final preset = categoryPreset(cfg.category);
    final bg = backgroundPresetById(cfg.backgroundId) ??
        backgroundPresetsForCategory(cfg.category).first;
    final palette = bg.config;

    final QuoteModel qEn = QuoteRepository.pick(
        cfg.category, AppLanguage.en, cfg.quoteIndex, tag: cfg.quoteTag);
    final QuoteModel qHi = QuoteRepository.pick(
        cfg.category, AppLanguage.hi, cfg.quoteIndex, tag: cfg.quoteTag);
    final quoteNow = lang.isHindi ? qHi.text : qEn.text;
    final weight = qEn.weight > qHi.weight ? qEn.weight : qHi.weight;

    final greetingEn = preset.greeting(hindi: false, tag: cfg.quoteTag);
    final greetingHi = preset.greeting(hindi: true, tag: cfg.quoteTag);

    final ctx = LayoutContext(
      idPrefix: cfg.id,
      preset: preset,
      palette: palette,
      photo: cfg.imageFrame,
      quote: quoteNow,
      quoteWeight: weight,
      greeting: lang.isHindi ? greetingHi : greetingEn,
      greetingWeight: textWeight(greetingEn) > textWeight(greetingHi)
          ? textWeight(greetingEn)
          : textWeight(greetingHi),
    );
    final bp = buildLayout(cfg.layout, ctx);

    // Both languages for the quote (and title/kicker) so textFor() and the
    // language toggle have what they need. The modern layout's kicker is
    // upper-cased Latin; Devanagari has no case so it passes through.
    final upper = preset.upperQuote;
    String maybeUpper(String s) =>
        upper && textWeight(s) == s.length ? s.toUpperCase() : s;
    final hiText = <String, String>{bp.quoteSlotId: maybeUpper(qHi.text)};
    final enText = <String, String>{bp.quoteSlotId: maybeUpper(qEn.text)};
    if (bp.titleSlotId != null) {
      final kicker = cfg.layout == LayoutType.modernPremium;
      hiText[bp.titleSlotId!] = kicker ? greetingHi.toUpperCase() : greetingHi;
      enText[bp.titleSlotId!] = kicker ? greetingEn.toUpperCase() : greetingEn;
    }

    // Alternate backgrounds: the rest of the category, only when allowed.
    final alternates = cfg.capabilities.changeBackground
        ? [
            for (final p in backgroundPresetsForCategory(cfg.category))
              if (p.id != bg.id && (cfg.quoteTag == null || p.tag == cfg.quoteTag))
                p.toState(),
          ]
        : const <BackgroundState>[];

    // Capabilities that remove a slot altogether.
    final texts = <TextObject>[
      for (final t in bp.texts)
        if (t.id != bp.nameSlotId || cfg.capabilities.changeName) t,
    ];
    final nameSlotId = cfg.capabilities.changeName ? bp.nameSlotId : null;
    final photo = cfg.capabilities.changePhoto ? bp.photo : null;

    final category = studioCategory(cfg.category);
    return FixedTemplate(
      id: cfg.id,
      name: _nameFor(category, cfg.layout, lang),
      theme: cfg.category,
      background: bg.toState(),
      texts: texts,
      elements: bp.elements,
      photo: photo,
      showPlaceholder: photo != null && bp.showPlaceholder,
      nameSlotId: nameSlotId,
      hiText: hiText,
      enText: enText,
      maxLines: bp.maxLines,
      quoteSlotId: cfg.capabilities.editQuote ? bp.quoteSlotId : null,
      showNamePlaceholder: false,
      nameFormat: (raw) => preset.nameStyle.format(raw, lang),
      alternateBackgrounds: alternates,
      allowLanguageChange: cfg.capabilities.changeLanguage &&
          cfg.languageSupport.length > 1,
      studioCategory: cfg.category,
      quoteCategoryKey: category.legacyQuoteCategory,
      quoteTag: cfg.quoteTag,
      languageCode: lang.code,
    );
  }

  static String _nameFor(CategoryModel c, LayoutType layout, AppLanguage lang) {
    final cat = lang.isHindi ? c.nameHi : c.nameEn;
    final style = switch (layout) {
      LayoutType.largeQuoteSmallPhoto => lang.isHindi ? 'क्लासिक' : 'Classic',
      LayoutType.fullImageQuoteOverlay => lang.isHindi ? 'फ़ोटो' : 'Photo',
      LayoutType.quoteOnly => lang.isHindi ? 'कोट' : 'Quote',
      LayoutType.circlePhotoCenterQuote => lang.isHindi ? 'पोर्ट्रेट' : 'Portrait',
      LayoutType.minimalText => lang.isHindi ? 'मिनिमल' : 'Minimal',
      LayoutType.photoQuoteSignature => lang.isHindi ? 'सिग्नेचर' : 'Signature',
      LayoutType.traditional => lang.isHindi ? 'पारंपरिक' : 'Traditional',
      LayoutType.modernPremium => lang.isHindi ? 'मॉडर्न' : 'Modern',
    };
    return '$cat · $style';
  }
}
