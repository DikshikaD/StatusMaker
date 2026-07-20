import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/utils/responsive.dart';

/// The default bottom bar: the only things you can add. Big targets, evenly
/// spaced, thumb-reachable. Light theme to match the app.
class AddBar extends StatelessWidget {
  final VoidCallback onBackground;
  final VoidCallback onPhoto;
  final VoidCallback onText;
  final VoidCallback onQuotes;
  final VoidCallback onElements;

  const AddBar({
    super.key,
    required this.onBackground,
    required this.onPhoto,
    required this.onText,
    required this.onQuotes,
    required this.onElements,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _item(Icons.wallpaper_rounded, S.t('background'), onBackground),
            _item(Icons.add_photo_alternate_rounded, S.t('photo'), onPhoto),
            _item(Icons.text_fields_rounded, S.t('text'), onText),
            _item(Icons.auto_awesome_rounded, S.t('elements'), onElements),
            _item(Icons.format_quote_rounded, S.t('quotes'), onQuotes),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52.w,
                height: 52.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(icon, color: AppColors.accent, size: 26.w),
              ),
              SizedBox(height: 6.h),
              Text(
                label,
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
        ),
      ),
    );
  }
}
