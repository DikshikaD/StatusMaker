import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:status_maker/core/supabase/supabase_service.dart';
import 'package:status_maker/features/statuses/data/saved_status.dart';

/// Why a post is being reported. The `name` is what the `reports.reason` check
/// constraint accepts (see supabase/migrations/0003_*.sql).
enum ReportReason { spam, sexual, hate, violence, other }

/// Reporting and on-device hiding of other people's posts.
///
/// Play's user-generated-content policy needs two things: users can flag
/// objectionable content, and they can stop seeing it. Reports go to the
/// `reports` table (three distinct reporters auto-hide a post for everyone,
/// server-side); hiding a post or blocking a creator is local to this device and
/// takes effect immediately, without waiting for any review.
class ModerationStore extends ChangeNotifier {
  ModerationStore._();
  static final ModerationStore instance = ModerationStore._();

  static const _hiddenKey = 'mod_hidden_posts';
  static const _blockedKey = 'mod_blocked_users';

  final Set<String> _hiddenPosts = <String>{};
  final Set<String> _blockedUsers = <String>{};
  Future<void>? _loading;

  /// Reads the saved lists once. Safe to call from many places.
  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hiddenPosts.addAll(prefs.getStringList(_hiddenKey) ?? const []);
      _blockedUsers.addAll(prefs.getStringList(_blockedKey) ?? const []);
      notifyListeners();
    } catch (_) {
      // Unreadable prefs just mean nothing is hidden yet.
    }
  }

  /// True when [s] should not be shown on this device.
  bool isHidden(SavedStatus s) =>
      _hiddenPosts.contains(s.id) ||
      (s.userId != null && _blockedUsers.contains(s.userId));

  /// [list] without anything the user has hidden or blocked.
  List<SavedStatus> visible(List<SavedStatus> list) =>
      _hiddenPosts.isEmpty && _blockedUsers.isEmpty
          ? list
          : list.where((s) => !isHidden(s)).toList();

  Future<void> hidePost(String statusId) async {
    if (!_hiddenPosts.add(statusId)) return;
    notifyListeners();
    await _save(_hiddenKey, _hiddenPosts);
  }

  Future<void> blockUser(String userId) async {
    if (!_blockedUsers.add(userId)) return;
    notifyListeners();
    await _save(_blockedKey, _blockedUsers);
  }

  Future<void> _save(String key, Set<String> value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key, value.toList());
    } catch (_) {
      // Best effort: the in-memory list still applies for this session.
    }
  }

  /// Files a report and hides the post on this device. Throws when the report
  /// couldn't be sent, so the caller can tell the user instead of pretending.
  Future<void> report(String statusId, ReportReason reason) async {
    if (!await SupabaseService.ensureReady()) {
      throw StateError('backend not ready');
    }
    final uid = SupabaseService.userId;
    if (uid == null) throw StateError('not signed in');
    try {
      await SupabaseService.client.from('reports').insert({
        'reporter_id': uid,
        'status_id': statusId,
        'reason': reason.name,
      }).timeout(const Duration(seconds: 15));
    } catch (e) {
      // 23505 = already reported by this user: the goal is met, so don't fail.
      if (!e.toString().contains('23505')) rethrow;
    }
    await hidePost(statusId);
  }

  /// Forgets everything (used after "Delete my data").
  Future<void> clear() async {
    _hiddenPosts.clear();
    _blockedUsers.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hiddenKey);
      await prefs.remove(_blockedKey);
    } catch (_) {}
  }
}
