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
