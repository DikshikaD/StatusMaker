/// Category-matched photo backgrounds for the editor's Background sheet.
///
/// These are bundled assets under `assets/backgrounds/<folder>/` (10 per
/// category), so they load instantly and work offline. Each design is kept
/// deliberately calm — soft gradients with a light, blurred motif and a gentle
/// vignette — and the editor also paints a subtle scrim over image backgrounds
/// (see TemplateBackground), so overlaid text always stays readable.
library;

const String _root = 'assets/backgrounds';

/// Folder (and filename prefix) each app category maps to. Hindi-flavoured
/// aliases reuse a fitting theme.
String _folderFor(String? category) {
  switch (category) {
    case 'Good Morning':
    case 'Morning':
    case 'Suprabhat':
      return 'morning';
    case 'Love':
      return 'love';
    case 'Birthday':
      return 'birthday';
    case 'Festival':
      return 'festival';
    case 'Motivation':
    case 'Suvichar':
      return 'motivation';
    case 'Devotional':
      return 'devotional';
    case 'Good Night':
      return 'goodnight';
    default:
      return 'general';
  }
}

/// The 10 bundled background image asset paths for [category].
List<String> backgroundImagesForCategory(String? category) {
  final folder = _folderFor(category);
  return [
    for (var i = 1; i <= 10; i++)
      '$_root/$folder/${folder}_${i.toString().padLeft(2, '0')}.jpg',
  ];
}
