import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/utils/responsive.dart';

/// A reusable "are you sure?" confirmation popup, styled to match the app's
/// other dialogs (see `language_dialog.dart`): [AppColors.surface] card,
/// rounded corners, a circular icon badge, and the same fade + slide + scale
/// entrance/exit transition.
///
/// Returns `true` if the destructive action was confirmed, `false`/`null`
/// otherwise (dismissed or Cancel tapped).
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  IconData icon = Icons.delete_outline_rounded,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'confirm',
    barrierColor: AppColors.primary.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (dialogContext, _, __) {
      return Dialog(
        backgroundColor: AppColors.surface,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.redAccent, size: 28.w),
              ),
              SizedBox(height: 16.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(false),
                      child: Container(
                        height: 52.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.cardLight,
                          borderRadius: BorderRadius.circular(28.r),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          S.t('cancel'),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(true),
                      child: Container(
                        height: 52.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                        child: Text(
                          confirmLabel ?? S.t('delete'),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}
