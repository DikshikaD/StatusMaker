import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:status_maker/features/statuses/data/saved_status.dart';
import 'package:status_maker/features/statuses/data/status_repository.dart';

/// App-wide like state.
///
/// Likes were previously a `bool` living inside each feed card's State, so the
/// heart reset the moment the card was rebuilt and the count was a fake local
/// +1 that never reached the backend. This owns the truth instead: which
/// statuses the signed-in user has liked, and the current count per status.
///
/// A single shared instance means every surface agrees — liking on the Home feed
/// immediately lights up the same status in "Saved Templates", because both read
/// this rather than their own copy.
class LikesStore extends ChangeNotifier {
  LikesStore._();
  static final LikesStore instance = LikesStore._();

  final StatusRepository _repo = StatusRepository();

  final Set<String> _liked = <String>{};

  /// Server-known count per status, kept separately from [SavedStatus] so an
  /// optimistic toggle survives the card rebuilding.
  final Map<String, int> _counts = <String, int>{};

  /// Ids with a like/unlike still in flight — used to ignore repeat taps.
  final Set<String> _pending = <String>{};

  bool _loaded = false;
  Future<void>? _loading;

  bool isLiked(String statusId) => _liked.contains(statusId);

  /// Every liked id. Read-only — mutate through [toggle].
  Set<String> get likedIds => UnmodifiableSetView(_liked);

  /// The count to display: whatever we last learned from the server for this
  /// status, adjusted by any toggle since, falling back to the row's own value.
  int countFor(SavedStatus status) => _counts[status.id] ?? status.likesCount;

  /// Loads the user's likes once per session. Safe to call from many places at
  /// once — concurrent callers await the same request.
  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final ids = await _repo.fetchLikedIds();
      // null means the read itself failed — leave `_loaded` false so a later
      // call retries instead of caching "nothing liked" for the session.
      if (ids == null) return;
      _liked
        ..clear()
        ..addAll(ids);
      _loaded = true;
      notifyListeners();
    } finally {
      _loading = null;
    }
  }

  /// Records the counts a fetch just returned, so the display starts from server
  /// truth (the DB trigger maintains `likes_count`) rather than a stale local
  /// adjustment.
  void syncFromRows(Iterable<SavedStatus> rows) {
    var changed = false;
    for (final r in rows) {
      if (_counts[r.id] != r.likesCount) {
        _counts[r.id] = r.likesCount;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// Toggles the like, updating the UI immediately and rolling back if the write
  /// fails — so the heart never shows a state the backend didn't accept.
  Future<void> toggle(SavedStatus status) async {
    final id = status.id;
    if (_pending.contains(id)) return;

    final wasLiked = _liked.contains(id);
    final previousCount = countFor(status);
    final nowLiked = !wasLiked;

    _pending.add(id);
    if (nowLiked) {
      _liked.add(id);
    } else {
      _liked.remove(id);
    }
    _counts[id] = (previousCount + (nowLiked ? 1 : -1)).clamp(0, 1 << 31);
    notifyListeners();

    try {
      await _repo.setLike(id, nowLiked);
    } catch (_) {
      if (wasLiked) {
        _liked.add(id);
      } else {
        _liked.remove(id);
      }
      _counts[id] = previousCount;
      notifyListeners();
      rethrow;
    } finally {
      _pending.remove(id);
    }
  }
}
