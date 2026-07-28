import 'package:flutter/material.dart';

/// Routes every editor bottom sheet (background/elements/quotes/font, ...)
/// through one place, so switching between them is always a clean
/// close-then-open — never two sheets glitching on top of each other.
///
/// `showModalBottomSheet` on its own gives each individual sheet a nice
/// slide-up/slide-down animation, but nothing stops a second call from
/// stacking a new sheet on top of one that's still open (e.g. one toolbar
/// button tapped right after another). [show] fixes that: if a sheet opened
/// through this coordinator is still open when a new one is requested, it
/// closes the current one first and waits for its exit animation to finish
/// before the next sheet starts its own entrance animation.
class SheetCoordinator {
  SheetCoordinator._();

  static bool _open = false;

  /// Matches the stock modal-bottom-sheet exit transition duration, so the
  /// next sheet only appears once the current one has visibly finished
  /// closing.
  static const _closeTransition = Duration(milliseconds: 300);

  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    Color backgroundColor = Colors.transparent,
    bool isScrollControlled = true,
  }) async {
    if (_open) {
      Navigator.of(context).maybePop();
      await Future.delayed(_closeTransition);
    }
    _open = true;
    try {
      return await showModalBottomSheet<T>(
        context: context,
        isScrollControlled: isScrollControlled,
        backgroundColor: backgroundColor,
        builder: builder,
      );
    } finally {
      _open = false;
    }
  }
}
