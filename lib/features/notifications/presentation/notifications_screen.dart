import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/utils/page_transitions.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/features/notifications/data/app_notification.dart';
import 'package:status_maker/features/preview/presentation/template_detail_screen.dart';
import 'package:status_maker/shared/widgets/app_shimmer.dart';
import 'package:status_maker/shared/widgets/empty_state.dart';

/// Settings → Notifications: everything the user has been notified about
/// (likes and remixes of their statuses), newest first.
///
/// Each row shows the status title, its quote underneath, and when it
/// happened. Tapping opens the status, the same destination a push tap lands
/// on. Opening this screen marks everything as read.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepository _repo = NotificationRepository();

  List<AppNotification> _items = const [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final items = await _repo.fetch();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
      // After the list is on screen, so the unread dots are visible for this
      // visit and gone on the next — like a mail inbox.
      if (items.any((n) => !n.isRead)) _repo.markAllRead();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  void _open(AppNotification n) {
    final status = n.status;
    if (status == null) return;
    Navigator.push(
      context,
      FadeSlidePageRoute(page: TemplateDetailScreen(status: status)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(S.t('notifications')),
        centerTitle: false,
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(20.w),
        itemCount: 6,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (_, __) => const _TileShimmer(),
      );
    }
    if (_failed) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        title: S.t('something_wrong'),
        message: S.t('try_again_msg'),
        actionLabel: S.t('retry'),
        onAction: _load,
      );
    }
    if (_items.isEmpty) {
      return EmptyState(
        icon: Icons.notifications_none_rounded,
        title: S.t('notif_empty_title'),
        message: S.t('notif_empty_msg'),
      );
    }
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: EdgeInsets.all(20.w),
        itemCount: _items.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (_, i) {
          final n = _items[i];
          return _NotificationTile(
            notification: n,
            onTap: n.status == null ? null : () => _open(n),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  const _NotificationTile({required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final title = n.title ??
        (n.status == null ? S.t('notif_status_gone') : S.t('notif_untitled'));
    final quote = n.quote;
    final unread = !n.isRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: unread ? AppColors.accent.withValues(alpha: 0.5) : AppColors.border,
              width: unread ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Thumb(url: n.status?.thumbUrl, type: n.type),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          SizedBox(width: 8.w),
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (quote != null) ...[
                      SizedBox(height: 3.h),
                      Text(
                        quote,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          height: 1.3,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(
                          _iconFor(n.type),
                          size: 13.w,
                          color: AppColors.accent,
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            _labelFor(n.type),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        Text(
                          '  ·  ${relativeTime(n.createdAt)}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                SizedBox(width: 6.w),
                Icon(Icons.chevron_right,
                    color: AppColors.textSecondary, size: 22.w),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(String type) => switch (type) {
        'like' => Icons.favorite_rounded,
        'remix' => Icons.auto_awesome_rounded,
        _ => Icons.notifications_rounded,
      };

  static String _labelFor(String type) => switch (type) {
        'like' => S.t('notif_like_label'),
        'remix' => S.t('notif_remix_label'),
        _ => S.t('notifications'),
      };
}

/// Small 9:16 preview of the status, with the notification-type icon as a
/// fallback when there is no thumbnail (or the status is gone).
class _Thumb extends StatelessWidget {
  final String? url;
  final String type;

  const _Thumb({required this.url, required this.type});

  @override
  Widget build(BuildContext context) {
    final w = 44.w;
    final h = 64.h;
    final radius = BorderRadius.circular(10.r);
    final fallback = Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.accentGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
      ),
      child: Icon(_NotificationTile._iconFor(type),
          color: Colors.white, size: 20.w),
    );
    if (url == null || url!.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: url!,
        width: w,
        height: h,
        fit: BoxFit.cover,
        placeholder: (_, __) => ShimmerBox(width: w, height: h, radius: 10.r),
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}

class _TileShimmer extends StatelessWidget {
  const _TileShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ShimmerBox(width: 44.w, height: 64.h, radius: 10.r),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 160.w, height: 14.h),
                  SizedBox(height: 8.h),
                  ShimmerBox(width: double.infinity, height: 12.h),
                  SizedBox(height: 8.h),
                  ShimmerBox(width: 90.w, height: 11.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Just now", "5 min ago", "Yesterday", … in the app language, falling back
/// to a plain date past a week. Kept here rather than pulling in `intl` for
/// one screen.
String relativeTime(DateTime when, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(when);
  if (diff.inMinutes < 1) return S.t('time_just_now');
  if (diff.inHours < 1) {
    return S.t('time_min_ago').replaceAll('{n}', '${diff.inMinutes}');
  }
  if (diff.inDays < 1) {
    return S.t('time_hr_ago').replaceAll('{n}', '${diff.inHours}');
  }
  if (diff.inDays == 1) return S.t('time_yesterday');
  if (diff.inDays < 7) {
    return S.t('time_days_ago').replaceAll('{n}', '${diff.inDays}');
  }
  final d = when.day.toString().padLeft(2, '0');
  final m = when.month.toString().padLeft(2, '0');
  return '$d/$m/${when.year}';
}
