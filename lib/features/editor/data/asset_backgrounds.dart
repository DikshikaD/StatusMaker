import 'package:flutter/services.dart';

/// Lists bundled image assets at runtime by reading the asset manifest, so any
/// image dropped into a registered folder shows up without a code change.
///
/// Note: category backgrounds are NOT listed here any more — they moved to the
/// `category-backgrounds` Supabase bucket (see remote_backgrounds.dart), so
/// only the sticker helper below remains.

List<String>? _cache;

const List<String> _imageExt = ['.jpg', '.jpeg', '.png', '.webp'];

Future<List<String>> _allAssets() async {
  if (_cache != null) return _cache!;
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    _cache = manifest.listAssets();
  } catch (_) {
    _cache = const [];
  }
  return _cache!;
}

/// Sorted image asset paths inside `assets/stickers/` — illustrated
/// character/emoji-style stickers (distinct from the code-drawn shapes in
/// ElementPainter). Any image dropped into that folder shows up automatically
/// in the Elements sheet's Stickers tab, same as the category backgrounds
/// above — no code change needed to add more.
Future<List<String>> stickerAssets() async {
  final all = await _allAssets();
  const prefix = 'assets/stickers/';
  final list = all
      .where((a) =>
          a.startsWith(prefix) &&
          _imageExt.any((e) => a.toLowerCase().endsWith(e)))
      .toList()
    ..sort();
  return list;
}
