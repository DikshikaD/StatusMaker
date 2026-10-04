import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:status_maker/core/supabase/supabase_config.dart';
import 'package:status_maker/core/supabase/supabase_service.dart';
import 'package:status_maker/features/editor/data/status_design.dart';
import 'package:status_maker/features/statuses/data/saved_status.dart';

/// Why the last read failed, so screens can say something more useful than
/// "something went wrong" — a server that can't be reached (no connectivity,
/// or the project paused / renamed) is a different problem from a query error.
enum BackendFailure { none, unreachable, timeout, error }

/// Thrown when a backend action can't run (e.g. Supabase not configured, no
/// session, or a network/permission error). The UI shows [message] in a snackbar.
class StatusRepositoryException implements Exception {
  final String message;
  StatusRepositoryException(this.message);
  @override
  String toString() => message;
}

/// All reads/writes for the `statuses` table + the two storage buckets live
/// here, so screens never touch the Supabase SDK directly.
///
/// Save flow (matches supabase/schema.sql):
///   1. Snapshot the editor  -> StatusDesign.toJson()  (the editable jsonb).
///   2. Upload any local user photos to `status-assets/<uid>/...` and rewrite
///      the design's paths to public URLs, so the design is portable.
///   3. Upload the rendered thumbnail PNG to `thumbnails/<uid>/...`.
///   4. Insert a row (is_public=false on Save) — or update it on Post/re-save.
///   5. Post flips is_public=true so it appears on the public Home feed.
class StatusRepository {
  /// Upper bound on any read. The auth client retries an expired-token
  /// refresh almost indefinitely while offline (gotrue: 999 attempts, up to
  /// 10 s apart), and a PostgREST query waits on that refresh — so without
  /// a bound a feed load on a phone with no signal never completes and the
  /// screen shimmers forever. Ten seconds is long enough for a slow mobile
  /// connection and short enough that the Retry state appears while the user
  /// is still looking.
  static const Duration readTimeout = Duration(seconds: 10);

  /// Set by every read path; `none` after a success.
  static BackendFailure lastFailure = BackendFailure.none;

  static const _table = 'statuses';
  static const _likesTable = 'likes';
  static const _assetsBucket = 'status-assets';
  static const _thumbsBucket = 'thumbnails';

  SupabaseClient get _db => SupabaseService.client;

  /// Guard used by every write. Tries to (re)connect and sign in on demand, so
  /// a failed startup doesn't permanently disable saving. Throws the *actual*
  /// reason (auth disabled, bad key, real network error) rather than a generic
  /// "no internet" message.
  Future<void> _requireReady() async {
    final ok = await SupabaseService.ensureReady();
    if (!ok || SupabaseService.userId == null) {
      throw StatusRepositoryException(SupabaseService.statusMessage);
    }
  }

  /// [SupabaseService.ensureReady] bounded by [readTimeout]. Reads treat a
  /// timeout as "not ready" (the caller surfaces its own error / retry state)
  /// rather than waiting out the auth client's retry loop.
  ///
  /// Preceded by a DNS reachability check: with no connectivity at all the
  /// lookup fails in milliseconds, so the Retry state appears at once instead
  /// of after the full timeout. A flaky-but-connected network passes the check
  /// and falls through to the normal bounded wait.
  Future<bool> _readyWithin() async {
    if (!await _hostReachable()) {
      lastFailure = BackendFailure.unreachable;
      return false;
    }
    final ready = await SupabaseService.ensureReady()
        .timeout(readTimeout, onTimeout: () => false);
    lastFailure = ready ? BackendFailure.none : BackendFailure.timeout;
    return ready;
  }

  /// Classifies an exception from a query and records it.
  void _recordFailure(Object e) {
    lastFailure = e is TimeoutException
        ? BackendFailure.timeout
        : (lastFailure == BackendFailure.unreachable
            ? BackendFailure.unreachable
            : BackendFailure.error);
  }

  static Future<bool> _hostReachable() async {
    try {
      final host = Uri.parse(SupabaseConfig.url).host;
      if (host.isEmpty) return false;
      final addresses = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 3));
      return addresses.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  int _seq = 0;
  String _uniqueName(String ext) =>
      '${DateTime.now().microsecondsSinceEpoch}_${_seq++}.$ext';

  // ---------------------------------------------------------------------------
  // Save / Post
  // ---------------------------------------------------------------------------

  /// Persists [design] + [thumbnailBytes]. When [existingId] is supplied the
  /// same row is updated (so tapping Save then Post doesn't create duplicates).
  /// [makePublic] sets is_public — false for a private Save, true for Post.
  Future<SavedStatus> saveDesign({
    required StatusDesign design,
    required Uint8List thumbnailBytes,
    String? title,
    String? category,
    bool makePublic = false,
    String? existingId,
    String? remixOf,
  }) async {
    await _requireReady();
    final uid = SupabaseService.userId!;

    // (2) Portable design: push local photos to storage, swap in public URLs.
    final designJson = design.toJson();
    await _uploadEmbeddedImages(designJson, uid);

    // (3) Thumbnail.
    final thumbUrl = await _uploadThumbnail(thumbnailBytes, uid);

    // (4/5) Insert or update the row.
    final payload = <String, dynamic>{
      'user_id': uid,
      'title': (title == null || title.trim().isEmpty) ? null : title.trim(),
      'category': (category == null || category.isEmpty) ? null : category,
      'design': designJson,
      'thumb_url': thumbUrl,
      // Post always publishes; a fresh insert takes makePublic as-is. But a
      // plain Save on an existing row must NOT touch is_public — otherwise
      // editing an already-posted status and tapping Save would silently
      // unpublish it from the feed.
      if (makePublic || existingId == null) 'is_public': makePublic,
      if (remixOf != null) 'remix_of': remixOf,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final Map<String, dynamic> row;
      if (existingId != null) {
        row = await _db
            .from(_table)
            .update(payload)
            .eq('id', existingId)
            .select()
            .single();
      } else {
        row = await _db.from(_table).insert(payload).select().single();
      }
      return SavedStatus.fromRow(row);
    } catch (e) {
      debugPrint('StatusRepository.saveDesign failed: $e');
      throw StatusRepositoryException('Couldn\'t save. Please try again.');
    }
  }

  /// Flip an existing row to public (used if we ever Post something already saved).
  Future<void> publish(String id) async {
    await _requireReady();
    try {
      await _db.from(_table).update({'is_public': true}).eq('id', id);
    } catch (e) {
      debugPrint('StatusRepository.publish failed: $e');
      throw StatusRepositoryException('Couldn\'t post. Please try again.');
    }
  }

  /// Delete one of the current user's creations. RLS ensures you can only
  /// delete your own rows.
  Future<void> delete(String id) async {
    await _requireReady();
    try {
      await _db.from(_table).delete().eq('id', id);
    } catch (e) {
      debugPrint('StatusRepository.delete failed: $e');
      throw StatusRepositoryException('Couldn\'t delete. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// Public feed for the Home tab, newest first, optionally filtered by category.
  Future<List<SavedStatus>> fetchPublic({String? category, int limit = 60}) async {
    if (!await _readyWithin()) throw StatusRepositoryException('Couldn\'t load the feed.');
    try {
      var query = _db.from(_table).select().eq('is_public', true);
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      final rows = await query
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(readTimeout);
      lastFailure = BackendFailure.none;
      return (rows as List)
          .map((r) => SavedStatus.fromRow((r as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      _recordFailure(e);
      debugPrint('StatusRepository.fetchPublic failed: $e');
      throw StatusRepositoryException('Couldn\'t load the feed.');
    }
  }

  /// The current user's own creations for the "My Creations" tab, newest first.
  Future<List<SavedStatus>> fetchMine({int limit = 100}) async {
    if (!await _readyWithin() || SupabaseService.userId == null) {
      throw StatusRepositoryException('Couldn\'t load your creations.');
    }
    try {
      final rows = await _db
          .from(_table)
          .select()
          .eq('user_id', SupabaseService.userId!)
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(readTimeout);
      return (rows as List)
          .map((r) => SavedStatus.fromRow((r as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      debugPrint('StatusRepository.fetchMine failed: $e');
      throw StatusRepositoryException('Couldn\'t load your creations.');
    }
  }

  /// A single status by id, or null if it doesn't exist (or is private and
  /// isn't the caller's own) — RLS enforces that, this just surfaces "not
  /// found" instead of throwing. Used to open the status a push notification
  /// (e.g. "someone liked your status") points at.
  Future<SavedStatus?> fetchById(String id) async {
    if (!await _readyWithin()) return null;
    try {
      final row = await _db
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle()
          .timeout(readTimeout);
      if (row == null) return null;
      return SavedStatus.fromRow((row as Map).cast<String, dynamic>());
    } catch (e) {
      debugPrint('StatusRepository.fetchById failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Likes
  //
  // `public.likes` is a (user_id, status_id) join table; a trigger keeps
  // `statuses.likes_count` in sync on insert/delete, so nothing here has to
  // touch the count itself. See supabase/schema.sql.
  // ---------------------------------------------------------------------------

  /// Status ids the current user has liked, most recently liked first.
  ///
  /// Returns null when the likes couldn't be read at all (no session yet, or a
  /// network error) — deliberately distinct from an empty list, which means "read
  /// fine, nothing liked". Callers use that to avoid caching a failed read as
  /// "this user has no likes" for the rest of the session.
  Future<List<String>?> fetchLikedIds({int limit = 200}) async {
    if (!await _readyWithin() || SupabaseService.userId == null) {
      return null;
    }
    try {
      final rows = await _db
          .from(_likesTable)
          .select('status_id')
          .eq('user_id', SupabaseService.userId!)
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(readTimeout);
      return (rows as List)
          .map((r) => (r as Map)['status_id'] as String)
          .toList();
    } catch (e) {
      debugPrint('StatusRepository.fetchLikedIds failed: $e');
      return null;
    }
  }

  /// Likes or unlikes [statusId] for the current user.
  ///
  /// Liking uses upsert so a double-tap can't fail on the primary key, which
  /// means the caller can treat this as idempotent.
  Future<void> setLike(String statusId, bool liked) async {
    await _requireReady();
    final uid = SupabaseService.userId!;
    try {
      if (liked) {
        await _db.from(_likesTable).upsert(
          {'user_id': uid, 'status_id': statusId},
          onConflict: 'user_id,status_id',
        );
      } else {
        await _db
            .from(_likesTable)
            .delete()
            .eq('user_id', uid)
            .eq('status_id', statusId);
      }
    } catch (e) {
      debugPrint('StatusRepository.setLike failed: $e');
      throw StatusRepositoryException('Couldn\'t update. Please try again.');
    }
  }

  /// The statuses the current user has liked — the "Saved Templates" tab.
  ///
  /// Two queries rather than a PostgREST embed: the ids come from `likes` (which
  /// gives the like order), then the rows are fetched by id and re-sorted to
  /// match. A liked status that has since been deleted or made private simply
  /// doesn't come back, and is skipped.
  Future<List<SavedStatus>> fetchLiked({int limit = 100}) async {
    final ids = await fetchLikedIds(limit: limit);
    if (ids == null || ids.isEmpty) return const [];
    try {
      final rows = await _db
          .from(_table)
          .select()
          .inFilter('id', ids)
          .timeout(readTimeout);
      final byId = <String, SavedStatus>{};
      for (final r in rows as List) {
        final status =
            SavedStatus.fromRow((r as Map).cast<String, dynamic>());
        byId[status.id] = status;
      }
      // Keep the order the user liked them in.
      return [
        for (final id in ids)
          if (byId[id] != null) byId[id]!,
      ];
    } catch (e) {
      debugPrint('StatusRepository.fetchLiked failed: $e');
      throw StatusRepositoryException('Couldn\'t load your saved templates.');
    }
  }

  // ---------------------------------------------------------------------------
  // Storage helpers
  // ---------------------------------------------------------------------------

  Future<String> _uploadThumbnail(Uint8List bytes, String uid) async {
    final path = '$uid/${_uniqueName('png')}';
    await _db.storage.from(_thumbsBucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
        );
    return _db.storage.from(_thumbsBucket).getPublicUrl(path);
  }

  /// Walks the design JSON, uploads every embedded *local* photo to
  /// `status-assets` and rewrites its path to the public URL in place. Bundled
  /// assets (assetPath) and already-remote URLs are left untouched. Best-effort:
  /// if one image fails to upload we keep its original path rather than abort.
  Future<void> _uploadEmbeddedImages(
      Map<String, dynamic> design, String uid) async {
    // Background photo.
    final bg = design['background'];
    if (bg is Map && _isLocalFile(bg['imagePath'] as String?)) {
      final url = await _tryUpload(bg['imagePath'] as String, uid);
      if (url != null) bg['imagePath'] = url;
    }
    // Floating photos.
    final images = design['images'];
    if (images is List) {
      for (final img in images) {
        if (img is Map && _isLocalFile(img['path'] as String?)) {
          final url = await _tryUpload(img['path'] as String, uid);
          if (url != null) img['path'] = url;
        }
      }
    }
  }

  bool _isLocalFile(String? p) {
    if (p == null || p.isEmpty) return false;
    if (p.startsWith('http')) return false; // already remote
    try {
      return File(p).existsSync();
    } catch (_) {
      return false;
    }
  }

  Future<String?> _tryUpload(String filePath, String uid) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final ext = filePath.split('.').last.toLowerCase();
      final safeExt = (ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'webp')
          ? ext
          : 'jpg';
      final path = '$uid/${_uniqueName(safeExt)}';
      await _db.storage.from(_assetsBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/${safeExt == 'jpg' ? 'jpeg' : safeExt}',
              upsert: true,
            ),
          );
      return _db.storage.from(_assetsBucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('StatusRepository image upload skipped ($filePath): $e');
      return null;
    }
  }
}
