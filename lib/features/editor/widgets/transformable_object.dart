import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';

/// Wraps any canvas object (text or image) and gives it the full set of
/// direct-manipulation interactions in ONE place:
///
///  • one-finger drag to move, anywhere on the canvas
///  • two-finger pinch to resize, with simultaneous twist-to-rotate
///    (if [enableRotation] is true)
///  • a delete handle (tap)
///
/// All of drag/resize/rotate are driven by a SINGLE `GestureDetector`'s
/// `onScaleStart/Update/End` triad. Flutter's scale recognizer natively
/// reports pan (`focalPointDelta`), zoom (`scale`) and twist (`rotation`)
/// together for the same pointer set — there is no separate recognizer per
/// gesture, so there is nothing for them to conflict over. Do not add a
/// second `GestureDetector`/`Listener` for move/resize/rotate; route any new
/// transform behavior through this same callback triad.
///
/// While a gesture is in flight only local state changes (one cheap repaint);
/// the controller is written exactly once, on gesture end.
///
/// DELETE HANDLE IS A SCREEN-SPACE "BILLBOARD", NOT PART OF THE OBJECT'S OWN
/// `Transform.rotate`/`Transform.scale` SUBTREE:
///
/// The content and its selection border deliberately DO rotate/scale with the
/// object — that's correct, expected behavior (the border traces the actual
/// rotated/scaled bounds). The delete handle must NOT, and earlier versions
/// that nested it inside the same transform chain had a real, reproduced bug:
/// once an object was rotated (via two-finger twist), the handle's hit-test
/// region became a rotated, non-axis-aligned quadrilateral in screen space.
/// Hit-testing was still mathematically exact, but that's exactly the
/// problem — a user aiming at "the visual corner" of a rotated object no
/// longer has a forgiving, axis-aligned target, so taps that look correct to
/// the eye land just outside the true (rotated) hit box and are silently
/// dropped. Device logs confirmed this: pinch+rotate (scale 2.25x,
/// rotation ≈ -6°) followed immediately by a delete attempt produced no
/// gesture callback at all — the tap hit neither the content nor the handle.
///
/// The fix used by every production design tool (Figma, Canva, PowerPoint):
/// render selection handles as a screen-space overlay, computed from the
/// object's transformed corner position, but never itself rotated or scaled.
/// `_deleteHandleOffset()` below does that math directly (rotate-then-scale
/// around the object's own center, matching the paint transform order), so
/// the delete target is always upright, always the same tappable size, and
/// always exactly where the eye expects it — independent of how the object
/// underneath has been transformed.
class TransformableObject extends StatefulWidget {
  final Offset position;
  final double scale;
  final double rotation;
  final bool isSelected;
  final Widget child;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback? onDoubleTap;
  final void Function(Offset position, double scale, double rotation) onTransformEnd;

  /// Whether two-finger twist rotates the object. Defaults to true; set to
  /// false for element types that should stay axis-aligned.
  final bool enableRotation;

  const TransformableObject({
    super.key,
    required this.position,
    required this.scale,
    required this.rotation,
    required this.isSelected,
    required this.child,
    required this.onSelect,
    required this.onDelete,
    required this.onTransformEnd,
    this.onDoubleTap,
    this.enableRotation = true,
  });

  @override
  State<TransformableObject> createState() => _TransformableObjectState();
}

class _TransformableObjectState extends State<TransformableObject> {
  // Gap between the content and the selection border — kept small so the
  // border hugs the content closely. The delete handle no longer needs this
  // gap to avoid overlapping the content's hit box (it's a screen-space
  // billboard, see class doc comment), so this is purely a visual choice now.
  static const double _pad = 6;
  static const double _handleSize = 36;

  // Measured once layout completes; used only to place the billboard delete
  // handle at the object's actual top-left corner. A reasonable default
  // covers the very first frame before the real measurement lands.
  final GlobalKey _boxKey = GlobalKey();
  Size _measuredSize = const Size(160, 160);

  late Offset _position;
  late double _scale;
  late double _rotation;
  bool _interacting = false;

  // gesture bases
  double _baseScale = 1.0;
  double _baseRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant TransformableObject oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interacting) _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
  }

  void _sync() {
    _position = widget.position;
    _scale = widget.scale;
    _rotation = widget.rotation;
  }

  void _commit() => widget.onTransformEnd(_position, _scale, _rotation);

  // Reads the content box's actual (unscaled) layout size once it's
  // available, and schedules one more frame to pick up the corrected delete
  // handle position. Content size only changes when the underlying element
  // changes (e.g. text edited), so this is cheap and rare, not per-gesture.
  void _remeasure() {
    if (!mounted) return;
    final box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size != _measuredSize) {
      setState(() => _measuredSize = box.size);
    }
  }

  // ---- move + pinch to resize + twist to rotate --------------------------
  // One recognizer, one set of callbacks, all three transforms — see the
  // class doc comment for why this must stay a single GestureDetector.
  // No handle-related guards needed here: the delete handle occupies screen
  // space this GestureDetector's content box doesn't cover (see build()), so
  // a pointer that lands on it is never also delivered to this recognizer.
  void _onScaleStart(ScaleStartDetails d) {
    widget.onSelect();
    _baseScale = _scale;
    _baseRotation = _rotation;
    _interacting = true;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      _position += d.focalPointDelta;
      _scale = (_baseScale * d.scale).clamp(0.3, 6.0);
      if (widget.enableRotation) {
        _rotation = _baseRotation + d.rotation;
      }
    });
  }

  void _onScaleEnd(ScaleEndDetails d) {
    _interacting = false;
    _commit();
    // The gesture may have changed the content's footprint indirectly (e.g.
    // triggered a rebuild upstream); pick up any resulting size change.
    WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
  }

  /// Screen-space offset (relative to this object's canvas origin, i.e. the
  /// same coordinate space `_position` lives in) of the delete handle's
  /// center, given the object's current rotation/scale. Mirrors the paint
  /// transform order used in build(): scale first, then rotate, both
  /// pivoting on the nominal (unscaled) box's own center — exactly what
  /// `Transform.scale` + `Transform.rotate` do to the content itself.
  Offset _deleteHandleOffset() {
    final center = Offset(_measuredSize.width / 2, _measuredSize.height / 2);
    // Anchor at the selection border's own corner (inset by `_pad` from the
    // box edge — the same inset the border Positioned uses below), so the
    // handle sits right on top of the stroke corner instead of floating
    // further out past it.
    const corner = Offset(_pad, _pad);
    final scaled = (corner - center) * _scale;
    final cosA = math.cos(_rotation);
    final sinA = math.sin(_rotation);
    final rotated = Offset(
      scaled.dx * cosA - scaled.dy * sinA,
      scaled.dx * sinA + scaled.dy * cosA,
    );
    return _position + center + rotated;
  }

  @override
  Widget build(BuildContext context) {
    final handleCenter = _deleteHandleOffset();

    return Positioned.fill(
      // This RepaintBoundary is what makes dragging/pinching/rotating cheap:
      // it isolates EVERYTHING this widget paints (content + border + the
      // billboard handle below) into its own compositing layer, so a
      // per-frame setState here repaints only this one element — never the
      // rest of the canvas. Previously the billboard handle sat outside any
      // boundary at this level, so every drag/resize frame had to repaint
      // starting from the canvas's own top-level RepaintBoundary (in
      // status_canvas.dart) instead of this element's — i.e. the WHOLE
      // canvas repainted on every gesture frame. That cost scales with the
      // canvas's total content, which is exactly why it got worse at high
      // zoom (more/larger pixels to redraw each frame). Keep this boundary
      // wrapping the full per-object Stack, not just the content subtree.
      child: RepaintBoundary(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: _position.dx,
              top: _position.dy,
              child: Transform.rotate(
                angle: _rotation,
                child: Transform.scale(
                  scale: _scale,
                  // clipBehavior: Clip.none so the selection border (inset
                  // by _pad, i.e. outside the content itself) isn't clipped —
                  // this Stack's own size is fixed by the Padding below, so
                  // it never affects the content's actual size/hit box.
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        key: _boxKey,
                        padding: const EdgeInsets.all(_pad),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onSelect,
                          onDoubleTap: widget.onDoubleTap,
                          onScaleStart: _onScaleStart,
                          onScaleUpdate: _onScaleUpdate,
                          onScaleEnd: _onScaleEnd,
                          child: widget.child,
                        ),
                      ),
                      if (widget.isSelected)
                        Positioned(
                          left: _pad,
                          top: _pad,
                          right: _pad,
                          bottom: _pad,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.accent, width: 1.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Delete handle — a screen-space billboard: always upright,
            // always the same tappable size, positioned at the object's
            // actual (rotated/scaled) corner. See the class doc comment for
            // why this must NOT live inside the Transform.rotate/scale
            // subtree above. It's still inside the RepaintBoundary above, so
            // it repainting each gesture frame stays isolated to this object.
            if (widget.isSelected)
              Positioned(
                left: handleCenter.dx - _handleSize / 2,
                top: handleCenter.dy - _handleSize / 2,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onDelete,
                  child: _handle(Icons.close, Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _handle(IconData icon, Color color) {
    return Container(
      width: _handleSize,
      height: _handleSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 4),
        ],
      ),
      child: Icon(icon, size: 15, color: color == Colors.white ? AppColors.primary : Colors.white),
    );
  }
}
