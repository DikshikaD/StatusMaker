import 'package:flutter/material.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/status_design.dart';
import 'package:status_maker/features/editor/data/template_motif.dart';
import 'package:status_maker/features/editor/utils/image_shape_utils.dart';

/// The logical canvas every fixed template is designed against. The locked
/// canvas always lays out at exactly this size (scaled to fit the screen with
/// a FittedBox), so positions here are deterministic on every device — unlike
/// the free editor, where coordinates depend on the live canvas size.
const Size kFixedCanvasSize = Size(360, 640);

/// The theme rows the Create tab groups the ready-made designs into. The order
/// here is the order they appear on screen; each key's heading comes from
/// `S.t('grp_<key>')`.
const List<String> kFixedTemplateThemes = [
  'morning',
  'wishes',
  'night',
  'devotional',
  'love',
  'quotes',
];

/// A ready-made design with a LOCKED layout. The user can only:
///  • edit the words of each text slot (style & position stay fixed)
///  • add / replace the photo in its designed slot
///
/// Nothing can be moved, scaled, rotated, recolored, added or deleted —
/// that's the whole point: the composition always looks the way it was
/// designed.
class FixedTemplate {
  final String id;
  final String name;

  /// Which row of the Create tab this belongs to — one of
  /// [kFixedTemplateThemes].
  final String theme;

  final BackgroundState background;
  final StatusFrame frame;
  final Color frameColor;
  final double frameWidth;

  /// Prototype text slots — content is user-editable, everything else fixed.
  final List<TextObject> texts;

  /// Fixed decorative accents (never selectable or movable).
  final List<ElementObject> elements;

  /// The designed photo slot. Every template has one so any design can take
  /// the user's picture.
  final ImageObject? photo;

  /// Whether the empty photo slot is visible from the start ("Add photo"
  /// frame baked into the design) or only appears once the user adds a photo
  /// (a clean text design that optionally takes an overlay picture).
  final bool showPlaceholder;

  /// The id of the text slot meant for the user's own name. Drives the
  /// "Add your name" / "अपना नाम जोड़ें" button, and gets a localized
  /// placeholder so the design never ships a blank gap.
  final String? nameSlotId;

  // Not const: the template memoizes its preview design and line limits below,
  // which needs mutable fields. Nothing constructs these as const anyway — each
  // entry in [kFixedTemplates] is built from helper calls.
  FixedTemplate({
    required this.id,
    required this.name,
    required this.theme,
    required this.background,
    required this.texts,
    this.elements = const [],
    this.photo,
    this.showPlaceholder = false,
    this.nameSlotId,
    this.frame = StatusFrame.none,
    this.frameColor = Colors.white,
    this.frameWidth = 1.0,
  });

  bool get hasPhotoOption => photo != null;
  bool get hasNameSlot => nameSlotId != null;

  /// The quote category that best matches this theme, so opening the design in
  /// the editor can suggest lines that fit it.
  String get quoteCategory {
    switch (theme) {
      case 'morning':
        return 'Suprabhat';
      case 'wishes':
        return 'Festival';
      case 'night':
        return 'Good Night';
      case 'devotional':
        return 'Devotional';
      case 'love':
        return 'Love';
      default:
        return 'Suvichar';
    }
  }

  /// How many lines each slot is allotted in this design — the line count it
  /// was authored with. [FixedTemplateCanvas] clamps to these so text longer
  /// than the design expects ellipsizes instead of growing downwards into the
  /// next slot.
  ///
  /// Computed once per template: the preview cards ask for this on every build,
  /// and rebuilding a map of split strings each time a card scrolls into view is
  /// pure waste — the authored line counts never change.
  Map<String, int>? _lineLimits;
  Map<String, int> get lineLimits => _lineLimits ??= {
        for (final t in texts)
          t.id: t.text.isEmpty ? 1 : t.text.split('\n').length,
      };

  // Preview designs are read-only, so unlike [design] they can be shared rather
  // than deep-copied on every build. Cached per language because the name
  // slot's placeholder is localized.
  StatusDesign? _preview;
  String? _previewLang;

  /// A shared, **read-only** snapshot for preview cards. Never hand this to an
  /// editor — use [design], which returns an independent copy that's safe to
  /// mutate.
  StatusDesign previewDesign() {
    if (_preview != null && _previewLang == S.lang.value) return _preview!;
    _previewLang = S.lang.value;
    return _preview = design();
  }

  /// A fresh, independently mutable copy of the design (so editing one
  /// session never leaks into the shared prototypes).
  ///
  /// The name slot's placeholder is resolved here rather than baked into the
  /// static list above, so it follows the app's current language — including
  /// after the user switches it.
  StatusDesign design({bool includeHiddenPhoto = false}) => StatusDesign(
        background: background,
        texts: texts.map((t) {
          final copy = t.copyWith();
          if (t.id == nameSlotId && copy.text.isEmpty) {
            copy.text = S.t('name_placeholder');
          }
          return copy;
        }).toList(),
        images: [
          if (photo != null && (showPlaceholder || includeHiddenPhoto))
            photo!.copyWith(),
        ],
        elements: elements.map((e) => e.copyWith()).toList(),
        frame: frame,
        frameColor: frameColor,
        frameWidth: frameWidth,
      );
}

/// Every template belonging to [theme], in authoring order. Grouped once and
/// reused — the Search tab asks for each theme's list on every build.
final Map<String, List<FixedTemplate>> _byTheme = () {
  final map = <String, List<FixedTemplate>>{};
  for (final t in kFixedTemplates) {
    map.putIfAbsent(t.theme, () => <FixedTemplate>[]).add(t);
  }
  return map;
}();

List<FixedTemplate> fixedTemplatesForTheme(String theme) =>
    _byTheme[theme] ?? const [];

/// Re-scales a design whose coordinates were authored for a [from]-sized canvas
/// (e.g. [kFixedCanvasSize]) onto a live editor canvas of size [to].
///
/// The free editor's canvas is sized by the device (a 9:16 box in whatever
/// space is left over), while these designs use fixed 360×640 coordinates. On a
/// narrower canvas the bottom-most slots would fall off the edge, and on a
/// wider one the composition would sit too high and too small — so everything
/// gets multiplied by one scalar. Both spaces are 9:16, so width and height
/// give the same factor and the design keeps its proportions exactly.
///
/// Scaling `scale` alongside `position` is what preserves apparent size:
/// on-canvas objects render at their natural box size times `scale`, so the
/// same factor applied to both is a uniform zoom of the whole composition.
StatusDesign scaleDesignToCanvas(StatusDesign d, Size from, Size to) {
  if (from.width <= 0 || to.width <= 0) return d;
  final s = to.width / from.width;
  if ((s - 1.0).abs() < 0.001) return d;

  return StatusDesign(
    background: d.background,
    texts: d.texts
        .map((t) => t.copyWith(position: t.position * s, scale: t.scale * s))
        .toList(),
    images: d.images
        .map((i) => i.copyWith(position: i.position * s, scale: i.scale * s))
        .toList(),
    elements: d.elements
        .map((e) => e.copyWith(position: e.position * s, scale: e.scale * s))
        .toList(),
    frame: d.frame,
    frameColor: d.frameColor,
    frameWidth: d.frameWidth,
  );
}

// ---------------------------------------------------------------------------
// Layout helpers
//
// Every object's stored `position` is the top-left of its *unscaled* box, and
// `scale` pivots on that box's own center — exactly the semantics the free
// editor's TransformableObject uses, so a design authored here reopens there
// unchanged. That makes raw coordinates awkward to hand-author (a scaled
// object's visible edge is inset from its position), so the helpers below take
// the *visible* geometry a designer actually cares about and convert.
//
// Each design's comments record the vertical band (in canvas px, out of 640)
// that every slot occupies, so it's checkable at a glance that nothing
// collides.
// ---------------------------------------------------------------------------

/// Canvas center line.
const double _cx = 360 / 2;

/// Padding [FixedTemplateCanvas] and TransformableObject both put around an
/// object's content before scaling.
const double _objPad = 6;

/// A text slot's block is a fixed 300-wide box; with the 6px object padding
/// that's 312 total, so this dx centers it on the canvas.
const double _textX = (360 - (300 + 2 * _objPad)) / 2;

/// Vertical space a text slot occupies at [lines] lines — 12px object padding
/// plus 16px of the block's own vertical padding, plus the line boxes.
double textSlotHeight({
  required double fontSize,
  required double lineHeight,
  required int lines,
}) =>
    2 * _objPad + 16 + lines * fontSize * lineHeight;

TextObject _slot({
  required String id,
  required String text,
  required String font,
  required double size,
  required Color color,
  required double top,
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
      position: Offset(_textX, top),
    );

/// The slot for the user's own name. Ships with empty text so
/// [FixedTemplate.design] can fill in the language-appropriate placeholder.
TextObject _nameSlot({
  required String id,
  required String font,
  required double size,
  required Color color,
  required double top,
  bool bold = false,
  double letterSpacing = 0,
}) =>
    _slot(
      id: id,
      text: '',
      font: font,
      size: size,
      color: color,
      top: top,
      bold: bold,
      letterSpacing: letterSpacing,
    );

/// A photo slot expressed the way it's designed: horizontally centered, with
/// its *visible* top edge at [top] and visible width [width].
ImageObject _photoSlot({
  required String id,
  required ImageShape shape,
  required double top,
  required double width,
  Color frameColor = Colors.white,
  bool framed = true,
}) {
  final base = baseSizeForImageShape(shape);
  final boxW = base.width + 2 * _objPad;
  final boxH = base.height + 2 * _objPad;
  final scale = width / boxW;
  final visH = boxH * scale;
  return ImageObject(
    id: id,
    path: '',
    shape: shape,
    // Undo the center-pivoted scale's inset so the *visible* box lands where
    // the design asks.
    position: Offset(
      _cx - width / 2 - (boxW - width) / 2,
      top - (boxH - visH) / 2,
    ),
    scale: scale,
    isPlaceholder: true,
    framed: framed,
    frameColor: frameColor,
  );
}

/// A centered hairline divider whose stroke sits at [centerY]. The line is
/// drawn across the middle of a 160×80 element box, so only its center matters.
ElementObject _divider({
  required String id,
  required Color color,
  required double centerY,
  double width = 90,
}) {
  const boxW = 160 + 2 * _objPad;
  const boxH = 80 + 2 * _objPad;
  final scale = width / boxW;
  return ElementObject(
    id: id,
    shape: ElementShape.line,
    color: color,
    position: Offset(_cx - boxW / 2, centerY - boxH / 2),
    scale: scale,
  );
}

/// The curated set shown in the Create tab. Deliberately elegant and calm
/// rather than cartoonish, and weighted towards morning greetings and wishes.
final List<FixedTemplate> kFixedTemplates = [
  // =========================================================================
  // MORNING
  // =========================================================================

  // Warm Suprabhat blessing
  FixedTemplate(
    id: 'fx_suprabhat',
    name: 'Suprabhat',
    theme: 'morning',
    background: const BackgroundState(
      gradientColors: [Color(0xFFFFE9C7), Color(0xFFFFB74D)],
      motif: TemplateMotif.sunrise,
      motifColor: Color(0xFF9C5700),
    ),
    frame: StatusFrame.thin,
    frameColor: const Color(0xCC8D5524),
    nameSlotId: 'fx_supra_name',
    photo: _photoSlot(
      id: 'fx_supra_photo',
      shape: ImageShape.circle,
      top: 300, // 300–428
      width: 128,
    ),
    texts: [
      _slot(
        id: 'fx_supra_title',
        text: 'सुप्रभात',
        font: 'Rozha One',
        size: 42,
        color: const Color(0xFF7B3F00),
        top: 70, // 70–153
      ),
      _slot(
        id: 'fx_supra_body',
        text: 'हर सुबह एक नई शुरुआत है,\nमुस्कुराइए और आगे बढ़िए।',
        font: 'Hind',
        size: 24,
        color: const Color(0xFF5D3A00),
        top: 180, // 180–282
        bold: false,
        lineHeight: 1.55,
      ),
      _slot(
        id: 'fx_supra_caption',
        text: 'आपका दिन शुभ हो',
        font: 'Kalam',
        size: 20,
        color: const Color(0xB35D3A00),
        top: 455, // 455–509
        bold: false,
      ),
      _nameSlot(
        id: 'fx_supra_name',
        font: 'Hind',
        size: 15,
        color: const Color(0x995D3A00),
        top: 535, // 535–578
      ),
    ],
  ),

  // Elegant English good-morning card
  FixedTemplate(
    id: 'fx_morning_gold',
    name: 'Golden Morning',
    theme: 'morning',
    background: const BackgroundState(
      gradientColors: [Color(0xFFFFF8EC), Color(0xFFF0CE8E)],
      motif: TemplateMotif.sunrise,
      motifColor: Color(0xFFB07B2E),
    ),
    frame: StatusFrame.inset,
    frameColor: const Color(0xFFB07B2E),
    nameSlotId: 'fx_mgold_name',
    photo: _photoSlot(
      id: 'fx_mgold_photo',
      shape: ImageShape.circle,
      top: 330, // 330–470
      width: 140,
      frameColor: const Color(0xFFFFF8EC),
    ),
    texts: [
      _slot(
        id: 'fx_mgold_title',
        text: 'Good Morning',
        font: 'Playfair Display',
        size: 40,
        color: const Color(0xFF6B4A16),
        top: 90, // 90–170
      ),
      _slot(
        id: 'fx_mgold_body',
        text: 'Every sunrise is a new\ninvitation to begin again.',
        font: 'Montserrat',
        size: 20,
        color: const Color(0xFF7A5A24),
        top: 210, // 210–300
        bold: false,
        lineHeight: 1.55,
      ),
      _nameSlot(
        id: 'fx_mgold_name',
        font: 'Montserrat',
        size: 12,
        color: const Color(0x996B4A16),
        top: 510, // 510–554
        letterSpacing: 3,
      ),
    ],
  ),

  // Chai / coffee morning
  FixedTemplate(
    id: 'fx_morning_chai',
    name: 'Morning Chai',
    theme: 'morning',
    background: const BackgroundState(
      gradientColors: [Color(0xFFF3E7D8), Color(0xFFCBAe8F)],
      motif: TemplateMotif.coffee,
      motifColor: Color(0xFF5D4037),
    ),
    nameSlotId: 'fx_chai_name',
    photo: _photoSlot(
      id: 'fx_chai_photo',
      shape: ImageShape.roundedRectangle,
      top: 300, // 300–507
      width: 170,
    ),
    texts: [
      _slot(
        id: 'fx_chai_title',
        text: 'शुभ प्रभात',
        font: 'Rozha One',
        size: 38,
        color: const Color(0xFF4E342E),
        top: 70, // 70–147
      ),
      _slot(
        id: 'fx_chai_body',
        text: 'चाय की चुस्की के साथ\nदिन की शुरुआत कीजिए।',
        font: 'Hind',
        size: 22,
        color: const Color(0xFF5D4037),
        top: 180, // 180–278
        bold: false,
        lineHeight: 1.6,
      ),
      _nameSlot(
        id: 'fx_chai_name',
        font: 'Kalam',
        size: 18,
        color: const Color(0xB34E342E),
        top: 540, // 540–587
      ),
    ],
  ),

  // Calm botanical morning
  FixedTemplate(
    id: 'fx_morning_botanical',
    name: 'Rise & Shine',
    theme: 'morning',
    background: const BackgroundState(
      gradientColors: [Color(0xFFEAF4E7), Color(0xFFB6D3AE)],
      motif: TemplateMotif.botanical,
      motifColor: Color(0xFF3F6B3A),
    ),
    frame: StatusFrame.thin,
    frameColor: const Color(0x993F6B3A),
    nameSlotId: 'fx_mbot_name',
    photo: _photoSlot(
      id: 'fx_mbot_photo',
      shape: ImageShape.circle,
      top: 350, // 350–480
      width: 130,
    ),
    texts: [
      _slot(
        id: 'fx_mbot_title',
        text: 'Rise & Shine',
        font: 'Caveat',
        size: 40,
        color: const Color(0xFF2E5A2A),
        top: 110, // 110–190
        bold: false,
      ),
      _slot(
        id: 'fx_mbot_body',
        text: 'A calm mind is the\nbest way to start.',
        font: 'Montserrat',
        size: 20,
        color: const Color(0xFF3F6B3A),
        top: 230, // 230–318
        bold: false,
        lineHeight: 1.5,
      ),
      _nameSlot(
        id: 'fx_mbot_name',
        font: 'Montserrat',
        size: 12,
        color: const Color(0x992E5A2A),
        top: 520, // 520–564
        letterSpacing: 3,
      ),
    ],
  ),

  // Traditional lotus Suprabhat
  FixedTemplate(
    id: 'fx_suprabhat_lotus',
    name: 'Kamal Suprabhat',
    theme: 'morning',
    background: const BackgroundState(
      gradientColors: [Color(0xFFFDE7EF), Color(0xFFF6C8A8)],
      motif: TemplateMotif.lotus,
      motifColor: Color(0xFFA5285C),
    ),
    frame: StatusFrame.rounded,
    frameColor: const Color(0x66A5285C),
    nameSlotId: 'fx_lotus_name',
    photo: _photoSlot(
      id: 'fx_lotus_photo',
      shape: ImageShape.circle,
      top: 300, // 300–440
      width: 140,
    ),
    texts: [
      _slot(
        id: 'fx_lotus_title',
        text: 'सुप्रभात',
        font: 'Yatra One',
        size: 40,
        color: const Color(0xFF8E2350),
        top: 60, // 60–140
      ),
      _slot(
        id: 'fx_lotus_body',
        text: 'ईश्वर आपका दिन\nमंगलमय करे।',
        font: 'Tiro Devanagari Hindi',
        size: 24,
        color: const Color(0xFF7A3B2E),
        top: 175, // 175–277
        bold: false,
        lineHeight: 1.55,
      ),
      _nameSlot(
        id: 'fx_lotus_name',
        font: 'Kalam',
        size: 18,
        color: const Color(0xB38E2350),
        top: 480, // 480–527
      ),
    ],
  ),

  // Minimal lowercase morning
  FixedTemplate(
    id: 'fx_morning_minimal',
    name: 'Quiet Morning',
    theme: 'morning',
    background: const BackgroundState(
      gradientColors: [Color(0xFFFAF9F6), Color(0xFFE8E2D4)],
      motif: TemplateMotif.dots,
      motifColor: Color(0xFFA69B84),
    ),
    nameSlotId: 'fx_mmin_name',
    photo: _photoSlot(
      id: 'fx_mmin_photo',
      shape: ImageShape.circle,
      top: 70, // 70–190
      width: 120,
      frameColor: const Color(0xFF6E6552),
    ),
    texts: [
      _slot(
        id: 'fx_mmin_title',
        text: 'good morning',
        font: 'Montserrat',
        size: 26,
        color: const Color(0xFF4A4234),
        top: 250, // 250–312
        letterSpacing: 5,
      ),
      _slot(
        id: 'fx_mmin_body',
        text: '“Today is a fresh start.”',
        font: 'Playfair Display',
        size: 22,
        color: const Color(0xFF6E6552),
        top: 350, // 350–440 (up to 2 lines)
        bold: false,
        lineHeight: 1.4,
      ),
      _nameSlot(
        id: 'fx_mmin_name',
        font: 'Montserrat',
        size: 11,
        color: const Color(0x994A4234),
        top: 480, // 480–522
        letterSpacing: 3,
      ),
    ],
  ),

  // Bold sunrise poster
  FixedTemplate(
    id: 'fx_morning_bold',
    name: 'Sunrise Poster',
    theme: 'morning',
    background: const BackgroundState(
      gradientColors: [Color(0xFFFF8A3D), Color(0xFFFFC94D)],
      motif: TemplateMotif.sunrise,
      motifColor: Color(0xFFFFF3D6),
    ),
    frame: StatusFrame.corners,
    frameColor: const Color(0xFFFFF3D6),
    nameSlotId: 'fx_mbold_name',
    photo: _photoSlot(
      id: 'fx_mbold_photo',
      shape: ImageShape.circle,
      top: 390, // 390–520
      width: 130,
      frameColor: const Color(0xFFFFF3D6),
    ),
    elements: [
      _divider(
        id: 'fx_mbold_line',
        color: const Color(0xCCFFF3D6),
        centerY: 245,
      ),
    ],
    texts: [
      _slot(
        id: 'fx_mbold_title',
        text: 'GOOD MORNING',
        font: 'Bebas Neue',
        size: 44,
        color: Colors.white,
        top: 130, // 130–215
        letterSpacing: 3,
      ),
      _slot(
        id: 'fx_mbold_body',
        text: 'Make today amazing.',
        font: 'Montserrat',
        size: 20,
        color: const Color(0xFFFFF3D6),
        top: 280, // 280–360 (up to 2 lines)
        bold: false,
      ),
      _nameSlot(
        id: 'fx_mbold_name',
        font: 'Montserrat',
        size: 12,
        color: const Color(0xCCFFF3D6),
        top: 550, // 550–594
        letterSpacing: 3,
      ),
    ],
  ),

  // =========================================================================
  // WISHES
  // =========================================================================

  // Elegant birthday wish
  FixedTemplate(
    id: 'fx_birthday',
    name: 'Birthday Wish',
    theme: 'wishes',
    background: const BackgroundState(
      gradientColors: [Color(0xFF2A1140), Color(0xFF7B2CBF)],
      motif: TemplateMotif.confetti,
      motifColor: Color(0xFFFFD54F),
    ),
    frame: StatusFrame.corners,
    frameColor: const Color(0xFFFFD54F),
    showPlaceholder: true,
    nameSlotId: 'fx_bday_name',
    photo: _photoSlot(
      id: 'fx_bday_photo',
      shape: ImageShape.circle,
      top: 330, // 330–510
      width: 180,
      frameColor: const Color(0xFFFFD54F),
    ),
    texts: [
      _slot(
        id: 'fx_bday_title',
        text: 'Happy Birthday',
        font: 'Dancing Script',
        size: 44,
        color: const Color(0xFFFFD54F),
        top: 70, // 70–155
        bold: false,
      ),
      _nameSlot(
        id: 'fx_bday_name',
        font: 'Montserrat',
        size: 26,
        color: Colors.white,
        top: 175, // 175–237
        bold: true,
      ),
      _slot(
        id: 'fx_bday_caption',
        text: 'ढेर सारी शुभकामनाएँ',
        font: 'Hind',
        size: 18,
        color: const Color(0xCCFFFFFF),
        top: 250, // 250–301
        bold: false,
      ),
    ],
  ),

  // Festive Diwali greeting
  FixedTemplate(
    id: 'fx_festive_glow',
    name: 'Festive Glow',
    theme: 'wishes',
    background: const BackgroundState(
      gradientColors: [Color(0xFF6E0F12), Color(0xFFC79A3A)],
      motif: TemplateMotif.diya,
      motifColor: Color(0xFFFFE9B0),
    ),
    frame: StatusFrame.doubleLine,
    frameColor: const Color(0xFFFFE9B0),
    nameSlotId: 'fx_fest_name',
    photo: _photoSlot(
      id: 'fx_fest_photo',
      shape: ImageShape.circle,
      top: 25, // 25–145
      width: 120,
      frameColor: const Color(0xFFFFE9B0),
    ),
    texts: [
      _slot(
        id: 'fx_fest_title',
        text: 'शुभ दीपावली',
        font: 'Rozha One',
        size: 38,
        color: const Color(0xFFFFE9B0),
        top: 160, // 160–237
      ),
      _slot(
        id: 'fx_fest_body',
        text: 'दीपों की रोशनी से आपका जीवन\nसदा जगमगाता रहे।',
        font: 'Tiro Devanagari Hindi',
        size: 22,
        color: const Color(0xFFFFF3D6),
        top: 280, // 280–378
        bold: false,
        lineHeight: 1.6,
      ),
      _slot(
        id: 'fx_fest_caption',
        text: 'सपरिवार शुभकामनाएँ',
        font: 'Hind',
        size: 16,
        color: const Color(0xCCFFE9B0),
        top: 450, // 450–520 (up to 2 lines)
        bold: false,
      ),
      _nameSlot(
        id: 'fx_fest_name',
        font: 'Hind',
        size: 15,
        color: const Color(0x99FFE9B0),
        top: 545, // 545–588
      ),
    ],
  ),

  // Anniversary
  FixedTemplate(
    id: 'fx_anniversary',
    name: 'Anniversary',
    theme: 'wishes',
    background: const BackgroundState(
      gradientColors: [Color(0xFF7A1B3D), Color(0xFFD9A05B)],
      motif: TemplateMotif.roses,
      motifColor: Color(0xFFFFE0E6),
    ),
    frame: StatusFrame.rounded,
    frameColor: const Color(0xFFFFE0E6),
    nameSlotId: 'fx_anniv_name',
    photo: _photoSlot(
      id: 'fx_anniv_photo',
      shape: ImageShape.heart,
      top: 370, // 370–554
      width: 200,
      frameColor: const Color(0xFFFFE0E6),
    ),
    texts: [
      _slot(
        id: 'fx_anniv_title',
        text: 'Happy Anniversary',
        font: 'Dancing Script',
        size: 38,
        color: const Color(0xFFFFE0E6),
        top: 70, // 70–147
        bold: false,
      ),
      _nameSlot(
        id: 'fx_anniv_name',
        font: 'Montserrat',
        size: 22,
        color: Colors.white,
        top: 170, // 170–227
        bold: true,
      ),
      _slot(
        id: 'fx_anniv_body',
        text: 'शादी की सालगिरह\nमुबारक हो!',
        font: 'Hind',
        size: 20,
        color: const Color(0xE6FFE0E6),
        top: 250, // 250–340
        bold: false,
        lineHeight: 1.55,
      ),
    ],
  ),

  // New Year
  FixedTemplate(
    id: 'fx_new_year',
    name: 'New Year',
    theme: 'wishes',
    background: const BackgroundState(
      gradientColors: [Color(0xFF0B1437), Color(0xFF3E2B6B)],
      motif: TemplateMotif.sparkles,
      motifColor: Color(0xFFF2CE6B),
    ),
    frame: StatusFrame.corners,
    frameColor: const Color(0xFFF2CE6B),
    nameSlotId: 'fx_ny_name',
    photo: _photoSlot(
      id: 'fx_ny_photo',
      shape: ImageShape.circle,
      top: 360, // 360–500
      width: 140,
      frameColor: const Color(0xFFF2CE6B),
    ),
    texts: [
      _slot(
        id: 'fx_ny_title',
        text: 'Happy New Year',
        font: 'Cinzel',
        size: 34,
        color: const Color(0xFFF2CE6B),
        top: 120, // 120–192
      ),
      _slot(
        id: 'fx_ny_body',
        text: 'नया साल आपके लिए\nखुशियाँ लेकर आए।',
        font: 'Hind',
        size: 22,
        color: const Color(0xE6FFFFFF),
        top: 230, // 230–328
        bold: false,
        lineHeight: 1.6,
      ),
      _nameSlot(
        id: 'fx_ny_name',
        font: 'Montserrat',
        size: 13,
        color: const Color(0xCCF2CE6B),
        top: 540, // 540–585
        letterSpacing: 3,
      ),
    ],
  ),

  // Holi
  FixedTemplate(
    id: 'fx_holi',
    name: 'Holi Wishes',
    theme: 'wishes',
    background: const BackgroundState(
      gradientColors: [Color(0xFFFFF6E9), Color(0xFFFFD1A8)],
      motif: TemplateMotif.holi,
      motifColor: Color(0xFF6A1B9A),
    ),
    frame: StatusFrame.thin,
    frameColor: const Color(0x996A1B9A),
    nameSlotId: 'fx_holi_name',
    photo: _photoSlot(
      id: 'fx_holi_photo',
      shape: ImageShape.roundedRectangle,
      top: 320, // 320–515
      width: 160,
    ),
    texts: [
      _slot(
        id: 'fx_holi_title',
        text: 'शुभ होली',
        font: 'Rozha One',
        size: 40,
        color: const Color(0xFF6A1B9A),
        top: 90, // 90–170
      ),
      _slot(
        id: 'fx_holi_body',
        text: 'रंगों का त्योहार आपके\nजीवन में खुशियाँ भरे।',
        font: 'Tiro Devanagari Hindi',
        size: 22,
        color: const Color(0xFF7B3F00),
        top: 200, // 200–298
        bold: false,
        lineHeight: 1.6,
      ),
      _nameSlot(
        id: 'fx_holi_name',
        font: 'Hind',
        size: 15,
        color: const Color(0x996A1B9A),
        top: 545, // 545–588
      ),
    ],
  ),

  // Raksha Bandhan
  FixedTemplate(
    id: 'fx_rakhi',
    name: 'Raksha Bandhan',
    theme: 'wishes',
    background: const BackgroundState(
      gradientColors: [Color(0xFF9B1B30), Color(0xFFE0A94C)],
      motif: TemplateMotif.rakhi,
      motifColor: Color(0xFFFFF3D6),
    ),
    frame: StatusFrame.doubleLine,
    frameColor: const Color(0xFFFFF3D6),
    nameSlotId: 'fx_rakhi_name',
    photo: _photoSlot(
      id: 'fx_rakhi_photo',
      shape: ImageShape.circle,
      top: 305, // 305–455
      width: 150,
      frameColor: const Color(0xFFFFF3D6),
    ),
    texts: [
      _slot(
        id: 'fx_rakhi_title',
        text: 'शुभ रक्षाबंधन',
        font: 'Rozha One',
        size: 36,
        color: const Color(0xFFFFF3D6),
        top: 80, // 80–155
      ),
      _slot(
        id: 'fx_rakhi_body',
        text: 'भाई-बहन का प्यार\nसदा बना रहे।',
        font: 'Hind',
        size: 22,
        color: const Color(0xF2FFF3D6),
        top: 185, // 185–283
        bold: false,
        lineHeight: 1.6,
      ),
      _nameSlot(
        id: 'fx_rakhi_name',
        font: 'Kalam',
        size: 18,
        color: const Color(0xCCFFF3D6),
        top: 490, // 490–537
      ),
    ],
  ),

  // Congratulations
  FixedTemplate(
    id: 'fx_congrats',
    name: 'Congratulations',
    theme: 'wishes',
    background: const BackgroundState(
      gradientColors: [Color(0xFF0F4C4A), Color(0xFF6FC5A8)],
      motif: TemplateMotif.confetti,
      motifColor: Color(0xFFEAFBF4),
    ),
    frame: StatusFrame.inset,
    frameColor: const Color(0xFFEAFBF4),
    nameSlotId: 'fx_cong_name',
    photo: _photoSlot(
      id: 'fx_cong_photo',
      shape: ImageShape.circle,
      top: 390, // 390–540
      width: 150,
      frameColor: const Color(0xFFEAFBF4),
    ),
    texts: [
      _slot(
        id: 'fx_cong_title',
        text: 'Congratulations!',
        font: 'Playfair Display',
        size: 32,
        color: const Color(0xFFEAFBF4),
        top: 100, // 100–170
      ),
      _nameSlot(
        id: 'fx_cong_name',
        font: 'Montserrat',
        size: 24,
        color: Colors.white,
        top: 195, // 195–254
        bold: true,
      ),
      _slot(
        id: 'fx_cong_body',
        text: 'Wishing you continued\nsuccess ahead.',
        font: 'Montserrat',
        size: 18,
        color: const Color(0xE6EAFBF4),
        top: 280, // 280–362
        bold: false,
        lineHeight: 1.5,
      ),
    ],
  ),

  // Wedding
  FixedTemplate(
    id: 'fx_wedding',
    name: 'Shubh Vivah',
    theme: 'wishes',
    background: const BackgroundState(
      gradientColors: [Color(0xFFFFFBF2), Color(0xFFE8CFA0)],
      motif: TemplateMotif.botanical,
      motifColor: Color(0xFF8C6A2F),
    ),
    frame: StatusFrame.rounded,
    frameColor: const Color(0xFF8C6A2F),
    nameSlotId: 'fx_wed_name',
    photo: _photoSlot(
      id: 'fx_wed_photo',
      shape: ImageShape.heart,
      top: 315, // 315–490
      width: 190,
    ),
    texts: [
      _slot(
        id: 'fx_wed_title',
        text: 'शुभ विवाह',
        font: 'Rozha One',
        size: 38,
        color: const Color(0xFF7A4E14),
        top: 80, // 80–157
      ),
      _slot(
        id: 'fx_wed_body',
        text: 'आपके नए जीवन की\nहार्दिक शुभकामनाएँ।',
        font: 'Tiro Devanagari Hindi',
        size: 22,
        color: const Color(0xFF8C6A2F),
        top: 190, // 190–288
        bold: false,
        lineHeight: 1.6,
      ),
      _nameSlot(
        id: 'fx_wed_name',
        font: 'Hind',
        size: 15,
        color: const Color(0x997A4E14),
        top: 525, // 525–568
      ),
    ],
  ),

  // Thank you
  FixedTemplate(
    id: 'fx_thank_you',
    name: 'Thank You',
    theme: 'wishes',
    background: const BackgroundState(
      gradientColors: [Color(0xFFF6F2FB), Color(0xFFD8CBEC)],
      motif: TemplateMotif.dots,
      motifColor: Color(0xFF5E4B8B),
    ),
    frame: StatusFrame.thin,
    frameColor: const Color(0x995E4B8B),
    nameSlotId: 'fx_thx_name',
    photo: _photoSlot(
      id: 'fx_thx_photo',
      shape: ImageShape.circle,
      top: 380, // 380–510
      width: 130,
      frameColor: const Color(0xFFF6F2FB),
    ),
    texts: [
      _slot(
        id: 'fx_thx_title',
        text: 'Thank You',
        font: 'Playfair Display',
        size: 36,
        color: const Color(0xFF432F6E),
        top: 150, // 150–225
      ),
      _slot(
        id: 'fx_thx_body',
        text: 'Grateful for your love\nand support always.',
        font: 'Montserrat',
        size: 18,
        color: const Color(0xFF5E4B8B),
        top: 265, // 265–349
        bold: false,
        lineHeight: 1.55,
      ),
      _nameSlot(
        id: 'fx_thx_name',
        font: 'Montserrat',
        size: 12,
        color: const Color(0x99432F6E),
        top: 545, // 545–589
        letterSpacing: 3,
      ),
    ],
  ),

  // =========================================================================
  // NIGHT
  // =========================================================================

  FixedTemplate(
    id: 'fx_shubh_ratri',
    name: 'Shubh Ratri',
    theme: 'night',
    background: const BackgroundState(
      gradientColors: [Color(0xFF0D1B3E), Color(0xFF33235E)],
      motif: TemplateMotif.moonStars,
      motifColor: Color(0xFFFFF3B0),
    ),
    nameSlotId: 'fx_night_name',
    photo: _photoSlot(
      id: 'fx_night_photo',
      shape: ImageShape.circle,
      top: 355, // 355–465
      width: 110,
      frameColor: const Color(0xFFFFF3B0),
    ),
    texts: [
      _slot(
        id: 'fx_night_title',
        text: 'शुभ रात्रि',
        font: 'Baloo 2',
        size: 40,
        color: const Color(0xFFFFF3B0),
        top: 110, // 110–190
      ),
      _slot(
        id: 'fx_night_body',
        text: 'दिन भर की थकान भूल जाइए,\nचाँदनी में सुकून पाइए।',
        font: 'Mukta',
        size: 22,
        color: const Color(0xE6FFFFFF),
        top: 235, // 235–333
        bold: false,
        lineHeight: 1.6,
      ),
      _slot(
        id: 'fx_night_caption',
        text: 'मीठे सपने',
        font: 'Kalam',
        size: 22,
        color: const Color(0xB3FFF3B0),
        top: 490, // 490–547
        bold: false,
      ),
      _nameSlot(
        id: 'fx_night_name',
        font: 'Hind',
        size: 14,
        color: const Color(0x99FFF3B0),
        top: 570, // 570–611
      ),
    ],
  ),

  FixedTemplate(
    id: 'fx_good_night_en',
    name: 'Sweet Dreams',
    theme: 'night',
    background: const BackgroundState(
      gradientColors: [Color(0xFF141B33), Color(0xFF4A3B7A)],
      motif: TemplateMotif.moonStars,
      motifColor: Color(0xFFDCD3FF),
    ),
    frame: StatusFrame.corners,
    frameColor: const Color(0xFFDCD3FF),
    nameSlotId: 'fx_gnen_name',
    photo: _photoSlot(
      id: 'fx_gnen_photo',
      shape: ImageShape.circle,
      top: 370, // 370–500
      width: 130,
      frameColor: const Color(0xFFDCD3FF),
    ),
    texts: [
      _slot(
        id: 'fx_gnen_title',
        text: 'Good Night',
        font: 'Playfair Display',
        size: 38,
        color: const Color(0xFFDCD3FF),
        top: 130, // 130–207
      ),
      _slot(
        id: 'fx_gnen_body',
        text: 'May your dreams be\nas sweet as you are.',
        font: 'Montserrat',
        size: 19,
        color: const Color(0xE6FFFFFF),
        top: 250, // 250–337
        bold: false,
        lineHeight: 1.55,
      ),
      _nameSlot(
        id: 'fx_gnen_name',
        font: 'Montserrat',
        size: 12,
        color: const Color(0xCCDCD3FF),
        top: 540, // 540–584
        letterSpacing: 3,
      ),
    ],
  ),

  // =========================================================================
  // DEVOTIONAL
  // =========================================================================

  FixedTemplate(
    id: 'fx_bhakti',
    name: 'Bhakti Blessing',
    theme: 'devotional',
    background: const BackgroundState(
      gradientColors: [Color(0xFFE65100), Color(0xFF7B1113)],
      motif: TemplateMotif.om,
      motifColor: Color(0xFFFFE082),
    ),
    frame: StatusFrame.rounded,
    frameColor: const Color(0xFFFFE082),
    nameSlotId: 'fx_bhakti_name',
    photo: _photoSlot(
      id: 'fx_bhakti_photo',
      shape: ImageShape.circle,
      top: 75, // 75–205
      width: 130,
      frameColor: const Color(0xFFFFE082),
    ),
    texts: [
      _slot(
        id: 'fx_bhakti_main',
        text: 'ईश्वर की कृपा सदा\nआप पर बनी रहे',
        font: 'Tiro Devanagari Hindi',
        size: 30,
        color: const Color(0xFFFFE9B0),
        top: 240, // 240–358
        lineHeight: 1.5,
      ),
      _slot(
        id: 'fx_bhakti_caption',
        text: 'जय श्री हरि',
        font: 'Yatra One',
        size: 22,
        color: const Color(0xCCFFE082),
        top: 430, // 430–487
        bold: false,
      ),
      _nameSlot(
        id: 'fx_bhakti_name',
        font: 'Hind',
        size: 15,
        color: const Color(0x99FFE082),
        top: 530, // 530–573
      ),
    ],
  ),

  FixedTemplate(
    id: 'fx_ganesh',
    name: 'Shri Ganesh',
    theme: 'devotional',
    background: const BackgroundState(
      gradientColors: [Color(0xFFFF7A18), Color(0xFFAF002D)],
      motif: TemplateMotif.ganesh,
      motifColor: Color(0xFFFFE9B0),
    ),
    frame: StatusFrame.doubleLine,
    frameColor: const Color(0xFFFFE9B0),
    nameSlotId: 'fx_gan_name',
    photo: _photoSlot(
      id: 'fx_gan_photo',
      shape: ImageShape.circle,
      top: 360, // 360–490
      width: 130,
      frameColor: const Color(0xFFFFE9B0),
    ),
    texts: [
      _slot(
        id: 'fx_gan_title',
        text: 'जय श्री गणेश',
        font: 'Rozha One',
        size: 36,
        color: const Color(0xFFFFE9B0),
        top: 120, // 120–195
      ),
      _slot(
        id: 'fx_gan_body',
        text: 'विघ्नहर्ता आपके सभी\nकष्ट दूर करें।',
        font: 'Tiro Devanagari Hindi',
        size: 22,
        color: const Color(0xF2FFF3D6),
        top: 230, // 230–328
        bold: false,
        lineHeight: 1.6,
      ),
      _nameSlot(
        id: 'fx_gan_name',
        font: 'Hind',
        size: 15,
        color: const Color(0xB3FFE9B0),
        top: 530, // 530–573
      ),
    ],
  ),

  // =========================================================================
  // LOVE & MEMORIES
  // =========================================================================

  FixedTemplate(
    id: 'fx_love_note',
    name: 'Love Note',
    theme: 'love',
    background: const BackgroundState(
      gradientColors: [Color(0xFFFFF0F3), Color(0xFFF8C1CF)],
      motif: TemplateMotif.hearts,
      motifColor: Color(0xFFD81B60),
    ),
    frame: StatusFrame.rounded,
    frameColor: const Color(0x66D81B60),
    showPlaceholder: true,
    nameSlotId: 'fx_love_name',
    photo: _photoSlot(
      id: 'fx_love_photo',
      shape: ImageShape.heart,
      top: 85, // 85–278
      width: 210,
    ),
    texts: [
      _slot(
        id: 'fx_love_main',
        text: 'Every love story is beautiful,\nbut ours is my favourite.',
        font: 'Dancing Script',
        size: 30,
        color: const Color(0xFFAD1457),
        top: 320, // 320–429
        bold: false,
        lineHeight: 1.35,
      ),
      _nameSlot(
        id: 'fx_love_name',
        font: 'Montserrat',
        size: 13,
        color: const Color(0x99AD1457),
        top: 470, // 470–515
        letterSpacing: 4,
      ),
    ],
  ),

  FixedTemplate(
    id: 'fx_photo_memory',
    name: 'Photo Memory',
    theme: 'love',
    background: const BackgroundState(
      gradientColors: [Color(0xFFFBF7EF), Color(0xFFEADFC8)],
      motif: TemplateMotif.botanical,
      motifColor: Color(0xFF7C8F6F),
    ),
    frame: StatusFrame.inset,
    frameColor: const Color(0xFF8A7B5C),
    showPlaceholder: true,
    nameSlotId: 'fx_memory_name',
    photo: _photoSlot(
      id: 'fx_memory_photo',
      shape: ImageShape.circle,
      top: 80, // 80–280
      width: 200,
    ),
    texts: [
      _slot(
        id: 'fx_memory_main',
        text: 'Some moments stay\nin the heart forever.',
        font: 'Caveat',
        size: 30,
        color: const Color(0xFF4E342E),
        top: 320, // 320–426
        bold: false,
      ),
      _nameSlot(
        id: 'fx_memory_name',
        font: 'Montserrat',
        size: 12,
        color: const Color(0x995D4037),
        top: 470, // 470–514
        letterSpacing: 2.5,
      ),
    ],
  ),

  // =========================================================================
  // QUOTES
  // =========================================================================

  FixedTemplate(
    id: 'fx_royal_quote',
    name: 'Royal Quote',
    theme: 'quotes',
    background: const BackgroundState(
      gradientColors: [Color(0xFF16161A), Color(0xFF2B2118)],
      motif: TemplateMotif.sparkles,
      motifColor: Color(0xFFE8C56E),
    ),
    frame: StatusFrame.corners,
    frameColor: const Color(0xFFE8C56E),
    frameWidth: 1.2,
    nameSlotId: 'fx_royal_name',
    photo: _photoSlot(
      id: 'fx_royal_photo',
      shape: ImageShape.circle,
      top: 60, // 60–190
      width: 130,
      frameColor: const Color(0xFFE8C56E),
    ),
    elements: [
      _divider(
        id: 'fx_royal_line',
        color: const Color(0xB3E8C56E),
        centerY: 235,
      ),
    ],
    texts: [
      _slot(
        id: 'fx_royal_main',
        text: 'Elegance is the only\nbeauty that never fades.',
        font: 'Playfair Display',
        size: 28,
        color: const Color(0xFFF3E3B8),
        top: 275, // 275–381
        lineHeight: 1.4,
      ),
      _nameSlot(
        id: 'fx_royal_name',
        font: 'Montserrat',
        size: 13,
        color: const Color(0x99FFFFFF),
        top: 430, // 430–475
        letterSpacing: 3,
      ),
    ],
  ),

  FixedTemplate(
    id: 'fx_suvichar',
    name: 'Suvichar',
    theme: 'quotes',
    background: const BackgroundState(
      gradientColors: [Color(0xFF06302B), Color(0xFF12564C)],
      motif: TemplateMotif.mandala,
      motifColor: Color(0xFFE8C56E),
    ),
    frame: StatusFrame.thin,
    frameColor: const Color(0xFFE8C56E),
    nameSlotId: 'fx_suvi_name',
    photo: _photoSlot(
      id: 'fx_suvi_photo',
      shape: ImageShape.circle,
      top: 360, // 360–480
      width: 120,
      frameColor: const Color(0xFFE8C56E),
    ),
    texts: [
      _slot(
        id: 'fx_suvi_title',
        text: 'सुविचार',
        font: 'Rozha One',
        size: 32,
        color: const Color(0xFFE8C56E),
        top: 90, // 90–160
      ),
      _slot(
        id: 'fx_suvi_body',
        text: 'मेहनत का फल\nसदा मीठा होता है।',
        font: 'Tiro Devanagari Hindi',
        size: 26,
        color: Colors.white,
        top: 220, // 220–326
        lineHeight: 1.5,
      ),
      _nameSlot(
        id: 'fx_suvi_name',
        font: 'Hind',
        size: 15,
        color: const Color(0x99E8C56E),
        top: 520, // 520–563
      ),
    ],
  ),

  FixedTemplate(
    id: 'fx_motivation',
    name: 'Bold Motivation',
    theme: 'quotes',
    background: const BackgroundState(
      gradientColors: [Color(0xFF10151B), Color(0xFF243B4A)],
      motif: TemplateMotif.geometric,
      motifColor: Color(0xFFECB365),
    ),
    nameSlotId: 'fx_motiv_name',
    photo: _photoSlot(
      id: 'fx_motiv_photo',
      shape: ImageShape.circle,
      top: 40, // 40–160
      width: 120,
      frameColor: const Color(0xFFECB365),
    ),
    elements: [
      _divider(
        id: 'fx_motiv_line',
        color: const Color(0xFFECB365),
        centerY: 415,
      ),
    ],
    texts: [
      _slot(
        id: 'fx_motiv_main',
        text: 'DREAM BIG.\nSTART SMALL.\nACT NOW.',
        font: 'Bebas Neue',
        size: 46,
        color: Colors.white,
        top: 180, // 180–380
        letterSpacing: 2,
        lineHeight: 1.25,
      ),
      _nameSlot(
        id: 'fx_motiv_name',
        font: 'Montserrat',
        size: 12,
        color: const Color(0xFFECB365),
        top: 450, // 450–494
        letterSpacing: 3,
      ),
    ],
  ),

  FixedTemplate(
    id: 'fx_minimal_thought',
    name: 'Minimal Thought',
    theme: 'quotes',
    background: const BackgroundState(
      gradientColors: [Color(0xFFF6F5F2), Color(0xFFE4E1DA)],
      motif: TemplateMotif.dots,
      motifColor: Color(0xFF9A948A),
    ),
    frame: StatusFrame.thin,
    frameColor: const Color(0xFF2E2C28),
    nameSlotId: 'fx_min_name',
    photo: _photoSlot(
      id: 'fx_min_photo',
      shape: ImageShape.circle,
      top: 70, // 70–210
      width: 140,
      frameColor: const Color(0xFF2E2C28),
    ),
    texts: [
      _slot(
        id: 'fx_min_main',
        text: '“Simplicity is the ultimate\nsophistication.”',
        font: 'Playfair Display',
        size: 26,
        color: const Color(0xFF2E2C28),
        top: 250, // 250–353
        lineHeight: 1.45,
      ),
      _nameSlot(
        id: 'fx_min_name',
        font: 'Montserrat',
        size: 11,
        color: const Color(0x992E2C28),
        top: 410, // 410–452
        letterSpacing: 3,
      ),
    ],
  ),
];
