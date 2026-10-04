import 'package:flutter/material.dart';

import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/studio/models/language_model.dart';

/// The eight composition families. Every generated template is one of these,
/// dressed in its category's palette, fonts, photo frame and decorations —
/// so two categories using "the same" layout still look nothing alike.
enum LayoutType {
  /// A — Large quote on top, small photo below, name bottom-right.
  largeQuoteSmallPhoto,

  /// B — Photo fills most of the canvas, quote overlaid on a soft scrim.
  fullImageQuoteOverlay,

  /// C — No photo. The quote is the whole design, framed by hairlines.
  quoteOnly,

  /// D — Circular photo up top, quote centred underneath.
  circlePhotoCenterQuote,

  /// E — Minimal: small quote low on the canvas, lots of air, tiny name.
  minimalText,

  /// F — Photo + quote + handwritten signature-style name.
  photoQuoteSignature,

  /// G — Traditional: title in a display face, body quote, ornamental rules,
  /// photo at the bottom.
  traditional,

  /// H — Modern premium: left-aligned kicker + big quote, hairline, small
  /// square photo in the corner.
  modernPremium,
}

/// Where the optional name goes. `none` means the layout has no name slot.
enum NamePosition { none, bottomRight, bottomCenter, underQuote, signature }

/// How a typed name is dressed: "Raj", "— Raj" or "By Raj" (Hindi: "राज",
/// "— राज", "– राज द्वारा" is avoided; "By" simply isn't idiomatic, so Hindi
/// uses the dash form for both).
enum NameStyle {
  plain,
  dash,
  by;

  String format(String raw, AppLanguage lang) {
    final name = raw.trim();
    if (name.isEmpty) return '';
    switch (this) {
      case NameStyle.plain:
        return name;
      case NameStyle.dash:
        return '— $name';
      case NameStyle.by:
        return lang.isHindi ? '— $name' : 'By $name';
    }
  }

  /// Strips any prefix [format] added, so re-editing shows the bare name.
  static String strip(String formatted) {
    var s = formatted.trim();
    if (s.startsWith('— ')) s = s.substring(2);
    if (s.startsWith('By ')) s = s.substring(3);
    return s.trim();
  }
}

/// The photo slot a layout wants, in design terms (visible top edge, visible
/// width, centred unless [centerX] says otherwise).
class PhotoFrameSpec {
  final ImageShape shape;
  final double width;
  final double top;

  /// Horizontal centre in canvas px; null = centred on the canvas.
  final double? centerX;
  final bool framed;
  final PhotoFrameStyle frameStyle;
  final Color frameColor;

  /// Feather width in the shape's own pixels — see `ImageObject.softEdge`.
  final double softEdge;

  const PhotoFrameSpec({
    required this.shape,
    required this.width,
    required this.top,
    this.centerX,
    this.framed = true,
    this.frameStyle = PhotoFrameStyle.thin,
    this.frameColor = Colors.white,
    this.softEdge = 0,
  });

  PhotoFrameSpec copyWith({
    ImageShape? shape,
    double? width,
    double? top,
    double? centerX,
    bool? framed,
    PhotoFrameStyle? frameStyle,
    Color? frameColor,
    double? softEdge,
  }) =>
      PhotoFrameSpec(
        shape: shape ?? this.shape,
        width: width ?? this.width,
        top: top ?? this.top,
        centerX: centerX ?? this.centerX,
        framed: framed ?? this.framed,
        frameStyle: frameStyle ?? this.frameStyle,
        frameColor: frameColor ?? this.frameColor,
        softEdge: softEdge ?? this.softEdge,
      );
}

/// What the user may change on a template. Not every template exposes every
/// option — a quote-only card has nothing photo-related to offer, and a
/// photo-first design keeps its quote fixed on purpose.
class TemplateCapabilities {
  final bool editQuote;
  final bool changePhoto;
  final bool changeName;
  final bool changeBackground;
  final bool changeLanguage;

  const TemplateCapabilities({
    this.editQuote = true,
    this.changePhoto = true,
    this.changeName = true,
    this.changeBackground = true,
    this.changeLanguage = true,
  });

  /// Quote only.
  static const quoteOnly = TemplateCapabilities(
      changePhoto: false, changeName: false, changeBackground: false);

  /// Quote + name.
  static const quoteName =
      TemplateCapabilities(changePhoto: false, changeBackground: false);

  /// Photo + quote.
  static const photoQuote =
      TemplateCapabilities(changeName: false, changeBackground: false);

  /// Photo + name (the quote is part of the design).
  static const photoName = TemplateCapabilities(
      editQuote: false, changeBackground: false, changeLanguage: false);

  /// Photo + quote + name.
  static const photoQuoteName = TemplateCapabilities(changeBackground: false);

  /// Background + quote.
  static const backgroundQuote =
      TemplateCapabilities(changePhoto: false, changeName: false);

  /// Everything.
  static const full = TemplateCapabilities();
}

/// Fonts a category pairs: a display face for titles/quotes and a quieter
/// body face for captions and names. Both must be in `kEditorFonts`.
class FontPair {
  final String display;
  final String body;

  /// A handwriting face for signature-style names.
  final String script;

  const FontPair({
    required this.display,
    required this.body,
    this.script = 'Caveat',
  });
}

/// The recipe for one template: *which* background, *which* layout, *which*
/// photo frame, how the name is shown, which languages it serves, what it
/// lets the user change. The quote is deliberately **not** here — it is
/// looked up from the quote store when the template is built, so one config
/// serves English and Hindi alike and quotes can be refreshed without
/// touching a single template.
class TemplateConfig {
  final String id;
  final String category;
  final String backgroundId;
  final LayoutType layout;
  final PhotoFrameSpec? imageFrame;
  final NamePosition namePosition;
  final NameStyle nameStyle;
  final Set<AppLanguage> languageSupport;
  final TemplateCapabilities capabilities;

  /// Restricts the quote pool to lines with this tag (Festival → `diwali`).
  final String? quoteTag;

  /// Index into the category's quote list, so neighbouring templates don't
  /// all carry the first quote. Wraps around.
  final int quoteIndex;

  const TemplateConfig({
    required this.id,
    required this.category,
    required this.backgroundId,
    required this.layout,
    this.imageFrame,
    this.namePosition = NamePosition.none,
    this.nameStyle = NameStyle.dash,
    this.languageSupport = const {AppLanguage.en, AppLanguage.hi},
    this.capabilities = TemplateCapabilities.full,
    this.quoteTag,
    this.quoteIndex = 0,
  });

  bool get hasPhoto => imageFrame != null;
  bool get hasName => namePosition != NamePosition.none;
}
