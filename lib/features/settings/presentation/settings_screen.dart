import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/theme/theme_controller.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/utils/app_snackbar.dart';
import 'package:status_maker/core/utils/page_transitions.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/features/notifications/data/app_notification.dart';
import 'package:status_maker/features/notifications/presentation/notifications_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Must match `applicationId` in android/app/build.gradle.kts.
  static const _packageId = 'com.appbedev.statusmaker';
  static const _storeUrl =
      'https://play.google.com/store/apps/details?id=$_packageId';

  /// Opens the Play Store listing — in the store app when it's installed
  /// (market://), otherwise the web listing.
  Future<void> _rateUs() async {
    for (final uri in [
      Uri.parse('market://details?id=$_packageId'),
      Uri.parse(_storeUrl),
    ]) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {
        // market:// has no handler on this device/platform — try the web URL.
      }
    }
    if (mounted) AppSnackBar.error(context, S.t('something_wrong'));
  }

  /// Opens the system share sheet with an invite message + store link.
  void _shareApp() => Share.share('${S.t('share_app_msg')}\n$_storeUrl');

  final NotificationRepository _notifications = NotificationRepository();

  /// Unread notifications, for the badge on the Notifications row. Zero until
  /// loaded (and on any failure) so the row never waits on the network.
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    final n = await _notifications.unreadCount();
    if (mounted && n != _unread) setState(() => _unread = n);
  }

  /// Opening the list marks everything read, so the badge is refreshed on
  /// return rather than cleared optimistically.
  void _openNotifications() {
    Navigator.push(
      context,
      FadeSlidePageRoute(page: const NotificationsScreen()),
    ).then((_) => _loadUnread());
  }

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
          _sectionTitle(S.t('appearance')),
          SizedBox(height: 4.h),
          Text(
            S.t('appearance_desc'),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
          ),
          SizedBox(height: 14.h),
          _themeToggle(),

          SizedBox(height: 32.h),
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
          _sectionTitle(S.t('notifications')),
          SizedBox(height: 4.h),
          SizedBox(height: 14.h),
          _notificationsTile(),

          SizedBox(height: 32.h),
          _sectionTitle(S.t('about')),
          SizedBox(height: 12.h),
          _row(Icons.star_outline, S.t('rate_us'), onTap: _rateUs),
          _row(Icons.ios_share, S.t('share_app'), onTap: _shareApp),
          _row(Icons.info_outline, '${S.t('version')}  1.0.0'),
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

  /// Primary control: a single row with a switch to flip dark mode on/off.
  Widget _themeToggle() {
    final isDark = ThemeController.isDark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: AppColors.accent,
            size: 22.w,
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              S.t('dark_mode'),
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: isDark,
            activeColor: AppColors.accent,
            onChanged: (_) => setState(ThemeController.toggle),
          ),
        ],
      ),
    );
  }

  /// Same card styling as the language tiles, with an unread-count badge.
  Widget _notificationsTile() {
    return GestureDetector(
      onTap: _openNotifications,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_outlined,
                color: AppColors.accent, size: 22.w),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                S.t('notifications'),
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (_unread > 0) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  _unread > 99 ? '99+' : '$_unread',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
            ],
            Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 22.w),
          ],
        ),
      ),
    );
  }

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

  Widget _row(IconData icon, String label, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label,
          style: TextStyle(fontSize: 15.sp, color: AppColors.textPrimary)),
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: AppColors.textSecondary)
          : null,
      onTap: onTap,
    );
  }
}
