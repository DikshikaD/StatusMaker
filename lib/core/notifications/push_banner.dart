import 'dart:async';

import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/utils/responsive.dart';

/// The heads-up notification tile shown when a push arrives while the app is
/// already open.
///
/// Android withholds the tray notification for foreground messages, so this
/// stands in for it. It deliberately looks like a system heads-up notification
/// — a card that drops in from the top, not a bottom SnackBar — because that
/// is what a notification arriving *is*, and the bottom of the screen is
/// already occupied by the nav bar and the editor toolbars.
///
/// Kept separate from [AppSnackBar]: that is for confirming something the user
/// just did (accent gradient, short, transient). This is an incoming message
/// from someone else, so it uses the surface palette and reads as content —
/// avatar, title, body, and an affordance to open it.
///
/// Takes an [OverlayState] rather than looking one up, so this file stays
/// independent of `PushService` (which owns the navigator key and imports it).
class PushBanner {
  PushBanner._();

  static OverlayEntry? _current;

  /// Which push types this tile can navigate into. Purely cosmetic here — it
  /// only decides whether the "open" chevron is drawn; [onOpen] is the gate.
  static IconData _iconFor(String? type) => switch (type) {
        'like' => Icons.favorite_rounded,
        'remix' => Icons.auto_awesome_rounded,
        _ => Icons.notifications_rounded,
      };

  /// Drops a notification tile in from the top.
  ///
  /// [onOpen] being non-null is what makes the tile tappable — pass null for
  /// informational pushes that have nowhere to go.
  static void show(
    OverlayState overlay, {
    String? title,
    String? body,
    String? type,
    VoidCallback? onOpen,
    Duration duration = const Duration(seconds: 5),
  }) {
    // Nothing to render — don't flash an empty card.
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    dismiss();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _PushTile(
        title: title,
        body: body,
        icon: _iconFor(type),
        duration: duration,
        onOpen: onOpen,
        onGone: () {
          // Guard against removing an entry a newer banner already replaced.
          if (_current == entry) {
            entry.remove();
            _current = null;
          }
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  /// Removes the visible tile immediately, if any.
  static void dismiss() {
    _current?.remove();
    _current = null;
  }
}

class _PushTile extends StatefulWidget {
  final String? title;
  final String? body;
  final IconData icon;
  final Duration duration;
  final VoidCallback? onOpen;
  final VoidCallback onGone;

  const _PushTile({
    required this.title,
    required this.body,
    required this.icon,
    required this.duration,
    required this.onOpen,
    required this.onGone,
  });

  @override
  State<_PushTile> createState() => _PushTileState();
}

class _PushTileState extends State<_PushTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 220),
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -1.3),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  ));

  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);

  Timer? _autoClose;

  /// Stops the auto-close timer from racing a dismissal already in flight.
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _autoClose = Timer(widget.duration, _close);
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _autoClose?.cancel();
    if (!mounted) {
      widget.onGone();
      return;
    }
    await _c.reverse();
    widget.onGone();
  }

  void _handleTap() {
    final open = widget.onOpen;
    if (open == null) return;
    // Navigate first so the destination is already building while the tile
    // animates away.
    open();
    _close();
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final tappable = widget.onOpen != null;

    return Positioned(
      top: topInset + 10.h,
      left: 12.w,
      right: 12.w,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleTap,
              // Flick up to dismiss, the way a real heads-up notification
              // behaves. Downward drags are ignored so this can't fight a
              // pull-to-refresh underneath.
              onVerticalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0) < 0) _close();
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 14.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.border, width: 1.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 24.r,
                      offset: Offset(0, 8.h),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _iconBadge(),
                    SizedBox(width: 12.w),
                    Expanded(child: _text()),
                    if (tappable) ...[
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                        size: 22.w,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBadge() {
    return Container(
      width: 42.w,
      height: 42.w,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.accentGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.32),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Icon(widget.icon, color: Colors.white, size: 22.w),
    );
  }

  Widget _text() {
    final title = widget.title;
    final body = widget.body;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title.isNotEmpty)
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5.sp,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        if (title != null &&
            title.isNotEmpty &&
            body != null &&
            body.isNotEmpty)
          SizedBox(height: 3.h),
        if (body != null && body.isNotEmpty)
          Text(
            body,
            // Two lines is what a system heads-up shows before truncating.
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
      ],
    );
  }
}
