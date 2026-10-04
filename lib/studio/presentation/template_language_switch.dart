import 'package:flutter/material.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/studio/models/language_model.dart';

/// EN | हिं pill that picks the language the *generated designs* carry,
/// independent of the app language — a Hindi-UI user can still make an
/// English status for a friend. Labels are each language's own short form so
/// the control reads correctly whichever UI language is active.
class TemplateLanguageSwitch extends StatelessWidget {
  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;

  const TemplateLanguageSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget seg(AppLanguage l, String label) {
      final on = l == value;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(l),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: on ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: on ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: S.t('templates_in'),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            seg(AppLanguage.en, 'EN'),
            seg(AppLanguage.hi, 'हिं'),
          ],
        ),
      ),
    );
  }
}
