import 'package:flutter/material.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/utils/responsive.dart';

/// What the user chose when backing out of an editor with unsaved work.
enum DiscardChoice {
  /// Save the design, then leave — but only if the save actually succeeds.
  save,

  /// Leave immediately, throwing the edits away.
  discard,

  /// Stay in the editor. Also what a dismissed (tapped-outside / back) dialog
  /// resolves to, since neither of the destructive options should ever be the
  /// result of *not* answering.
  cancel,
}

/// Asks whether to save, discard, or stay — the guard both editors put in front
/// of back navigation when there are unsaved changes.
///
/// `barrierDismissible: false` because Save and Discard are not symmetric: an
/// accidental barrier tap resolving to anything other than "stay here" would
/// risk silently binning the user's work. The explicit Cancel button is the
/// only way out that isn't a decision.
Future<DiscardChoice> showDiscardChangesDialog(BuildContext context) async {
  final choice = await showDialog<DiscardChoice>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.r),
      ),
      title: Text(
        S.t('discard_changes_title'),
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18.sp,
        ),
      ),
      content: Text(
        S.t('discard_changes_msg'),
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
      ),
      // ONE action holding a Column, rather than three actions. Three actions —
      // two with translated labels that can run long ("रद्द करें", "छोड़ दें") —
      // crowd a phone-width dialog row, and stacking also puts real distance
      // between "Discard" and its neighbours so the destructive option isn't a
      // near-miss away from the safe one.
      //
      // AlertDialog has no switch that forces this: actionsOverflowDirection
      // only picks which way an OverflowBar stacks *if* it independently
      // decides the row doesn't fit, so on a wide screen the buttons would
      // still lay out in a row. A single Column child sidesteps the
      // fits-or-not decision entirely.
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          // Full-width rows: the whole strip is the tap target, which is much
          // easier to hit than a shrink-wrapped label on a small phone.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(DiscardChoice.save),
              child: Text(
                S.t('save'),
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(DiscardChoice.discard),
              child: Text(
                S.t('discard'),
                style: TextStyle(color: Colors.redAccent, fontSize: 15.sp),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(DiscardChoice.cancel),
              child: Text(
                S.t('cancel'),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15.sp),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  // A null result means the route was popped without a button (e.g. the system
  // back button inside the dialog) — treat that as "stay", never as discard.
  return choice ?? DiscardChoice.cancel;
}
