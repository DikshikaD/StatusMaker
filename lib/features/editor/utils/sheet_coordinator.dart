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

  /// Identifies which [show] call currently owns [_open]. A plain bool is not
  /// enough: the outgoing sheet's `finally` and the incoming call's `_open =
  /// true` are both ~[_closeTransition] away and unordered, so the outgoing
  /// one could clear the flag while the incoming sheet is open. The next call
  /// would then skip the close-first step and stack a second sheet. Only the
  /// call that still owns the current generation may clear the flag.
  static int _generation = 0;

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
    final generation = ++_generation;
    if (_open) {
      Navigator.of(context).maybePop();
      await Future.delayed(_closeTransition);
      // The editor can be popped while we wait out the close animation;
      // showing from a deactivated context throws.
      if (!context.mounted) return null;
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
      // Only clear if a newer sheet hasn't taken ownership in the meantime.
      if (_generation == generation) _open = false;
    }
  }
}
