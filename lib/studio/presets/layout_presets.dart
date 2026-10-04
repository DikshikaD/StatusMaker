import 'package:flutter/material.dart';

import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/utils/image_shape_utils.dart';
import 'package:status_maker/studio/models/background_config.dart';
import 'package:status_maker/studio/models/template_config.dart';
import 'package:status_maker/studio/presets/category_presets.dart';

// ---------------------------------------------------------------------------
// Slot geometry — identical conventions to fixed_templates.dart so a generated
// design renders in FixedTemplateCanvas / the free editor exactly like the
// hand-authored ones: every position is the top-left of the *unscaled* box,
// `scale` pivots on the box centre, and every object carries 6px of padding.
// ---------------------------------------------------------------------------
const double _objPad = 6;
const double _canvasW = 360;

double _centeredLeft(double boxWidth) => (_canvasW - (boxWidth + 2 * _objPad)) / 2;

TextObject _text({
  required String id,
  required String text,
  required String font,
  required double size,
  required Color color,
  required double top,
  double? left,
  double boxWidth = kDefaultTextBoxWidth,
  bool bold = true,
  bool italic = false,
  double letterSpacing = 0,
  double lineHeight = 1.3,
  Color? highlight,
  TextAlign align = TextAlign.center,
}) =>
    TextObject(
      id: id,
      text: text,
      fontFamily: font,
      color: color,
      fontSize: size,
      textAlign: align,
      bold: bold,
      italic: italic,
      letterSpacing: letterSpacing,
      lineHeight: lineHeight,
      highlight: highlight,
      position: Offset(left ?? _centeredLeft(boxWidth), top),
      boxWidth: boxWidth == kDefaultTextBoxWidth ? null : boxWidth,
    );

/// A photo slot from its *visible* geometry (see fixed_templates.dart).
ImageObject photoSlotFromSpec(String id, PhotoFrameSpec spec) {
  final base = baseSizeForImageShape(spec.shape);
  final boxW = base.width + 2 * _objPad;
  final boxH = base.height + 2 * _objPad;
  final scale = spec.width / boxW;
  final visH = boxH * scale;
  final cx = spec.centerX ?? _canvasW / 2;
  return ImageObject(
    id: id,
    path: '',
    shape: spec.shape,
    position: Offset(
      cx - spec.width / 2 - (boxW - spec.width) / 2,
      spec.top - (boxH - visH) / 2,
    ),
    scale: scale,
    isPlaceholder: true,
    framed: spec.framed,
    frameColor: spec.frameColor,
    frameStyle: spec.frameStyle,
    softEdge: spec.softEdge,
  );
}

/// Visible height of the photo [spec] on the canvas.
double photoVisibleHeight(PhotoFrameSpec spec) {
  final base = baseSizeForImageShape(spec.shape);
  final boxW = base.width + 2 * _objPad;
  final boxH = base.height + 2 * _objPad;
  return boxH * (spec.width / boxW);
}

ElementObject _rule({
  required String id,
  required Color color,
  required double centerY,
  double centerX = _canvasW / 2,
  double width = 90,
}) {
  const boxW = 160 + 2 * _objPad;
  const boxH = 80 + 2 * _objPad;
  final scale = width / boxW;
  return ElementObject(
    id: id,
    shape: ElementShape.line,
    color: color,
    position: Offset(centerX - boxW / 2, centerY - boxH / 2),
    scale: scale,
  );
}

/// A small accent sticker whose *visible* size is [size] px, centred at
/// ([cx], [cy]).
ElementObject _decor({
  required String id,
  required ElementShape shape,
  required Color color,
  required double cx,
  required double cy,
  double size = 30,
  double rotation = 0,
}) {
  const boxW = 120 + 2 * _objPad;
  final scale = size / boxW;
  return ElementObject(
    id: id,
    shape: shape,
    color: color,
    position: Offset(cx - boxW / 2, cy - boxW / 2),
    scale: scale,
    rotation: rotation,
  );
}

// ---------------------------------------------------------------------------
// Fitting
// ---------------------------------------------------------------------------

/// Visual weight of a line — Devanagari glyphs run wider, so count double.
int textWeight(String s) {
  var w = 0;
  for (final r in s.runes) {
    w += (r >= 0x0900 && r <= 0x097F) ? 2 : 1;
  }
  return w;
}

/// Shrinks [base] until a quote of [weight] fits [maxLines] in [boxWidth],
/// never below [min]. Approximation (average glyph ≈ 0.52 em) — the canvas
/// still ellipsizes as a last resort, this just makes that rare.
double fitFontSize(int weight, double base,
    {required double boxWidth, required int maxLines, double min = 16}) {
  var size = base;
  for (var i = 0; i < 12; i++) {
    final perLine = (boxWidth - 24) / (size * 0.52);
    final lines = (weight / perLine).ceil();
    if (lines <= maxLines) break;
    size -= 1.5;
    if (size <= min) return min;
  }
  return size;
}

// ---------------------------------------------------------------------------
// Blueprint
// ---------------------------------------------------------------------------

/// What a layout produces: the slots plus which slot plays which role.
class LayoutBlueprint {
  final List<TextObject> texts;
  final List<ElementObject> elements;
  final ImageObject? photo;
  final bool showPlaceholder;
  final String quoteSlotId;
  final String? nameSlotId;
  final String? titleSlotId;
  final Map<String, int> maxLines;

  const LayoutBlueprint({
    required this.texts,
    required this.elements,
    required this.photo,
    required this.showPlaceholder,
    required this.quoteSlotId,
    required this.nameSlotId,
    this.titleSlotId,
    required this.maxLines,
  });
}

/// Everything a layout needs to know to dress itself.
class LayoutContext {
  final String idPrefix;
  final CategoryPreset preset;
  final BackgroundConfig palette;
  final PhotoFrameSpec? photo;

  /// Quote in the language the design is being authored in.
  final String quote;

  /// Visual weight of the longer of the two language versions, so a slot
  /// sized here fits after a language switch too.
  final int quoteWeight;

  /// Greeting in the authoring language (title / kicker).
  final String greeting;

  /// Weight of the longer greeting (both languages), for one-line fitting.
  final int greetingWeight;

  const LayoutContext({
    required this.idPrefix,
    required this.preset,
    required this.palette,
    required this.photo,
    required this.quote,
    required this.quoteWeight,
    required this.greeting,
    required this.greetingWeight,
  });

  String id(String role) => '${idPrefix}_$role';
  Color get text => palette.textColor;
  Color get muted => palette.mutedTextColor;
  Color get accent => palette.accentColor;
  FontPair get fonts => preset.fonts;
}

/// Builds the slots for [type]. Vertical bands (out of 640) are noted per
/// slot so collisions are checkable at a glance.
LayoutBlueprint buildLayout(LayoutType type, LayoutContext c) {
  switch (type) {
    case LayoutType.largeQuoteSmallPhoto:
      return _layoutA(c);
    case LayoutType.fullImageQuoteOverlay:
      return _layoutB(c);
    case LayoutType.quoteOnly:
      return _layoutC(c);
    case LayoutType.circlePhotoCenterQuote:
      return _layoutD(c);
    case LayoutType.minimalText:
      return _layoutE(c);
    case LayoutType.photoQuoteSignature:
      return _layoutF(c);
    case LayoutType.traditional:
      return _layoutG(c);
    case LayoutType.modernPremium:
      return _layoutH(c);
  }
}

String _maybeUpper(LayoutContext c, String s) =>
    c.preset.upperQuote && textWeight(s) == s.length ? s.toUpperCase() : s;

/// A — Large quote (80–330), small photo (380–490), name bottom-right (560).
LayoutBlueprint _layoutA(LayoutContext c) {
  const maxLines = 5;
  final size = fitFontSize(c.quoteWeight, 34, boxWidth: 300, maxLines: maxLines);
  final photo = c.photo?.copyWith(width: 110, top: 380);
  final decor = c.preset.decor;
  return LayoutBlueprint(
    texts: [
      _text(
        id: c.id('quote'),
        text: _maybeUpper(c, c.quote),
        font: c.fonts.display,
        size: size,
        color: c.text,
        top: 84,
        lineHeight: 1.3,
      ),
      _text(
        id: c.id('name'),
        text: '',
        font: c.fonts.body,
        size: 14,
        color: c.muted,
        top: 560,
        bold: false,
        letterSpacing: 1,
        align: TextAlign.right,
      ),
    ],
    elements: [
      _rule(id: c.id('rule'), color: c.accent, centerY: 352, width: 60),
      if (decor != null)
        _decor(
            id: c.id('decor'),
            shape: decor,
            color: c.accent,
            cx: 48,
            cy: 56,
            size: 26),
    ],
    photo: photo == null ? null : photoSlotFromSpec(c.id('photo'), photo),
    showPlaceholder: true,
    quoteSlotId: c.id('quote'),
    nameSlotId: c.id('name'),
    maxLines: {c.id('quote'): maxLines, c.id('name'): 1},
  );
}

/// B — Photo fills the top (20–433), quote on a scrim over its lower part
/// (330–440), name bottom-centre (572).
LayoutBlueprint _layoutB(LayoutContext c) {
  const maxLines = 3;
  final size = fitFontSize(c.quoteWeight, 26, boxWidth: 300, maxLines: maxLines);
  final spec = (c.photo ??
          PhotoFrameSpec(shape: ImageShape.roundedRectangle, width: 300, top: 20))
      .copyWith(
    shape: ImageShape.roundedRectangle,
    width: 328,
    top: 20,
    framed: false,
    softEdge: 22,
  );
  return LayoutBlueprint(
    texts: [
      _text(
        id: c.id('quote'),
        text: c.quote,
        font: c.fonts.display,
        size: size,
        color: Colors.white,
        top: 340,
        lineHeight: 1.3,
        highlight: const Color(0x99000000),
      ),
      _text(
        id: c.id('name'),
        text: '',
        font: c.fonts.body,
        size: 14,
        color: c.muted,
        top: 572,
        bold: false,
        letterSpacing: 1.5,
      ),
    ],
    elements: const [],
    photo: photoSlotFromSpec(c.id('photo'), spec),
    showPlaceholder: true,
    quoteSlotId: c.id('quote'),
    nameSlotId: c.id('name'),
    maxLines: {c.id('quote'): maxLines, c.id('name'): 1},
  );
}

/// C — Quote only: rule (200), quote (235–440), rule (466). Nothing else.
LayoutBlueprint _layoutC(LayoutContext c) {
  const maxLines = 4;
  final size = fitFontSize(c.quoteWeight, 32, boxWidth: 300, maxLines: maxLines);
  final decor = c.preset.decor;
  return LayoutBlueprint(
    texts: [
      _text(
        id: c.id('quote'),
        text: _maybeUpper(c, c.quote),
        font: c.fonts.display,
        size: size,
        color: c.text,
        top: 236,
        lineHeight: 1.35,
        italic: c.preset.id == 'heartbreak',
      ),
    ],
    elements: [
      _rule(id: c.id('rule1'), color: c.accent, centerY: 204, width: 80),
      _rule(id: c.id('rule2'), color: c.accent, centerY: 466, width: 80),
      if (decor != null)
        _decor(
            id: c.id('decor'),
            shape: decor,
            color: c.accent,
            cx: 180,
            cy: 168,
            size: 28),
    ],
    photo: null,
    showPlaceholder: false,
    quoteSlotId: c.id('quote'),
    nameSlotId: null,
    maxLines: {c.id('quote'): maxLines},
  );
}

/// D — Circular photo (90–250), quote centred (290–460), name under it (490).
LayoutBlueprint _layoutD(LayoutContext c) {
  const maxLines = 4;
  final size = fitFontSize(c.quoteWeight, 28, boxWidth: 300, maxLines: maxLines);
  final spec = (c.photo ?? PhotoFrameSpec(shape: ImageShape.circle, width: 160, top: 90))
      .copyWith(shape: ImageShape.circle, width: 160, top: 90);
  return LayoutBlueprint(
    texts: [
      _text(
        id: c.id('quote'),
        text: c.quote,
        font: c.fonts.display,
        size: size,
        color: c.text,
        top: 290,
        lineHeight: 1.35,
      ),
      _text(
        id: c.id('name'),
        text: '',
        font: c.fonts.body,
        size: 15,
        color: c.muted,
        top: 492,
        bold: false,
      ),
    ],
    elements: [
      _rule(id: c.id('rule'), color: c.accent, centerY: 480, width: 44),
    ],
    photo: photoSlotFromSpec(c.id('photo'), spec),
    showPlaceholder: true,
    quoteSlotId: c.id('quote'),
    nameSlotId: c.id('name'),
    maxLines: {c.id('quote'): maxLines, c.id('name'): 1},
  );
}

/// E — Minimal: short rule (366), left-aligned quote (380–542), tiny name
/// (566). Everything above is empty on purpose.
LayoutBlueprint _layoutE(LayoutContext c) {
  const maxLines = 4;
  const box = 260.0;
  const left = 36.0;
  final size = fitFontSize(c.quoteWeight, 24, boxWidth: box, maxLines: maxLines);
  return LayoutBlueprint(
    texts: [
      _text(
        id: c.id('quote'),
        text: c.quote,
        font: c.fonts.display,
        size: size,
        color: c.text,
        top: 380,
        left: left,
        boxWidth: box,
        bold: false,
        lineHeight: 1.4,
        align: TextAlign.left,
      ),
      _text(
        id: c.id('name'),
        text: '',
        font: c.fonts.body,
        size: 12,
        color: c.muted,
        top: 566,
        left: left,
        boxWidth: box,
        bold: false,
        letterSpacing: 2.5,
        align: TextAlign.left,
      ),
    ],
    elements: [
      _rule(
          id: c.id('rule'),
          color: c.accent,
          centerY: 366,
          centerX: left + 12 + 20,
          width: 40),
    ],
    photo: null,
    showPlaceholder: false,
    quoteSlotId: c.id('quote'),
    nameSlotId: c.id('name'),
    maxLines: {c.id('quote'): maxLines, c.id('name'): 1},
  );
}

/// F — Photo (70–267), quote (300–450), handwritten signature (520).
LayoutBlueprint _layoutF(LayoutContext c) {
  const maxLines = 4;
  final size = fitFontSize(c.quoteWeight, 26, boxWidth: 300, maxLines: maxLines);
  final spec = (c.photo ??
          PhotoFrameSpec(shape: ImageShape.roundedRectangle, width: 150, top: 70))
      .copyWith(width: 150, top: 70);
  return LayoutBlueprint(
    texts: [
      _text(
        id: c.id('quote'),
        text: c.quote,
        font: c.fonts.body,
        size: size,
        color: c.text,
        top: 300,
        bold: false,
        lineHeight: 1.45,
      ),
      _text(
        id: c.id('name'),
        text: '',
        font: c.fonts.script,
        size: 24,
        color: c.accent,
        top: 516,
        bold: false,
        align: TextAlign.right,
      ),
    ],
    elements: const [],
    photo: photoSlotFromSpec(c.id('photo'), spec),
    showPlaceholder: true,
    quoteSlotId: c.id('quote'),
    nameSlotId: c.id('name'),
    maxLines: {c.id('quote'): maxLines, c.id('name'): 1},
  );
}

/// G — Traditional: one-line title (56–≤132), ornament (150), body quote
/// (172–332), photo (350–480), name bottom-centre (545).
LayoutBlueprint _layoutG(LayoutContext c) {
  const maxLines = 4;
  final size = fitFontSize(c.quoteWeight, 22, boxWidth: 300, maxLines: maxLines, min: 15);
  // The greeting must stay on one line ("Independence Day", "स्वतंत्रता
  // दिवस") or it collides with the body below.
  final titleSize = fitFontSize(c.greetingWeight, 38, boxWidth: 300, maxLines: 1, min: 24);
  final spec = (c.photo ?? PhotoFrameSpec(shape: ImageShape.circle, width: 130, top: 350))
      .copyWith(shape: ImageShape.circle, width: 130, top: 350);
  final decor = c.preset.decor ?? ElementShape.diamond;
  return LayoutBlueprint(
    texts: [
      _text(
        id: c.id('title'),
        text: c.greeting,
        font: c.fonts.display,
        size: titleSize,
        color: c.text,
        top: 56,
        lineHeight: 1.25,
      ),
      _text(
        id: c.id('quote'),
        text: c.quote,
        font: c.fonts.body,
        size: size,
        color: c.muted,
        top: 172,
        bold: false,
        lineHeight: 1.5,
      ),
      _text(
        id: c.id('name'),
        text: '',
        font: c.fonts.body,
        size: 15,
        color: c.muted,
        top: 545,
        bold: false,
      ),
    ],
    elements: [
      _rule(id: c.id('rule_l'), color: c.accent, centerY: 150, centerX: 128, width: 70),
      _rule(id: c.id('rule_r'), color: c.accent, centerY: 150, centerX: 232, width: 70),
      _decor(id: c.id('decor'), shape: decor, color: c.accent, cx: 180, cy: 150, size: 22),
    ],
    photo: photoSlotFromSpec(c.id('photo'), spec),
    showPlaceholder: true,
    quoteSlotId: c.id('quote'),
    nameSlotId: c.id('name'),
    titleSlotId: c.id('title'),
    maxLines: {c.id('title'): 1, c.id('quote'): maxLines, c.id('name'): 1},
  );
}

/// H — Modern premium: kicker (70), small square photo top-right (60–144),
/// big left-aligned quote (180–440), hairline (470), name (490).
LayoutBlueprint _layoutH(LayoutContext c) {
  const maxLines = 5;
  const box = 290.0;
  const left = 32.0;
  final size = fitFontSize(c.quoteWeight, 34, boxWidth: box, maxLines: maxLines);
  final spec = (c.photo ?? PhotoFrameSpec(shape: ImageShape.square, width: 84, top: 60))
      .copyWith(shape: ImageShape.square, width: 84, top: 60, centerX: 296);
  return LayoutBlueprint(
    texts: [
      _text(
        id: c.id('kicker'),
        text: c.greeting.toUpperCase(),
        font: c.fonts.body,
        size: 11,
        color: c.muted,
        top: 72,
        left: left,
        boxWidth: 200,
        bold: true,
        letterSpacing: 4,
        align: TextAlign.left,
      ),
      _text(
        id: c.id('quote'),
        text: _maybeUpper(c, c.quote),
        font: c.fonts.display,
        size: size,
        color: c.text,
        top: 180,
        left: left,
        boxWidth: box,
        lineHeight: 1.25,
        align: TextAlign.left,
      ),
      _text(
        id: c.id('name'),
        text: '',
        font: c.fonts.body,
        size: 13,
        color: c.muted,
        top: 488,
        left: left,
        boxWidth: box,
        bold: false,
        letterSpacing: 1,
        align: TextAlign.left,
      ),
    ],
    elements: [
      _rule(id: c.id('rule'), color: c.accent, centerY: 472, centerX: left + 12 + 30, width: 60),
    ],
    photo: photoSlotFromSpec(c.id('photo'), spec),
    showPlaceholder: true,
    quoteSlotId: c.id('quote'),
    nameSlotId: c.id('name'),
    titleSlotId: c.id('kicker'),
    maxLines: {c.id('kicker'): 1, c.id('quote'): maxLines, c.id('name'): 1},
  );
}
