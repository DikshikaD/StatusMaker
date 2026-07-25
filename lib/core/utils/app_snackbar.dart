import 'dart:async';
import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/utils/responsive.dart';

enum AppSnackType { success, error, info }

/// A theme-matched toast that slides in from the TOP with an accent gradient
/// background. Built on the [Overlay] (not ScaffoldMessenger) so it can sit at
/// the top of the screen and float above everything. Used everywhere so
/// messages look consistent — never show raw exception text.
class AppSnackBar {
  static OverlayEntry? _current;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    AppSnackType type = AppSnackType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _dismiss();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopToast(
        message: message,
        type: type,
        duration: duration,
        onGone: () {
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

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _current?.remove();
    _current = null;
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: AppSnackType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: AppSnackType.error);

  static void info(BuildContext context, String message) =>
      show(context, message, type: AppSnackType.info);
}

class _TopToast extends StatefulWidget {
  final String message;
  final AppSnackType type;
  final Duration duration;
  final VoidCallback onGone;

  const _TopToast({
    required this.message,
    required this.type,
    required this.duration,
    required this.onGone,
  });

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -1.4),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);

  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _autoClose = Timer(widget.duration, _close);
  }

  Future<void> _close() async {
    _autoClose?.cancel();
    if (!mounted) {
      widget.onGone();
      return;
    }
    await _c.reverse();
    widget.onGone();
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

    final icon = switch (widget.type) {
      AppSnackType.success => Icons.check_circle_rounded,
      AppSnackType.error => Icons.error_rounded,
      AppSnackType.info => Icons.info_rounded,
    };

    return Positioned(
      top: topInset + 10.h,
      left: 16.w,
      right: 16.w,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _close,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.accentGradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.40),
                      blurRadius: 18.r,
                      offset: Offset(0, 6.h),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 22.w),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
