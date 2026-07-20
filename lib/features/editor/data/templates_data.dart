import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/quotes_data.dart';
import 'package:status_maker/features/editor/data/template_motif.dart';

/// Where the quote sits vertically in the design.
enum TemplateAnchor { top, center, bottom }

/// The photo-frame shape used by a category's image templates.
ImageShape imageShapeForCategory(String? category) {
  switch (category) {
    case 'Love':
      return ImageShape.heart;
    case 'Good Morning':
    case 'Morning':
    case 'Festival':
      return ImageShape.circle;
    case 'Motivation':
      return ImageShape.square;
    case 'Devotional':
    case 'Suprabhat':
      return ImageShape.circle;
    case 'Good Night':
      return ImageShape.circle;
    default:
      return ImageShape.roundedRectangle;
  }
}

/// A ready-made status design: a decorated background + a composed, styled
/// quote. Selecting one opens the editor already set up with this look.
class StatusTemplate {
  final String text;
  final List<Color> gradient;
  final Color textColor;
  final String fontFamily;
  final bool bold;
  final TemplateMotif motif;
  final TextAlign align;
  final TemplateAnchor anchor;
  final double fontSize;
  final double letterSpacing;
  final Color? highlight;
  final ImageShape? imageShape; // null = text-only template
  final Offset imagePosition;
  final double imageScale;

  const StatusTemplate({
    required this.text,
    required this.gradient,
    required this.textColor,
    required this.fontFamily,
    required this.motif,
    required this.align,
    required this.anchor,
    required this.fontSize,
    this.bold = true,
    this.letterSpacing = 0.0,
    this.highlight,
    this.imageShape,
    this.imagePosition = const Offset(65, 55),
    this.imageScale = 0.85,
  });

  bool get hasImage => imageShape != null;
}

/// The decorative theme that makes each category visually distinct.
TemplateMotif motifForCategory(String? category) {
  switch (category) {
    case 'Good Morning':
    case 'Morning':
      return TemplateMotif.sun;
    case 'Birthday':
      return TemplateMotif.confetti;
    case 'Festival':
      return TemplateMotif.diya;
    case 'Motivation':
      return TemplateMotif.geometric;
    case 'Love':
      return TemplateMotif.hearts;
    case 'Devotional':
      return TemplateMotif.om;
    case 'Good Night':
      return TemplateMotif.moonStars;
    case 'Suprabhat':
      return TemplateMotif.sunrise;
    case 'Suvichar':
      return TemplateMotif.mandala;
    default:
      return TemplateMotif.dots;
  }
}

class _Style {
  final List<Color> gradient;
  final Color textColor;
  final String font;
  final bool bold;
  final TextAlign align;
  final TemplateAnchor anchor;
  final double fontSize;
  final double letterSpacing;
  final Color? highlight;
  final bool upper;
  final bool image;
  final TemplateAnchor imageAnchor;
  final TemplateMotif? motif; // per-template concept (overrides category default)
  final ImageShape? imageShape; // per-template photo shape override

  const _Style({
    required this.gradient,
    required this.textColor,
    required this.font,
    required this.align,
    required this.anchor,
    required this.fontSize,
    this.bold = true,
    this.letterSpacing = 0.0,
    this.highlight,
    this.upper = false,
    this.image = false,
    this.imageAnchor = TemplateAnchor.top,
    this.motif,
    this.imageShape,
  });
}

/// Eight distinct COMPOSITIONS — different fonts, positions, alignments, sizes,
/// casing and highlight treatments. Cycled within a category so the designs
/// look genuinely different, not just recoloured.
const List<_Style> _styles = [
  // 1 — classic serif, centered
  _Style(
    gradient: [Color(0xFF667EEA), Color(0xFF764BA2)],
    textColor: Colors.white,
    font: 'Playfair Display',
    align: TextAlign.center,
    anchor: TemplateAnchor.center,
    fontSize: 34,
  ),
  // 2 — modern sans, bottom-left, dark highlight bar + photo on top
  _Style(
    gradient: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    textColor: Colors.white,
    font: 'Poppins',
    align: TextAlign.left,
    anchor: TemplateAnchor.bottom,
    fontSize: 30,
    highlight: Color(0x47000000),
    image: true,
    imageAnchor: TemplateAnchor.top,
  ),
  // 3 — elegant script, top, photo below
  _Style(
    gradient: [Color(0xFFFF9A9E), Color(0xFFFAD0C4)],
    textColor: Color(0xFF3A2E39),
    font: 'Dancing Script',
    bold: false,
    align: TextAlign.center,
    anchor: TemplateAnchor.top,
    fontSize: 42,
    image: true,
    imageAnchor: TemplateAnchor.bottom,
  ),
  // 4 — uppercase poster
  _Style(
    gradient: [Color(0xFFF83600), Color(0xFFFE8C00)],
    textColor: Colors.white,
    font: 'Bebas Neue',
    align: TextAlign.center,
    anchor: TemplateAnchor.center,
    fontSize: 44,
    letterSpacing: 2,
    upper: true,
  ),
  // 5 — handwritten, bottom, photo on top
  _Style(
    gradient: [Color(0xFF43E97B), Color(0xFF38F9D7)],
    textColor: Color(0xFF0B3D2E),
    font: 'Caveat',
    bold: false,
    align: TextAlign.center,
    anchor: TemplateAnchor.bottom,
    fontSize: 36,
    image: true,
    imageAnchor: TemplateAnchor.top,
  ),
  // 6 — sticker look, white pill highlight, centered
  _Style(
    gradient: [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
    textColor: Color(0xFF3A2E39),
    font: 'Montserrat',
    align: TextAlign.center,
    anchor: TemplateAnchor.center,
    fontSize: 26,
    highlight: Color(0xD9FFFFFF),
  ),
  // 7 — condensed caps, top-left, photo below
  _Style(
    gradient: [Color(0xFF0F2027), Color(0xFF2C5364)],
    textColor: Colors.white,
    font: 'Oswald',
    align: TextAlign.left,
    anchor: TemplateAnchor.top,
    fontSize: 32,
    letterSpacing: 1,
    upper: true,
    image: true,
    imageAnchor: TemplateAnchor.bottom,
  ),
  // 8 — playful, centered
  _Style(
    gradient: [Color(0xFFFBAB7E), Color(0xFFF7CE68)],
    textColor: Color(0xFF4A2C2A),
    font: 'Pacifico',
    bold: false,
    align: TextAlign.center,
    anchor: TemplateAnchor.center,
    fontSize: 34,
  ),
];

// Indian festivals — each a DIFFERENT concept (Diwali, Holi, Rakhi, Ganesh,
// Eid, Navratri), not recolours. Order matches the Festival quote order.
const List<_Style> _festivalStyles = [
  _Style(gradient: [Color(0xFF7B1113), Color(0xFFC79A3A)], textColor: Color(0xFFFFE9B0), font: 'Rozha One', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 38, motif: TemplateMotif.diya),
  _Style(gradient: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)], textColor: Color(0xFF4A148C), font: 'Poppins', align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 32, motif: TemplateMotif.holi),
  _Style(gradient: [Color(0xFFB71C1C), Color(0xFFFFC107)], textColor: Color(0xFFFFF3D6), font: 'Cinzel', align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 28, image: true, imageAnchor: TemplateAnchor.top, motif: TemplateMotif.rakhi, imageShape: ImageShape.circle),
  _Style(gradient: [Color(0xFFFF7043), Color(0xFFFFCA28)], textColor: Color(0xFF5D2E00), font: 'Playfair Display', align: TextAlign.center, anchor: TemplateAnchor.top, fontSize: 34, motif: TemplateMotif.ganesh),
  _Style(gradient: [Color(0xFF004D40), Color(0xFF00897B)], textColor: Color(0xFFFFE082), font: 'Cinzel', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 34, motif: TemplateMotif.eid),
  _Style(gradient: [Color(0xFF6A1B9A), Color(0xFFEC407A)], textColor: Colors.white, font: 'Poppins', align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 32, motif: TemplateMotif.navratri),
  _Style(gradient: [Color(0xFF1A237E), Color(0xFFFFD54F)], textColor: Colors.white, font: 'Dancing Script', bold: false, align: TextAlign.center, anchor: TemplateAnchor.top, fontSize: 42, image: true, imageAnchor: TemplateAnchor.bottom, motif: TemplateMotif.diya, imageShape: ImageShape.circle),
  _Style(gradient: [Color(0xFFAD1457), Color(0xFFFFB300)], textColor: Color(0xFFFFF3D6), font: 'Rozha One', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 34, motif: TemplateMotif.sparkles),
  // Traditional additions — devotional mandala & Om for elders.
  _Style(gradient: [Color(0xFF7B1113), Color(0xFFC79A3A)], textColor: Color(0xFFFFE9B0), font: 'Rozha One', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 36, motif: TemplateMotif.mandala),
  _Style(gradient: [Color(0xFFE65100), Color(0xFFFFB300)], textColor: Color(0xFFFFF3D6), font: 'Baloo 2', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 34, motif: TemplateMotif.om),
];

// Morning — sunrise, coffee, botanical, minimal, spiritual…
const List<_Style> _morningStyles = [
  _Style(gradient: [Color(0xFFFFB74D), Color(0xFFFFF176)], textColor: Color(0xFF4E342E), font: 'Playfair Display', align: TextAlign.center, anchor: TemplateAnchor.top, fontSize: 34, motif: TemplateMotif.sunrise),
  _Style(gradient: [Color(0xFFD7CCC8), Color(0xFFEFEBE9)], textColor: Color(0xFF4E342E), font: 'Poppins', align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 30, motif: TemplateMotif.coffee),
  _Style(gradient: [Color(0xFFA5D6A7), Color(0xFFE8F5E9)], textColor: Color(0xFF1B5E20), font: 'Dancing Script', bold: false, align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 40, motif: TemplateMotif.botanical),
  _Style(gradient: [Color(0xFFFFE0B2), Color(0xFFFFF3E0)], textColor: Color(0xFF5D4037), font: 'Montserrat', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 30, motif: TemplateMotif.sun),
  _Style(gradient: [Color(0xFF80CBC4), Color(0xFFE0F2F1)], textColor: Color(0xFF004D40), font: 'Caveat', bold: false, align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 36, motif: TemplateMotif.dots),
  _Style(gradient: [Color(0xFF9575CD), Color(0xFFD1C4E9)], textColor: Colors.white, font: 'Playfair Display', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 30, motif: TemplateMotif.sparkles),
  _Style(gradient: [Color(0xFFFF8A65), Color(0xFFFFCC80)], textColor: Colors.white, font: 'Poppins', align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 30, highlight: Color(0x33000000), image: true, imageAnchor: TemplateAnchor.top, motif: TemplateMotif.sunrise, imageShape: ImageShape.circle),
  _Style(gradient: [Color(0xFFBCAAA4), Color(0xFFEFEBE9)], textColor: Color(0xFF3E2723), font: 'Dancing Script', bold: false, align: TextAlign.center, anchor: TemplateAnchor.top, fontSize: 40, image: true, imageAnchor: TemplateAnchor.bottom, motif: TemplateMotif.coffee, imageShape: ImageShape.roundedRectangle),
  // Traditional additions — sunrise & lotus for a classic morning feel.
  _Style(gradient: [Color(0xFFFFCC80), Color(0xFFFFF3E0)], textColor: Color(0xFF5D4037), font: 'Rozha One', align: TextAlign.center, anchor: TemplateAnchor.top, fontSize: 36, motif: TemplateMotif.sunrise),
  _Style(gradient: [Color(0xFFF8BBD0), Color(0xFFFFF3E0)], textColor: Color(0xFFAD1457), font: 'Baloo 2', align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 34, motif: TemplateMotif.lotus),
];

// Birthday — balloons, cake, confetti, luxury, cute…
const List<_Style> _birthdayStyles = [
  _Style(gradient: [Color(0xFF7E57C2), Color(0xFFB39DDB)], textColor: Colors.white, font: 'Poppins', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 34, motif: TemplateMotif.balloons),
  _Style(gradient: [Color(0xFFEC407A), Color(0xFFF8BBD0)], textColor: Colors.white, font: 'Pacifico', bold: false, align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 34, motif: TemplateMotif.cake),
  _Style(gradient: [Color(0xFF29B6F6), Color(0xFF81D4FA)], textColor: Colors.white, font: 'Bebas Neue', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 44, letterSpacing: 2, upper: true, motif: TemplateMotif.confetti),
  _Style(gradient: [Color(0xFF212121), Color(0xFFBFA14A)], textColor: Color(0xFFFFD54F), font: 'Playfair Display', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 30, motif: TemplateMotif.sparkles),
  _Style(gradient: [Color(0xFFFFB74D), Color(0xFFFFF176)], textColor: Color(0xFF5D4037), font: 'Caveat', bold: false, align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 36, image: true, imageAnchor: TemplateAnchor.top, motif: TemplateMotif.balloons, imageShape: ImageShape.circle),
  _Style(gradient: [Color(0xFFAB47BC), Color(0xFFCE93D8)], textColor: Colors.white, font: 'Montserrat', align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 28, highlight: Color(0x40000000), image: true, imageAnchor: TemplateAnchor.top, motif: TemplateMotif.confetti, imageShape: ImageShape.roundedRectangle),
  _Style(gradient: [Color(0xFFFF7043), Color(0xFFFFCC80)], textColor: Colors.white, font: 'Bebas Neue', align: TextAlign.center, anchor: TemplateAnchor.top, fontSize: 40, upper: true, image: true, imageAnchor: TemplateAnchor.bottom, motif: TemplateMotif.cake, imageShape: ImageShape.roundedRectangle),
  _Style(gradient: [Color(0xFF26C6DA), Color(0xFFB2EBF2)], textColor: Color(0xFF006064), font: 'Dancing Script', bold: false, align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 38, motif: TemplateMotif.balloons),
];

// Love — couple, roses, hearts, minimal, luxury…
const List<_Style> _loveStyles = [
  _Style(gradient: [Color(0xFFFF7043), Color(0xFFFFCA28)], textColor: Color(0xFF4A2C2A), font: 'Playfair Display', align: TextAlign.center, anchor: TemplateAnchor.top, fontSize: 32, motif: TemplateMotif.couple),
  _Style(gradient: [Color(0xFFEC407A), Color(0xFFF8BBD0)], textColor: Colors.white, font: 'Dancing Script', bold: false, align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 42, motif: TemplateMotif.roses),
  _Style(gradient: [Color(0xFFD81B60), Color(0xFFF48FB1)], textColor: Colors.white, font: 'Poppins', align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 32, highlight: Color(0x40000000), motif: TemplateMotif.hearts),
  _Style(gradient: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)], textColor: Color(0xFFAD1457), font: 'Montserrat', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 28, motif: TemplateMotif.hearts),
  _Style(gradient: [Color(0xFF5C6BC0), Color(0xFF9FA8DA)], textColor: Colors.white, font: 'Poppins', align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 30, image: true, imageAnchor: TemplateAnchor.top, motif: TemplateMotif.couple, imageShape: ImageShape.heart),
  _Style(gradient: [Color(0xFFAD1457), Color(0xFFF06292)], textColor: Colors.white, font: 'Dancing Script', bold: false, align: TextAlign.center, anchor: TemplateAnchor.top, fontSize: 40, image: true, imageAnchor: TemplateAnchor.bottom, motif: TemplateMotif.roses, imageShape: ImageShape.heart),
  _Style(gradient: [Color(0xFF311B92), Color(0xFFAD1457)], textColor: Color(0xFFFFD54F), font: 'Playfair Display', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 30, motif: TemplateMotif.sparkles),
];

// Business — skyline, growth, premium dark, leadership…
const List<_Style> _businessStyles = [
  _Style(gradient: [Color(0xFF263238), Color(0xFF37474F)], textColor: Colors.white, font: 'Montserrat', align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 30, motif: TemplateMotif.skyline),
  _Style(gradient: [Color(0xFF1A237E), Color(0xFF3949AB)], textColor: Colors.white, font: 'Poppins', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 30, motif: TemplateMotif.growth),
  _Style(gradient: [Color(0xFF000000), Color(0xFF212121)], textColor: Color(0xFFBFA14A), font: 'Playfair Display', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 30, motif: TemplateMotif.dots),
  _Style(gradient: [Color(0xFF004D40), Color(0xFF00695C)], textColor: Colors.white, font: 'Cinzel', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 28, motif: TemplateMotif.skyline),
  _Style(gradient: [Color(0xFF0D47A1), Color(0xFF1565C0)], textColor: Colors.white, font: 'Oswald', align: TextAlign.left, anchor: TemplateAnchor.top, fontSize: 30, letterSpacing: 1, upper: true, image: true, imageAnchor: TemplateAnchor.bottom, motif: TemplateMotif.growth, imageShape: ImageShape.square),
  _Style(gradient: [Color(0xFFECEFF1), Color(0xFFCFD8DC)], textColor: Color(0xFF263238), font: 'Montserrat', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 28, motif: TemplateMotif.geometric),
  _Style(gradient: [Color(0xFF37474F), Color(0xFF546E7A)], textColor: Colors.white, font: 'Poppins', align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 28, image: true, imageAnchor: TemplateAnchor.top, motif: TemplateMotif.skyline, imageShape: ImageShape.square),
  _Style(gradient: [Color(0xFF1B1B1B), Color(0xFFB8860B)], textColor: Color(0xFFFFD54F), font: 'Bebas Neue', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 40, letterSpacing: 2, upper: true, motif: TemplateMotif.arrow),
];

// Motivation — mountain, arrow, minimal, cinematic…
const List<_Style> _motivationStyles = [
  _Style(gradient: [Color(0xFF263238), Color(0xFF546E7A)], textColor: Colors.white, font: 'Bebas Neue', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 42, letterSpacing: 2, upper: true, motif: TemplateMotif.mountain),
  _Style(gradient: [Color(0xFF1A237E), Color(0xFF283593)], textColor: Colors.white, font: 'Oswald', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 34, upper: true, motif: TemplateMotif.arrow),
  _Style(gradient: [Color(0xFF000000), Color(0xFF1A1A1A)], textColor: Colors.white, font: 'Playfair Display', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 30, motif: TemplateMotif.dots),
  _Style(gradient: [Color(0xFF2E7D32), Color(0xFF66BB6A)], textColor: Colors.white, font: 'Montserrat', align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 30, motif: TemplateMotif.mountain),
  _Style(gradient: [Color(0xFF0F2027), Color(0xFF203A43)], textColor: Color(0xFFFFD54F), font: 'Cinzel', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 30, motif: TemplateMotif.geometric),
  _Style(gradient: [Color(0xFFB71C1C), Color(0xFF7F0000)], textColor: Colors.white, font: 'Bebas Neue', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 40, letterSpacing: 3, upper: true, motif: TemplateMotif.arrow),
  _Style(gradient: [Color(0xFF37474F), Color(0xFF263238)], textColor: Colors.white, font: 'Oswald', align: TextAlign.left, anchor: TemplateAnchor.top, fontSize: 30, upper: true, image: true, imageAnchor: TemplateAnchor.bottom, motif: TemplateMotif.mountain, imageShape: ImageShape.square),
  _Style(gradient: [Color(0xFF212121), Color(0xFF6D1B1B)], textColor: Color(0xFFFFD54F), font: 'Cinzel', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 32, upper: true, motif: TemplateMotif.geometric),
];

// Devotional / Bhakti — Om, mandala, lotus, diya over saffron, maroon &
// Krishna-blue. Devanagari-friendly fonts so Hindi text renders beautifully.
const List<_Style> _devotionalStyles = [
  _Style(gradient: [Color(0xFFE65100), Color(0xFF7B1113)], textColor: Color(0xFFFFE082), font: 'Rozha One', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 40, motif: TemplateMotif.om),
  _Style(gradient: [Color(0xFF1A237E), Color(0xFF00695C)], textColor: Color(0xFFFFD54F), font: 'Yatra One', align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 36, motif: TemplateMotif.lotus),
  _Style(gradient: [Color(0xFF7B1113), Color(0xFFC79A3A)], textColor: Color(0xFFFFF3D6), font: 'Tiro Devanagari Hindi', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 34, motif: TemplateMotif.mandala),
  _Style(gradient: [Color(0xFF3E2723), Color(0xFFBF8A2E)], textColor: Color(0xFFFFD54F), font: 'Rozha One', align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 34, motif: TemplateMotif.diya),
  _Style(gradient: [Color(0xFFFF8F00), Color(0xFFFFECB3)], textColor: Color(0xFF5D2E00), font: 'Baloo 2', align: TextAlign.center, anchor: TemplateAnchor.top, fontSize: 36, motif: TemplateMotif.sun),
  _Style(gradient: [Color(0xFF4A148C), Color(0xFFAD1457)], textColor: Colors.white, font: 'Mukta', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 34, motif: TemplateMotif.sparkles),
  _Style(gradient: [Color(0xFFFFF3E0), Color(0xFFFFCC80)], textColor: Color(0xFF7B1113), font: 'Kalam', bold: false, align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 32, image: true, imageAnchor: TemplateAnchor.top, motif: TemplateMotif.om, imageShape: ImageShape.circle),
  _Style(gradient: [Color(0xFFFDF6E3), Color(0xFFE9D8A6)], textColor: Color(0xFF7B1113), font: 'Hind', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 34, motif: TemplateMotif.mandala),
];

// Good Night / Shubh Ratri — moons, stars & calm night skies.
const List<_Style> _goodNightStyles = [
  _Style(gradient: [Color(0xFF0D1B3E), Color(0xFF1A237E)], textColor: Colors.white, font: 'Baloo 2', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 38, motif: TemplateMotif.moonStars),
  _Style(gradient: [Color(0xFF311B92), Color(0xFF1565C0)], textColor: Color(0xFFFFF3B0), font: 'Yatra One', align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 34, motif: TemplateMotif.moonStars),
  _Style(gradient: [Color(0xFF001F3F), Color(0xFF004D40)], textColor: Color(0xFFFFD54F), font: 'Rozha One', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 34, motif: TemplateMotif.sparkles),
  _Style(gradient: [Color(0xFF283593), Color(0xFF6A1B9A)], textColor: Colors.white, font: 'Mukta', align: TextAlign.center, anchor: TemplateAnchor.top, fontSize: 34, motif: TemplateMotif.moonStars),
  _Style(gradient: [Color(0xFF1B1B2F), Color(0xFF162447)], textColor: Colors.white, font: 'Hind', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 32, motif: TemplateMotif.dots),
  _Style(gradient: [Color(0xFF0D47A1), Color(0xFF4A148C)], textColor: Colors.white, font: 'Kalam', bold: false, align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 32, image: true, imageAnchor: TemplateAnchor.top, motif: TemplateMotif.moonStars, imageShape: ImageShape.circle),
  _Style(gradient: [Color(0xFF311B92), Color(0xFF880E4F)], textColor: Color(0xFFFFD54F), font: 'Tiro Devanagari Hindi', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 34, motif: TemplateMotif.mandala),
  _Style(gradient: [Color(0xFF000000), Color(0xFF1A237E)], textColor: Colors.white, font: 'Martel', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 34, motif: TemplateMotif.moonStars),
];

// Suprabhat / Good Morning (traditional) — sunrise, lotus, roses, blessings.
const List<_Style> _suprabhatStyles = [
  _Style(gradient: [Color(0xFFFFB74D), Color(0xFFFFF176)], textColor: Color(0xFF5D2E00), font: 'Rozha One', align: TextAlign.center, anchor: TemplateAnchor.top, fontSize: 38, motif: TemplateMotif.sunrise),
  _Style(gradient: [Color(0xFFFF8A65), Color(0xFFFFCC80)], textColor: Color(0xFF4E342E), font: 'Baloo 2', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 36, motif: TemplateMotif.sun),
  _Style(gradient: [Color(0xFFA5D6A7), Color(0xFFE8F5E9)], textColor: Color(0xFF1B5E20), font: 'Kalam', bold: false, align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 36, motif: TemplateMotif.botanical),
  _Style(gradient: [Color(0xFFF8BBD0), Color(0xFFFFF3E0)], textColor: Color(0xFFAD1457), font: 'Yatra One', align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 34, motif: TemplateMotif.lotus),
  _Style(gradient: [Color(0xFFFFCCBC), Color(0xFFFFE0B2)], textColor: Color(0xFF7B1113), font: 'Tiro Devanagari Hindi', align: TextAlign.center, anchor: TemplateAnchor.top, fontSize: 34, motif: TemplateMotif.roses),
  _Style(gradient: [Color(0xFFFFB74D), Color(0xFFFFECB3)], textColor: Color(0xFF5D4037), font: 'Mukta', align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 32, image: true, imageAnchor: TemplateAnchor.top, motif: TemplateMotif.sunrise, imageShape: ImageShape.circle),
  _Style(gradient: [Color(0xFFFDF6E3), Color(0xFFFFE0B2)], textColor: Color(0xFFE65100), font: 'Hind', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 34, motif: TemplateMotif.mandala),
  _Style(gradient: [Color(0xFF80CBC4), Color(0xFFE0F2F1)], textColor: Color(0xFF004D40), font: 'Martel', align: TextAlign.center, anchor: TemplateAnchor.top, fontSize: 34, motif: TemplateMotif.sun),
];

// Suvichar / Anmol Vachan — calm, minimal wisdom backdrops.
const List<_Style> _suvicharStyles = [
  _Style(gradient: [Color(0xFF1A237E), Color(0xFF3949AB)], textColor: Colors.white, font: 'Rozha One', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 34, motif: TemplateMotif.mandala),
  _Style(gradient: [Color(0xFF212121), Color(0xFF37474F)], textColor: Colors.white, font: 'Baloo 2', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 32, motif: TemplateMotif.dots),
  _Style(gradient: [Color(0xFF00695C), Color(0xFF2E7D32)], textColor: Colors.white, font: 'Mukta', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 32, motif: TemplateMotif.geometric),
  _Style(gradient: [Color(0xFFC8E6C9), Color(0xFFF1F8E9)], textColor: Color(0xFF1B5E20), font: 'Kalam', bold: false, align: TextAlign.center, anchor: TemplateAnchor.bottom, fontSize: 34, motif: TemplateMotif.botanical),
  _Style(gradient: [Color(0xFF4A148C), Color(0xFF7B1113)], textColor: Color(0xFFFFD54F), font: 'Yatra One', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 32, motif: TemplateMotif.sparkles),
  _Style(gradient: [Color(0xFFFDF6E3), Color(0xFFE9D8A6)], textColor: Color(0xFF4E342E), font: 'Hind', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 32, motif: TemplateMotif.mandala),
  _Style(gradient: [Color(0xFFFFE0B2), Color(0xFFFFF3E0)], textColor: Color(0xFF5D4037), font: 'Tiro Devanagari Hindi', align: TextAlign.center, anchor: TemplateAnchor.top, fontSize: 32, motif: TemplateMotif.sun),
  _Style(gradient: [Color(0xFF263238), Color(0xFF455A64)], textColor: Colors.white, font: 'Martel', align: TextAlign.center, anchor: TemplateAnchor.center, fontSize: 32, motif: TemplateMotif.mandala),
];

List<_Style> _stylesForCategory(String? category) {
  switch (category) {
    case 'Festival':
      return _festivalStyles;
    case 'Devotional':
      return _devotionalStyles;
    case 'Good Night':
      return _goodNightStyles;
    case 'Suprabhat':
      return _suprabhatStyles;
    case 'Suvichar':
      return _suvicharStyles;
    case 'Good Morning':
    case 'Morning':
      return _morningStyles;
    case 'Birthday':
      return _birthdayStyles;
    case 'Love':
      return _loveStyles;
    case 'Business':
      return _businessStyles;
    case 'Motivation':
      return _motivationStyles;
    default:
      return _styles;
  }
}

/// Builds the designed templates for a category. Each template picks its own
/// concept (motif), palette, font and layout so the set feels like a real
/// marketplace, not recolours.
List<StatusTemplate> templatesForCategory(String? category) {
  final quotes = quotesForCategory(category);
  final styleSet = _stylesForCategory(category);
  final defaultMotif = motifForCategory(category);
  final defaultShape = imageShapeForCategory(category);
  final count = quotes.length < styleSet.length ? quotes.length : styleSet.length;
  final result = <StatusTemplate>[];
  for (var i = 0; i < count; i++) {
    final s = styleSet[i];
    final text = s.upper ? quotes[i].toUpperCase() : quotes[i];
    final imgPos = s.imageAnchor == TemplateAnchor.top
        ? const Offset(65, 55)
        : const Offset(65, 305);
    result.add(StatusTemplate(
      text: text,
      gradient: s.gradient,
      textColor: s.textColor,
      fontFamily: s.font,
      bold: s.bold,
      motif: s.motif ?? defaultMotif,
      align: s.align,
      anchor: s.anchor,
      fontSize: s.fontSize,
      letterSpacing: s.letterSpacing,
      highlight: s.highlight,
      imageShape: s.image ? (s.imageShape ?? defaultShape) : null,
      imagePosition: imgPos,
    ));
  }
  return result;
}
