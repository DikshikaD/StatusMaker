import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';

/// Curated font list — the only fonts offered in the picker. All are valid
/// Google Fonts so [GoogleFonts.getFont] never throws for these.
const List<String> kEditorFonts = [
  'Poppins',
  'Montserrat',
  'Playfair Display',
  'Lobster',
  'Pacifico',
  'Oswald',
  'Dancing Script',
  'Bebas Neue',
  'Caveat',
  'Roboto Slab',
  'Rozha One', // Indian display serif
  'Cinzel', // regal serif
  // Devanagari-capable fonts for Hindi / traditional templates
  'Tiro Devanagari Hindi',
  'Baloo 2',
  'Mukta',
  'Hind',
  'Yatra One',
  'Kalam',
  'Martel',
];

/// The subset of [kEditorFonts] that actually ships Devanagari glyphs.
///
/// Everything else is Latin-only: setting Hindi text in one of those doesn't
/// fail loudly, it silently falls back to a system font, so the design renders
/// nothing like its preview.
const Set<String> kDevanagariFonts = {
  'Poppins', // Indian Type Foundry — has Devanagari
  'Rozha One',
  'Tiro Devanagari Hindi',
  'Baloo 2',
  'Mukta',
  'Hind',
  'Yatra One',
  'Kalam',
  'Martel',
};

/// Latin-only font -> the closest Devanagari-capable substitute, chosen to
/// preserve the design's character (serif stays serif, script stays script)
/// rather than collapsing everything onto one fallback.
const Map<String, String> _devanagariSubstitute = {
  'Playfair Display': 'Martel', // elegant serif
  'Roboto Slab': 'Martel', // slab serif
  'Cinzel': 'Rozha One', // regal display serif
  'Lobster': 'Yatra One', // display script
  'Pacifico': 'Yatra One',
  'Dancing Script': 'Kalam', // handwriting
  'Caveat': 'Kalam',
  'Bebas Neue': 'Baloo 2', // heavy condensed display
  'Oswald': 'Hind', // condensed sans
  'Montserrat': 'Mukta', // geometric sans
};

/// Returns a font that can actually render [text].
///
/// Only substitutes when the string contains Devanagari and the requested font
/// can't draw it — Latin text keeps the font the design asked for. Unknown
/// fonts are left alone rather than guessed at.
String fontForText(String font, String text) {
  if (kDevanagariFonts.contains(font)) return font;
  if (!containsDevanagari(text)) return font;
  return _devanagariSubstitute[font] ?? 'Mukta';
}

/// True when [text] contains any character in the Devanagari Unicode block
/// (U+0900–U+097F).
bool containsDevanagari(String text) {
  for (final unit in text.runes) {
    if (unit >= 0x0900 && unit <= 0x097F) return true;
  }
  return false;
}

// Every text object on the canvas re-resolves its style on EVERY editor
// rebuild — which fires on any controller change (adding/removing an object,
// dragging any other object, or dragging a size/spacing/line-height slider,
// which calls this dozens of times a second). GoogleFonts.getFont() re-walks
// its font table and re-merges the TextStyle each call, so for every text
// object whose style didn't actually change that frame, this was pure wasted
// work — the single biggest cause of editor jank. Caching the resolved style
// per distinct style combination makes all of those calls instant, since only
// the object actually being edited ever produces a new key. Capped so
// dragging a slider (which mints a new fontSize every frame) can't grow this
// unbounded.
final Map<String, TextStyle> _styleCache = <String, TextStyle>{};
const int _styleCacheCap = 200;

/// Single source of truth for turning a [TextObject]'s style fields into a
/// [TextStyle]. Used by both the on-canvas text and the inline editor so they
/// always match pixel-for-pixel.
TextStyle buildTextStyle(TextObject t) {
  final key =
      '${t.fontFamily}|${t.color.toString()}|${t.fontSize}|${t.bold}|${t.italic}|${t.letterSpacing}|${t.lineHeight}';
  final cached = _styleCache[key];
  if (cached != null) return cached;

  final base = TextStyle(
    color: t.color,
    fontSize: t.fontSize,
    fontWeight: t.bold ? FontWeight.w700 : FontWeight.w400,
    fontStyle: t.italic ? FontStyle.italic : FontStyle.normal,
    letterSpacing: t.letterSpacing,
    height: t.lineHeight,
  );
  TextStyle style;
  try {
    style = GoogleFonts.getFont(t.fontFamily, textStyle: base);
  } catch (_) {
    style = base;
  }

  if (_styleCache.length >= _styleCacheCap) {
    _styleCache.remove(_styleCache.keys.first);
  }
  _styleCache[key] = style;
  return style;
}
