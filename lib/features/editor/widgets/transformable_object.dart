import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';

/// Wraps any canvas object (text or image) and gives it the full set of
/// direct-manipulation interactions in ONE place:
///
///  • one-finger drag to move
///  • two-finger pinch to resize + twist to rotate (single gesture)
///  • a delete handle (tap)
///  • a rotate handle (drag) and a resize handle (drag) for discoverability
///
/// While a gesture is in flight only local state changes (one cheap repaint);
/// the controller is written exactly once, on gesture end. Handles are
/// inverse-scaled so they stay the same visual size no matter how big the
/// object gets.
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
  });

  @override
  State<TransformableObject> createState() => _TransformableObjectState();
}

class _TransformableObjectState extends State<TransformableObject> {
  // Transparent inset around the content. Handles live inside this inset so
  // they stay within the object's hit-test bounds (overflowing children can't
  // receive taps in Flutter).
  static const double _pad = 16;

  final GlobalKey _contentKey = GlobalKey();

  late Offset _position;
  late double _scale;
  late double _rotation;
  bool _interacting = false;

  // gesture bases
  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  double _startDist = 0.0;
  double _startAngle = 0.0;

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

  void _sync() {
    _position = widget.position;
    _scale = widget.scale;
    _rotation = widget.rotation;
  }

  void _commit() => widget.onTransformEnd(_position, _scale, _rotation);

  Offset? _center() {
    final ctx = _contentKey.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  // ---- move + pinch + twist -------------------------------------------------
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
      _rotation = _baseRotation + d.rotation;
    });
  }

  void _onScaleEnd(ScaleEndDetails d) {
    _interacting = false;
    _commit();
  }

  // ---- rotate handle --------------------------------------------------------
  void _onRotateStart(DragStartDetails d) {
    final c = _center();
    if (c == null) return;
    _startAngle = (d.globalPosition - c).direction;
    _baseRotation = _rotation;
    _interacting = true;
  }

  void _onRotateUpdate(DragUpdateDetails d) {
    final c = _center();
    if (c == null) return;
    final angle = (d.globalPosition - c).direction;
    setState(() => _rotation = _baseRotation + (angle - _startAngle));
  }

  // ---- resize handle --------------------------------------------------------
  void _onResizeStart(DragStartDetails d) {
    final c = _center();
    if (c == null) return;
    _startDist = (d.globalPosition - c).distance;
    _baseScale = _scale;
    _interacting = true;
  }

  void _onResizeUpdate(DragUpdateDetails d) {
    final c = _center();
    if (c == null || _startDist <= 0) return;
    final dist = (d.globalPosition - c).distance;
    setState(() => _scale = (_baseScale * dist / _startDist).clamp(0.3, 6.0));
  }

  void _onHandleEnd(DragEndDetails d) {
    _interacting = false;
    _commit();
  }

  @override
  Widget build(BuildContext context) {
    final inv = _scale == 0 ? 1.0 : 1 / _scale;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      // Gives this object its own compositing layer, so dragging/pinching it
      // repaints only itself — not every other image/text/element sharing the
      // canvas's outer RepaintBoundary. This is what makes moving one object
      // smooth regardless of how many other objects are on the canvas.
      child: RepaintBoundary(
        child: Transform.rotate(
          angle: _rotation,
          child: Transform.scale(
            scale: _scale,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onSelect,
              onDoubleTap: widget.onDoubleTap,
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Content, inset by _pad so the corner handles land inside
                  // the Stack's bounds (and therefore stay tappable).
                  Padding(
                    padding: const EdgeInsets.all(_pad),
                    child: Container(key: _contentKey, child: widget.child),
                  ),
                  if (widget.isSelected) ...[
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
                    // delete — top-left. Uses a raw pointer-down instead of
                    // onTap: this handle sits inside the same GestureDetector
                    // subtree as the parent's onScaleStart/Update/End (used to
                    // move/pinch the whole object), so a tap here also enters
                    // the same gesture arena as that pan/scale recognizer. On
                    // a small 28x28 target, even a pixel of finger jitter
                    // during the tap can cross the touch-slop threshold and
                    // let the parent's scale recognizer win instead — the
                    // "delete" silently turns into a tiny nudge. A Listener
                    // fires unconditionally on the raw pointer event, so it
                    // can't lose that race.
                    _corner(
                      left: 2,
                      top: 2,
                      inv: inv,
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (_) => widget.onDelete(),
                        child: _handle(Icons.close, Colors.redAccent),
                      ),
                    ),
                    // rotate — top-right
                    _corner(
                      right: 2,
                      top: 2,
                      inv: inv,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: _onRotateStart,
                        onPanUpdate: _onRotateUpdate,
                        onPanEnd: _onHandleEnd,
                        child: _handle(Icons.rotate_right, AppColors.accent),
                      ),
                    ),
                    // resize — bottom-right
                    _corner(
                      right: 2,
                      bottom: 2,
                      inv: inv,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: _onResizeStart,
                        onPanUpdate: _onResizeUpdate,
                        onPanEnd: _onHandleEnd,
                        child: _handle(Icons.open_in_full, Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _corner({
    double? left,
    double? top,
    double? right,
    double? bottom,
    required double inv,
    required Widget child,
  }) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: Transform.scale(scale: inv, child: child),
    );
  }

  Widget _handle(IconData icon, Color color) {
    return Container(
      width: 28,
      height: 28,
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
