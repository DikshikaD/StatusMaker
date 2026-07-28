import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/utils/responsive.dart';

/// A plain loader in the middle of the screen, shown while a status is being
/// exported and uploaded.
///
/// Deliberately just the spinner: no scrim over the screen, and nothing drawn
/// on the button that started the action. The buttons disable themselves while
/// [busy], which is what actually prevents a double-save — the scrim wasn't
/// carrying its weight and dimming the whole screen read as a glitch.
class BusyOverlay extends StatelessWidget {
  final bool busy;

  const BusyOverlay({super.key, required this.busy});

  @override
  Widget build(BuildContext context) {
    // AnimatedSwitcher (rather than a permanently mounted, faded-out spinner)
    // so the CircularProgressIndicator only exists while it's needed. A spinner
    // left in the tree keeps its repeating animation running, which schedules a
    // frame forever and drags the whole app down for something invisible.
    return IgnorePointer(
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: busy
              ? SizedBox(
                  width: 34.w,
                  height: 34.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.accent,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
