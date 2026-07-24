import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/utils/responsive.dart';

/// A single selectable category in the picker.
class _Cat {
  final IconData icon;
  final String name; // '' means General / no specific category
  final Color color;
  const _Cat(this.icon, this.name, this.color);
}

/// Shown when the user taps the floating Create button. Lets them pick a
/// category first; the choice is returned via [Navigator.pop] so the editor
/// can be opened with matching quote suggestions.
///
/// Pops with the chosen category name, an empty string for "General", or
/// `null` if dismissed.
class CategoryPickerSheet extends StatelessWidget {
  const CategoryPickerSheet({super.key});

  static final List<_Cat> _cats = [
    _Cat(Icons.auto_awesome, '', const Color(0xFFFDECE7)), // General
    _Cat(Icons.wb_sunny_outlined, 'Morning', const Color(0xFFE3F0FF)),
    _Cat(Icons.cake_outlined, 'Birthday', const Color(0xFFFCE4EC)),
    _Cat(Icons.celebration_outlined, 'Festival', const Color(0xFFFFF0E0)),
    _Cat(Icons.favorite_outline, 'Love', const Color(0xFFFFE5E5)),
    _Cat(Icons.bolt_outlined, 'Motivation', const Color(0xFFFFF8E1)),
    _Cat(Icons.business_center_outlined, 'Business', const Color(0xFFEFEFEF)),
    _Cat(Icons.self_improvement, 'Devotional', const Color(0xFFFFF0E0)),
    _Cat(Icons.wb_twilight, 'Suprabhat', const Color(0xFFFFF6E0)),
    _Cat(Icons.nightlight_round, 'Good Night', const Color(0xFFE8EAFF)),
    _Cat(Icons.format_quote, 'Suvichar', const Color(0xFFE0F2F1)),
  ];

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.78;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              S.t('choose_category'),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              S.t('choose_category_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 16.h),
            Flexible(
              child: SingleChildScrollView(
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 14.h,
                  crossAxisSpacing: 12.w,
                  childAspectRatio: 0.9,
                  children: [for (final c in _cats) _tile(context, c)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, _Cat c) {
    // General uses the special 'cat_General' label; others use their own key.
    final label = c.name.isEmpty ? S.cat('General') : S.cat(c.name);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(c.name),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 64.h,
            width: 64.w,
            decoration: BoxDecoration(
              color: c.color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(c.icon, color: AppColors.accent, size: 28.w),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
