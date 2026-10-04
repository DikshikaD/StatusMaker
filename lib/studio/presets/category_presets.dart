import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/studio/models/template_config.dart';

/// Everything that gives a category its own look beyond the background:
/// which layout families it rotates through, its type pairing, how its photo
/// is framed, how a name is signed, its greeting word, and a small accent
/// decoration. Two categories never share the same combination.
class CategoryPreset {
  final String id;

  /// Layout families in rotation order. Deliberately a *subset* — Motivation
  /// never gets the traditional layout, Bhakti never the modern-premium one.
  final List<LayoutType> layouts;
  final FontPair fonts;
  final ImageShape photoShape;
  final bool photoFramed;
  final PhotoFrameStyle frameStyle;
  final double softEdge;
  final NameStyle nameStyle;

  /// Greeting word used as the traditional layout's title and the modern
  /// layout's kicker. Festival resolves per occasion — see [greeting].
  final String greetingEn;
  final String greetingHi;

  /// Small accent sticker placed where the layout leaves room (null = the
  /// background motif is decoration enough).
  final ElementShape? decor;

  /// Sets the quote in UPPERCASE for Latin text (headline styles).
  final bool upperQuote;

  const CategoryPreset({
    required this.id,
    required this.layouts,
    required this.fonts,
    required this.photoShape,
    this.photoFramed = true,
    this.frameStyle = PhotoFrameStyle.thin,
    this.softEdge = 0,
    this.nameStyle = NameStyle.dash,
    required this.greetingEn,
    required this.greetingHi,
    this.decor,
    this.upperQuote = false,
  });

  String greeting({required bool hindi, String? tag}) {
    final festival = _festivalGreetings[tag];
    if (festival != null) return hindi ? festival.$2 : festival.$1;
    return hindi ? greetingHi : greetingEn;
  }
}

const Map<String, (String, String)> _festivalGreetings = {
  'diwali': ('Happy Diwali', 'शुभ दीपावली'),
  'holi': ('Happy Holi', 'होली मुबारक'),
  'rakhi': ('Raksha Bandhan', 'रक्षाबंधन'),
  'independence': ('Independence Day', 'स्वतंत्रता दिवस'),
  'ganesh': ('Ganesh Chaturthi', 'गणेश चतुर्थी'),
  'eid': ('Eid Mubarak', 'ईद मुबारक'),
  'navratri': ('Happy Navratri', 'शुभ नवरात्रि'),
};

const List<CategoryPreset> kCategoryPresets = [
  CategoryPreset(
    id: 'morning',
    layouts: [
      LayoutType.largeQuoteSmallPhoto,
      LayoutType.circlePhotoCenterQuote,
      LayoutType.traditional,
      LayoutType.quoteOnly,
    ],
    fonts: FontPair(display: 'Playfair Display', body: 'Montserrat', script: 'Caveat'),
    photoShape: ImageShape.circle,
    frameStyle: PhotoFrameStyle.thin,
    softEdge: 0,
    nameStyle: NameStyle.dash,
    greetingEn: 'Good Morning',
    greetingHi: 'सुप्रभात',
  ),
  CategoryPreset(
    id: 'goodnight',
    layouts: [
      LayoutType.quoteOnly,
      LayoutType.minimalText,
      LayoutType.circlePhotoCenterQuote,
      LayoutType.fullImageQuoteOverlay,
    ],
    fonts: FontPair(display: 'Playfair Display', body: 'Poppins', script: 'Dancing Script'),
    photoShape: ImageShape.circle,
    photoFramed: false,
    softEdge: 22,
    nameStyle: NameStyle.dash,
    greetingEn: 'Good Night',
    greetingHi: 'शुभ रात्रि',
    decor: ElementShape.star,
  ),
  CategoryPreset(
    id: 'bhakti',
    layouts: [
      LayoutType.traditional,
      LayoutType.circlePhotoCenterQuote,
      LayoutType.largeQuoteSmallPhoto,
      LayoutType.photoQuoteSignature,
    ],
    fonts: FontPair(display: 'Rozha One', body: 'Hind', script: 'Kalam'),
    photoShape: ImageShape.circle,
    frameStyle: PhotoFrameStyle.gold,
    nameStyle: NameStyle.plain,
    // A neutral devotional greeting — not itself one of the quotes, so the
    // traditional layout's title never repeats the line beneath it.
    greetingEn: 'Jai Ho',
    greetingHi: 'जय हो',
    decor: ElementShape.flower,
  ),
  CategoryPreset(
    id: 'motivation',
    layouts: [
      LayoutType.modernPremium,
      LayoutType.quoteOnly,
      LayoutType.minimalText,
      LayoutType.largeQuoteSmallPhoto,
    ],
    fonts: FontPair(display: 'Bebas Neue', body: 'Montserrat', script: 'Caveat'),
    photoShape: ImageShape.square,
    frameStyle: PhotoFrameStyle.thin,
    nameStyle: NameStyle.plain,
    greetingEn: 'Motivation',
    greetingHi: 'प्रेरणा',
    decor: ElementShape.bolt,
    upperQuote: true,
  ),
  CategoryPreset(
    id: 'success',
    layouts: [
      LayoutType.modernPremium,
      LayoutType.largeQuoteSmallPhoto,
      LayoutType.quoteOnly,
      LayoutType.photoQuoteSignature,
    ],
    fonts: FontPair(display: 'Cinzel', body: 'Montserrat', script: 'Caveat'),
    photoShape: ImageShape.roundedRectangle,
    frameStyle: PhotoFrameStyle.gold,
    nameStyle: NameStyle.dash,
    greetingEn: 'Success',
    greetingHi: 'सफलता',
    decor: ElementShape.crown,
  ),
  CategoryPreset(
    id: 'business',
    layouts: [
      LayoutType.modernPremium,
      LayoutType.minimalText,
      LayoutType.quoteOnly,
      LayoutType.photoQuoteSignature,
    ],
    fonts: FontPair(display: 'Montserrat', body: 'Poppins', script: 'Caveat'),
    photoShape: ImageShape.square,
    frameStyle: PhotoFrameStyle.thin,
    nameStyle: NameStyle.plain,
    greetingEn: 'Business',
    greetingHi: 'बिज़नेस',
  ),
  CategoryPreset(
    id: 'birthday',
    layouts: [
      LayoutType.circlePhotoCenterQuote,
      LayoutType.fullImageQuoteOverlay,
      LayoutType.photoQuoteSignature,
      LayoutType.largeQuoteSmallPhoto,
    ],
    fonts: FontPair(display: 'Lobster', body: 'Poppins', script: 'Pacifico'),
    photoShape: ImageShape.circle,
    frameStyle: PhotoFrameStyle.glow,
    nameStyle: NameStyle.dash,
    greetingEn: 'Happy Birthday',
    greetingHi: 'जन्मदिन मुबारक',
    decor: ElementShape.confetti,
  ),
  CategoryPreset(
    id: 'festival',
    layouts: [
      LayoutType.traditional,
      LayoutType.quoteOnly,
      LayoutType.circlePhotoCenterQuote,
      LayoutType.fullImageQuoteOverlay,
    ],
    fonts: FontPair(display: 'Yatra One', body: 'Mukta', script: 'Kalam'),
    photoShape: ImageShape.circle,
    frameStyle: PhotoFrameStyle.gold,
    nameStyle: NameStyle.plain,
    greetingEn: 'Festival',
    greetingHi: 'त्योहार',
    decor: ElementShape.sparkle,
  ),
  CategoryPreset(
    id: 'love',
    layouts: [
      LayoutType.fullImageQuoteOverlay,
      LayoutType.photoQuoteSignature,
      LayoutType.circlePhotoCenterQuote,
      LayoutType.quoteOnly,
    ],
    fonts: FontPair(display: 'Dancing Script', body: 'Poppins', script: 'Dancing Script'),
    photoShape: ImageShape.oval,
    photoFramed: false,
    softEdge: 26,
    nameStyle: NameStyle.dash,
    greetingEn: 'Love',
    greetingHi: 'प्यार',
    decor: ElementShape.heart,
  ),
  CategoryPreset(
    id: 'heartbreak',
    layouts: [
      LayoutType.minimalText,
      LayoutType.quoteOnly,
      LayoutType.fullImageQuoteOverlay,
    ],
    fonts: FontPair(display: 'Playfair Display', body: 'Mukta', script: 'Caveat'),
    photoShape: ImageShape.roundedRectangle,
    photoFramed: false,
    softEdge: 30,
    nameStyle: NameStyle.dash,
    greetingEn: 'Untold',
    greetingHi: 'अनकही',
  ),
  CategoryPreset(
    id: 'friendship',
    layouts: [
      LayoutType.photoQuoteSignature,
      LayoutType.fullImageQuoteOverlay,
      LayoutType.largeQuoteSmallPhoto,
      LayoutType.minimalText,
    ],
    fonts: FontPair(display: 'Baloo 2', body: 'Poppins', script: 'Caveat'),
    photoShape: ImageShape.roundedRectangle,
    frameStyle: PhotoFrameStyle.thin,
    nameStyle: NameStyle.dash,
    greetingEn: 'Friendship',
    greetingHi: 'दोस्ती',
    decor: ElementShape.sparkle,
  ),
  CategoryPreset(
    id: 'wishes',
    layouts: [
      LayoutType.quoteOnly,
      LayoutType.largeQuoteSmallPhoto,
      LayoutType.traditional,
      LayoutType.photoQuoteSignature,
    ],
    fonts: FontPair(display: 'Playfair Display', body: 'Montserrat', script: 'Dancing Script'),
    photoShape: ImageShape.circle,
    frameStyle: PhotoFrameStyle.doubleLine,
    nameStyle: NameStyle.by,
    greetingEn: 'Best Wishes',
    greetingHi: 'शुभकामनाएँ',
    decor: ElementShape.ribbon,
  ),
  CategoryPreset(
    id: 'nature',
    layouts: [
      LayoutType.fullImageQuoteOverlay,
      LayoutType.minimalText,
      LayoutType.quoteOnly,
      LayoutType.largeQuoteSmallPhoto,
    ],
    fonts: FontPair(display: 'Roboto Slab', body: 'Montserrat', script: 'Caveat'),
    photoShape: ImageShape.roundedRectangle,
    photoFramed: false,
    softEdge: 24,
    nameStyle: NameStyle.dash,
    greetingEn: 'Nature',
    greetingHi: 'प्रकृति',
    decor: ElementShape.leaf,
  ),
  CategoryPreset(
    id: 'minimal',
    layouts: [
      LayoutType.minimalText,
      LayoutType.quoteOnly,
      LayoutType.modernPremium,
    ],
    fonts: FontPair(display: 'Montserrat', body: 'Montserrat', script: 'Caveat'),
    photoShape: ImageShape.square,
    frameStyle: PhotoFrameStyle.thin,
    nameStyle: NameStyle.plain,
    greetingEn: 'Minimal',
    greetingHi: 'मिनिमल',
  ),
  CategoryPreset(
    id: 'premium_dark',
    layouts: [
      LayoutType.modernPremium,
      LayoutType.quoteOnly,
      LayoutType.minimalText,
      LayoutType.circlePhotoCenterQuote,
    ],
    fonts: FontPair(display: 'Cinzel', body: 'Montserrat', script: 'Caveat'),
    photoShape: ImageShape.square,
    frameStyle: PhotoFrameStyle.gold,
    nameStyle: NameStyle.plain,
    greetingEn: 'Classic',
    greetingHi: 'क्लासिक',
    decor: ElementShape.diamond,
  ),
];

CategoryPreset categoryPreset(String id) {
  for (final p in kCategoryPresets) {
    if (p.id == id) return p;
  }
  return kCategoryPresets.first;
}

/// Which options a template exposes, by layout — varied on purpose so the
/// catalogue mixes "quote only" cards with fully customisable ones.
/// [variant] alternates between two choices for the same layout.
TemplateCapabilities capabilitiesFor(LayoutType layout, int variant) {
  switch (layout) {
    case LayoutType.quoteOnly:
      return variant.isEven
          ? TemplateCapabilities.quoteOnly
          : TemplateCapabilities.backgroundQuote;
    case LayoutType.minimalText:
      return variant.isEven
          ? TemplateCapabilities.quoteName
          : TemplateCapabilities.backgroundQuote;
    case LayoutType.fullImageQuoteOverlay:
      return TemplateCapabilities.photoQuote;
    case LayoutType.largeQuoteSmallPhoto:
      return variant.isEven
          ? TemplateCapabilities.photoQuoteName
          : TemplateCapabilities.full;
    case LayoutType.circlePhotoCenterQuote:
      return TemplateCapabilities.full;
    case LayoutType.photoQuoteSignature:
      return TemplateCapabilities.photoQuoteName;
    case LayoutType.traditional:
      return variant.isEven
          ? TemplateCapabilities.photoName
          : TemplateCapabilities.photoQuoteName;
    case LayoutType.modernPremium:
      return TemplateCapabilities.full;
  }
}
