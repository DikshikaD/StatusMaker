import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:status_maker/core/supabase/supabase_config.dart';

/// Category backgrounds live in the public `category-backgrounds` Supabase
/// bucket instead of being bundled in the APK — 126 MB of PNGs used to ship
/// with the app. See supabase/schema.sql for the bucket + its layout:
///
///   manifest.json          — {version, categories:[{key, files:[...]}]}
///   thumb/<cat>/<file>.jpg — ~400px, ~24 KB. What the picker grid shows.
///   full/<cat>/<file>.jpg  — ~1600px, ~230 KB. Fetched only once picked.
///
/// The split matters for cost, not just speed: browsing every category pulls
/// ~1.7 MB of thumbs rather than ~17 MB of full-size images, which is the
/// difference between ~3,000 and ~300 users inside Supabase's free egress tier.
/// The images are uploaded with `max-age=31536000, immutable` and the manifest
/// with `max-age=300`, so a device downloads any given image once, and new
/// backgrounds still appear within ~5 minutes without an app release.
class RemoteBackgrounds {
  RemoteBackgrounds._();

  static const String bucket = 'category-backgrounds';

  /// Built by string concatenation rather than the Supabase SDK so it works
  /// before (or without) a session — the bucket is public.
  static const String _base =
      '${SupabaseConfig.url}/storage/v1/object/public/$bucket';

  static String thumbUrl(String category, String file) =>
      '$_base/thumb/$category/$file';

  static String fullUrl(String category, String file) =>
      '$_base/full/$category/$file';

  /// Cached for the process lifetime — the manifest is ~2 KB but there's no
  /// reason to re-fetch it every time the Background sheet opens.
  static Map<String, List<String>>? _cache;

  /// Category key -> filenames, in manifest order. Empty when offline or
  /// unconfigured; callers surface that as a retry state rather than an error,
  /// since there are no bundled fallbacks to fall back to.
  ///
  /// Pass [forceRefresh] to drop the cache (used by the sheet's Retry action).
  static Future<Map<String, List<String>>> load(
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;
    if (!SupabaseConfig.url.startsWith('http')) return const {};

    try {
      // Plain HTTPS against the *public* object endpoint — deliberately not
      // the Supabase SDK's storage.download(), which calls the authenticated
      // endpoint and would therefore need both a live session and an RLS
      // select policy on storage.objects even though the bucket is public.
      final res = await http
          .get(Uri.parse('$_base/manifest.json'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        debugPrint('RemoteBackgrounds: manifest HTTP ${res.statusCode}');
        return const {};
      }
      final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final out = <String, List<String>>{};
      for (final c in (json['categories'] as List<dynamic>)) {
        final m = c as Map<String, dynamic>;
        final files = (m['files'] as List<dynamic>).cast<String>();
        if (files.isNotEmpty) out[m['key'] as String] = files;
      }
      _cache = out;
      return out;
    } catch (e) {
      debugPrint('RemoteBackgrounds: manifest load failed — $e');
      return const {};
    }
  }
}
