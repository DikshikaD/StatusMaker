import 'package:flutter/services.dart';

/// Lists bundled background images under `assets/categories/<folder>/` at
/// runtime by reading the asset manifest. Because it reads the manifest (not a
/// hard-coded list), ANY image you drop into a category folder — and register
/// the folder in pubspec.yaml — automatically shows up in the Background sheet.
/// No code change needed to add more backgrounds.

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

/// Sorted image asset paths inside `assets/categories/<folder>/`.
Future<List<String>> categoryBackgroundAssets(String folder) async {
  final all = await _allAssets();
  final prefix = 'assets/categories/$folder/';
  final list = all
      .where((a) =>
          a.startsWith(prefix) &&
          _imageExt.any((e) => a.toLowerCase().endsWith(e)))
      .toList()
    ..sort();
  return list;
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
