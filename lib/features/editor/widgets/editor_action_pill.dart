import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/utils/responsive.dart';

/// A top-bar action (Save / Post / Share) in both editors: icon with a short
/// label underneath. Stacking the label keeps each pill narrow enough for a
/// phone-width row, and the label scales down (rather than overflowing) at
/// large accessibility font sizes.
class EditorActionPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  /// Dims the pill *without* swallowing the tap, so an unavailable action can
  /// still explain itself.
  final bool disabled;

  /// Shows a spinner in place of the icon (and doesn't dim).
  final bool busy;

  const EditorActionPill({
    super.key,
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
    this.disabled = false,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final dim = !busy && (disabled || onTap == null);
    final fg = filled ? Colors.white : AppColors.textPrimary;
    // The label shrinks via FittedBox anyway; capping the scaler too keeps the
    // pill's height sane at the largest system font sizes.
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);

    return Opacity(
      opacity: dim ? 0.5 : 1.0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Semantics(
          button: true,
          child: Container(
            constraints: BoxConstraints(minWidth: 46.w, minHeight: 40.w),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: filled ? AppColors.accent : AppColors.cardLight,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                busy
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: fg,
                        ),
                      )
                    : Icon(icon, size: 18.w, color: fg),
                SizedBox(height: 2.h),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 64.w),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      textScaler: scaler,
                      style: TextStyle(
                        color: fg,
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
