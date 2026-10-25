import 'package:flutter/material.dart';

import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/utils/app_snackbar.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/features/moderation/moderation_store.dart';
import 'package:status_maker/features/statuses/data/saved_status.dart';

/// What the user did in [showPostActionsSheet]; screens that show a single post
/// use it to close themselves once the post is gone.
enum PostAction { none, reported, hidden, blocked }

/// The "..." menu on someone else's post: report it, hide it, or block its
/// creator. Never offered on the user's own posts.
Future<PostAction> showPostActionsSheet(
    BuildContext context, SavedStatus status) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _tile(sheetContext, Icons.flag_outlined, S.t('report_post'),
                'report'),
            _tile(sheetContext, Icons.visibility_off_outlined,
                S.t('hide_post'), 'hide'),
            if (status.userId != null)
              _tile(sheetContext, Icons.block, S.t('block_creator'), 'block'),
          ],
        ),
      ),
    ),
  );
  if (choice == null || !context.mounted) return PostAction.none;

  switch (choice) {
    case 'hide':
      await ModerationStore.instance.hidePost(status.id);
      if (context.mounted) AppSnackBar.success(context, S.t('post_hidden'));
      return PostAction.hidden;
    case 'block':
      await ModerationStore.instance.blockUser(status.userId!);
      if (context.mounted) AppSnackBar.success(context, S.t('creator_blocked'));
      return PostAction.blocked;
    default:
      return _report(context, status);
  }
}

Future<PostAction> _report(BuildContext context, SavedStatus status) async {
  final reason = await showModalBottomSheet<ReportReason>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 8.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  S.t('report_why'),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            for (final r in ReportReason.values)
              ListTile(
                title: Text(S.t('report_${r.name}'),
                    style: TextStyle(
                        fontSize: 15.sp, color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(sheetContext, r),
              ),
          ],
        ),
      ),
    ),
  );
  if (reason == null || !context.mounted) return PostAction.none;

  try {
    await ModerationStore.instance.report(status.id, reason);
    if (context.mounted) AppSnackBar.success(context, S.t('report_thanks'));
    return PostAction.reported;
  } catch (_) {
    if (context.mounted) AppSnackBar.error(context, S.t('report_failed'));
    return PostAction.none;
  }
}

Widget _tile(BuildContext context, IconData icon, String label, String value) {
  return ListTile(
    leading: Icon(icon, color: AppColors.textSecondary),
    title: Text(label,
        style: TextStyle(fontSize: 15.sp, color: AppColors.textPrimary)),
    onTap: () => Navigator.pop(context, value),
  );
}
