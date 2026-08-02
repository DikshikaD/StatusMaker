import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/utils/responsive.dart';

/// Shows the language-selection popup. The chosen language is applied and
/// persisted immediately (via [S.set]) so the whole app — including any
/// onboarding shown next — rebuilds in that language. [onContinue] runs after
/// the dialog closes.
///
/// Uses the shared fade + slide animation (matching the app's page transitions)
/// for both opening and closing.
Future<void> showLanguagePicker(
  BuildContext context, {
  required VoidCallback onContinue,
}) {
  String selected = S.lang.value;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'language',
    barrierColor: AppColors.accent.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (dialogContext, _, __) {
      return StatefulBuilder(
        builder: (dialogContext, setLocal) {
          Widget option(String code, String native, String english) {
            final isSel = selected == code;
            return GestureDetector(
              onTap: () => setLocal(() => selected = code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: isSel
                      ? AppColors.accent.withValues(alpha: 0.06)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isSel ? AppColors.accentLight : AppColors.border,
                    width: isSel ? 2.r : 1.r,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        gradient: isSel
                            ? const LinearGradient(
                                colors: AppColors.accentGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSel ? null : AppColors.cardLight,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        code.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: isSel ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            native,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            english,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: isSel ? 1 : 0,
                      child: Icon(Icons.check_circle,
                          color: AppColors.accentLight, size: 22.w),
                    ),
                  ],
                ),
              ),
            );
          }

          // The picker is a mandatory first-run step: the caller only advances
          // from [onContinue]. Block the Android back button too, otherwise the
          // route pops without ever running it and the splash — which has
          // already latched `_navigated` — is left with nothing to advance it.
          return PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: AppColors.surface,
              insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(24.w),
                // Scrollable so the Continue button stays reachable in
                // landscape and at large system text scales.
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56.w,
                        height: 56.w,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppColors.accentGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.translate,
                            color: Colors.white, size: 28.w),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        S.t('choose_language'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        S.t('choose_language_desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      option('en', 'English', 'English'),
                      option('hi', 'हिंदी', 'Hindi'),
                      SizedBox(height: 8.h),
                      GestureDetector(
                        onTap: () {
                          S.set(selected);
                          Navigator.of(dialogContext).pop();
                          onContinue();
                        },
                        child: Container(
                          width: double.infinity,
                          height: 52.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppColors.accentGradient,
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(28.r),
                          ),
                          child: Text(
                            S.t('continue_btn'),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
        },
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
