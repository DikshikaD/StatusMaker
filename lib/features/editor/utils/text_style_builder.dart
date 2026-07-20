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

/// Single source of truth for turning a [TextObject]'s style fields into a
/// [TextStyle]. Used by both the on-canvas text and the inline editor so they
/// always match pixel-for-pixel.
TextStyle buildTextStyle(TextObject t) {
  final base = TextStyle(
    color: t.color,
    fontSize: t.fontSize,
    fontWeight: t.bold ? FontWeight.w700 : FontWeight.w400,
    fontStyle: t.italic ? FontStyle.italic : FontStyle.normal,
    letterSpacing: t.letterSpacing,
    height: t.lineHeight,
  );
  try {
    return GoogleFonts.getFont(t.fontFamily, textStyle: base);
  } catch (_) {
    return base;
  }
}
