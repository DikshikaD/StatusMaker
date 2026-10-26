import 'dart:async';
import 'dart:io';
import 'dart:math';
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

final Random _secureRandom = Random.secure();

/// Object name for an upload. The buckets are public, so the name is the only
/// thing keeping a private status's image from being fetched by someone who
/// knows the owner's id (it is visible in the URLs of their posted statuses).
/// A timestamp + counter is guessable; 96 random bits are not.
@visibleForTesting
String uniqueStorageName(String ext) {
  final rnd = List.generate(12, (_) => _secureRandom.nextInt(256))
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${DateTime.now().microsecondsSinceEpoch}_$rnd.$ext';
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

  /// Upper bound on connecting before a write. Longer than [readTimeout]: a
  /// write is something the user explicitly asked for, so it's worth waiting
  /// a little more before giving up — but never indefinitely.
  static const Duration writeReadyTimeout = Duration(seconds: 20);

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
  ///
  /// Bounded by [writeReadyTimeout] for the same reason reads are bounded (see
  /// [readTimeout]): offline with an expired token, ensureReady() sits in the
  /// auth client's refresh-retry loop, and an unbounded wait here left the
  /// Save spinner — or an optimistic like — pending forever.
  Future<void> _requireReady() async {
    var timedOut = false;
    final ok = await SupabaseService.ensureReady().timeout(
      writeReadyTimeout,
      onTimeout: () {
        timedOut = true;
        return false;
      },
    );
    if (timedOut) {
      throw StatusRepositoryException(
          'Couldn\'t connect. Check your internet and try again.');
    }
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

  String _uniqueName(String ext) => uniqueStorageName(ext);

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

  /// Permanently deletes everything this user has: their files in both storage
  /// buckets, then (through `delete_my_account`, see migrations/0003) their
  /// statuses, likes, notifications, device tokens and the account itself.
  ///
  /// Files go first and through the Storage API on purpose — removing
  /// `storage.objects` rows from SQL leaves the stored bytes behind. If any
  /// step fails nothing is half-reported: the exception reaches the caller and
  /// the account is only removed by the final RPC.
  Future<void> deleteAllMyData() async {
    await _requireReady();
    final uid = SupabaseService.userId!;
    try {
      for (final bucket in [_assetsBucket, _thumbsBucket]) {
        final files = _db.storage.from(bucket);
        // Paged, and capped so a policy that silently refuses deletes can't
        // spin forever on the same page.
        for (var page = 0; page < 100; page++) {
          final batch = await files.list(
            path: uid,
            searchOptions: const SearchOptions(limit: 1000),
          );
          if (batch.isEmpty) break;
          await files.remove([for (final f in batch) '$uid/${f.name}']);
          if (batch.length < 1000) break;
        }
      }
      await _db.rpc('delete_my_account');
    } catch (e) {
      debugPrint('StatusRepository.deleteAllMyData failed: $e');
      throw StatusRepositoryException('Couldn\'t delete your data.');
    }
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// How many posts the Home feed loads per page.
  static const int feedPageSize = 10;

  /// Public feed for the Home tab, newest first, optionally filtered by category.
  ///
  /// Paged by keyset, not offset: [before] is the `created_at` of the last post
  /// already shown, so posts published while the user scrolls can't shift the
  /// window and repeat (or skip) a card the way `range()` would. A page shorter
  /// than [limit] means the feed has no more.
  Future<List<SavedStatus>> fetchPublic({
    String? category,
    int limit = feedPageSize,
    DateTime? before,
  }) async {
    if (!await _readyWithin()) throw StatusRepositoryException('Couldn\'t load the feed.');
    try {
      var query = _db.from(_table).select().eq('is_public', true);
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      if (before != null) {
        query = query.lt('created_at', before.toUtc().toIso8601String());
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
        // ignoreDuplicates makes this ON CONFLICT DO NOTHING. A plain upsert
        // becomes DO UPDATE, and `likes` has no update policy — so re-liking
        // a status (e.g. one tapped before the liked ids had loaded) failed
        // RLS and rolled the heart back with an error.
        await _db.from(_likesTable).upsert(
          {'user_id': uid, 'status_id': statusId},
          onConflict: 'user_id,status_id',
          ignoreDuplicates: true,
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

  /// JPEG, PNG, WebP, GIF or HEIC/HEIF, by magic number.
  static bool _looksLikeImage(Uint8List b) {
    bool at(int offset, List<int> sig) {
      if (b.length < offset + sig.length) return false;
      for (var i = 0; i < sig.length; i++) {
        if (b[offset + i] != sig[i]) return false;
      }
      return true;
    }

    return at(0, const [0xFF, 0xD8, 0xFF]) || // JPEG
        at(0, const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) || // PNG
        (at(0, const [0x52, 0x49, 0x46, 0x46]) && // RIFF....WEBP
            at(8, const [0x57, 0x45, 0x42, 0x50])) ||
        at(0, const [0x47, 0x49, 0x46, 0x38]) || // GIF8
        (at(4, const [0x66, 0x74, 0x79, 0x70]) && _heifBrand(b)); // HEIC/HEIF
  }

  /// `ftyp` is shared with MP4/MOV, so check the brand too — videos aren't
  /// images and shouldn't be uploaded as one.
  static bool _heifBrand(Uint8List b) {
    if (b.length < 12) return false;
    final brand = String.fromCharCodes(b.sublist(8, 12));
    return const {'heic', 'heix', 'heim', 'heis', 'mif1', 'msf1', 'avif'}
        .contains(brand);
  }

  Future<String?> _tryUpload(String filePath, String uid) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      // Paths in a design come from its JSON — and a remix starts from someone
      // else's public design. Only ever upload actual image data, so a crafted
      // design pointing at a private app file (shared_prefs holds the session)
      // can't get that file published from the remixer's phone.
      if (!_looksLikeImage(bytes)) {
        debugPrint('StatusRepository image upload refused ($filePath): '
            'not an image');
        return null;
      }
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
