import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/utils/responsive.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(S.t('settings_title')),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          _sectionTitle(S.t('language')),
          SizedBox(height: 4.h),
          Text(
            S.t('language_desc'),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
          ),
          SizedBox(height: 14.h),
          _languageTile('English', 'en'),
          SizedBox(height: 12.h),
          _languageTile('हिंदी', 'hi'),

          SizedBox(height: 32.h),
          _sectionTitle(S.t('about')),
          SizedBox(height: 12.h),
          _row(Icons.star_outline, S.t('rate_us')),
          _row(Icons.ios_share, S.t('share_app')),
          _row(Icons.info_outline, '${S.t('version')}  1.0.0', tappable: false),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );

  Widget _languageTile(String label, String code) {
    final selected = S.lang.value == code;
    return GestureDetector(
      onTap: () => setState(() => S.set(code)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.translate,
                color: selected ? AppColors.accent : AppColors.textSecondary,
                size: 22.w),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: AppColors.accent, size: 22.w)
            else
              Icon(Icons.radio_button_unchecked,
                  color: AppColors.border, size: 22.w),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, {bool tappable = true}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(label,
            style: TextStyle(fontSize: 15.sp, color: AppColors.textPrimary)),
        trailing: tappable
            ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
            : null,
        onTap: tappable
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(label),
                      duration: const Duration(seconds: 2)),
                );
              }
            : null,
      ),
    );
  }
}
