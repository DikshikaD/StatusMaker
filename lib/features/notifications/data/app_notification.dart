import 'package:flutter/foundation.dart';
import 'package:status_maker/core/supabase/supabase_service.dart';
import 'package:status_maker/features/statuses/data/saved_status.dart';
import 'package:status_maker/features/statuses/data/status_repository.dart';

/// One row of the `notifications` table, with the status it is about embedded
/// (see supabase/notifications.sql). The same rows drive the push Edge
/// Function, so the list in Settings → Notifications always matches what was
/// pushed to the phone.
class AppNotification {
  final String id;

  /// 'like' or 'remix' today.
  final String type;
  final DateTime createdAt;
  final bool isRead;

  /// Null when the status was deleted after the notification was created
  /// (`status_id` is "on delete cascade", but the embed can still come back
  /// empty between the delete and the cascade, or for a private row).
  final SavedStatus? status;

  const AppNotification({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.status,
  });

  /// The status title, or null when there is none to show.
  String? get title {
    final t = status?.title?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  /// The quote on the status: the first non-empty text layer of its design.
  /// Null when the status has no text (image-only) or was deleted.
  String? get quote {
    final texts = status?.design['texts'];
    if (texts is! List) return null;
    for (final t in texts) {
      if (t is! Map) continue;
      final s = t['text']?.toString().trim();
      if (s != null && s.isNotEmpty) return s.replaceAll('\n', ' ');
    }
    return null;
  }

  factory AppNotification.fromRow(Map<String, dynamic> row) {
    final statusRow = row['statuses'];
    return AppNotification(
      id: row['id'] as String,
      type: row['type']?.toString() ?? '',
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
      isRead: row['read_at'] != null,
      status: statusRow is Map
          ? SavedStatus.fromRow(statusRow.cast<String, dynamic>())
          : null,
    );
  }
}

/// Reads the current user's notifications. RLS restricts the table to the
/// recipient, so no user filter is needed on the queries themselves — but the
/// mark-as-read update filters on it anyway so a bug can never widen it.
class NotificationRepository {
  static const _table = 'notifications';

  /// The embed asks for exactly what the list needs. `design` is included
  /// only to pull the quote out of it (see [AppNotification.quote]).
  static const _columns =
      'id, type, status_id, read_at, created_at, '
      'statuses(id, user_id, title, category, design, thumb_url, is_public, '
      'remix_of, likes_count, created_at)';

  /// Newest first. Throws on failure so the screen can show Retry.
  Future<List<AppNotification>> fetch({int limit = 100}) async {
    if (!await SupabaseService.ensureReady()) {
      throw StatusRepositoryException('Couldn\'t load notifications.');
    }
    try {
      final rows = await SupabaseService.client
          .from(_table)
          .select(_columns)
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(StatusRepository.readTimeout);
      return (rows as List)
          .map((r) => AppNotification.fromRow((r as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      debugPrint('NotificationRepository.fetch failed: $e');
      throw StatusRepositoryException('Couldn\'t load notifications.');
    }
  }

  /// How many are unread — drives the badge on the Settings row. Returns 0
  /// rather than throwing: a badge is not worth an error state.
  Future<int> unreadCount() async {
    if (!await SupabaseService.ensureReady()) return 0;
    try {
      final count = await SupabaseService.client
          .from(_table)
          .count()
          .isFilter('read_at', null)
          .timeout(StatusRepository.readTimeout);
      return count;
    } catch (e) {
      debugPrint('NotificationRepository.unreadCount failed: $e');
      return 0;
    }
  }

  /// Marks everything unread as read. Best-effort: opening the list is what
  /// matters to the user, a failed write here just leaves the badge on.
  Future<void> markAllRead() async {
    final uid = SupabaseService.userId;
    if (uid == null || !await SupabaseService.ensureReady()) return;
    try {
      await SupabaseService.client
          .from(_table)
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('recipient_id', uid)
          .isFilter('read_at', null)
          .timeout(StatusRepository.readTimeout);
    } catch (e) {
      debugPrint('NotificationRepository.markAllRead failed: $e');
    }
  }
}
