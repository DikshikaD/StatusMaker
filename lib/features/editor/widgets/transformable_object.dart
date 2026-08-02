import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';

/// Which handle a corner drag grabbed. The enum order is also the order the
/// handles are laid out in [_TransformableObjectState._corners].
enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

/// What the user is currently doing to the object. Exactly one at a time —
/// this is what stops a corner drag from also translating the object, and a
/// rotate drag from also resizing it.
enum _Mode { idle, move, resize, rotate }

/// Wraps any canvas object (text, image or sticker) and gives it the full set
/// of direct-manipulation interactions in ONE place:
///
///  • one-finger drag on the content to move, clamped to the canvas
///  • two-finger pinch to resize, with simultaneous twist-to-rotate
///  • four corner handles to resize (proportionally, or free-width for text)
///  • a dedicated rotate handle below the object
///  • a delete handle above the object
///
/// ## Why move/pinch/rotate share one recognizer
///
/// Drag/pinch/twist on the *content* are driven by a SINGLE `GestureDetector`'s
/// `onScaleStart/Update/End` triad. Flutter's scale recognizer natively reports
/// pan (`focalPointDelta`), zoom (`scale`) and twist (`rotation`) together for
/// the same pointer set — there is no separate recognizer per gesture, so there
/// is nothing for them to conflict over. Do not add a second
/// `GestureDetector`/`Listener` for content move/resize/rotate; route any new
/// transform behavior through this same callback triad.
///
/// The *handles* are a different matter: each is its own widget with its own
/// pan recognizer, in a separate part of the tree from the content, so a
/// pointer that lands on a handle is never also delivered to the content's
/// recognizer. [_mode] guards the remaining ambiguity — see below.
///
/// ## Why every handle is a screen-space "billboard"
///
/// The content and its selection border deliberately DO rotate/scale with the
/// object — that's correct, expected behavior (the border traces the actual
/// rotated/scaled bounds). The handles must NOT, and earlier versions that
/// nested the delete handle inside the same transform chain had a real,
/// reproduced bug: once an object was rotated (via two-finger twist), the
/// handle's hit-test region became a rotated, non-axis-aligned quadrilateral in
/// screen space. Hit-testing was still mathematically exact, but that's exactly
/// the problem — a user aiming at "the visual corner" of a rotated object no
/// longer has a forgiving, axis-aligned target, so taps that look correct to
/// the eye land just outside the true (rotated) hit box and are silently
/// dropped. Device logs confirmed this: pinch+rotate (scale 2.25x, rotation
/// ≈ -6°) followed immediately by a delete attempt produced no gesture callback
/// at all — the tap hit neither the content nor the handle.
///
/// The fix used by every production design tool (Figma, Canva, PowerPoint):
/// render selection handles as a screen-space overlay, computed from the
/// object's transformed corner positions, but never themselves rotated or
/// scaled. [_localToCanvas] does that math for all of them, so every handle is
/// always upright, always the same tappable size, and always exactly where the
/// eye expects it — independent of how the object underneath is transformed.
///
/// ## Why gestures write local state first
///
/// While a gesture is in flight only local state changes (one cheap repaint of
/// this object alone); the controller is written exactly once, on gesture end.
/// That keeps a 30–50 object canvas at full frame rate during a drag, and keeps
/// the undo stack to one entry per gesture rather than one per frame.
class TransformableObject extends StatefulWidget {
  final Offset position;
  final double scale;
  final double rotation;
  final bool isSelected;
  final Widget child;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback? onDoubleTap;

  /// Committed once per gesture, on end. [boxWidth] is null for objects that
  /// don't have a free width (images and stickers).
  final void Function(
    Offset position,
    double scale,
    double rotation,
    double? boxWidth,
  ) onTransformEnd;

  /// The canvas the object lives on, used to clamp dragging so an object can
  /// never be flung somewhere it can't be grabbed back from. Supplied by the
  /// canvas's own `LayoutBuilder`, so it's the real laid-out size on this
  /// device rather than an assumed design-space constant.
  final Size canvasSize;

  /// Non-null for objects whose width the user may set directly (text): corner
  /// handles then re-wrap the box to a new width in the object's own unscaled
  /// space, and this widget applies it as a max-width constraint on [child].
  /// Null for images and stickers, whose corner handles scale proportionally
  /// instead — stretching a photo or a vector sticker on one axis only
  /// distorts it.
  final double? boxWidth;

  /// Whether two-finger twist and the rotate handle are available. Defaults to
  /// true; set to false for element types that should stay axis-aligned.
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
    required this.canvasSize,
    this.boxWidth,
    this.onDoubleTap,
    this.enableRotation = true,
  });

  @override
  State<TransformableObject> createState() => _TransformableObjectState();
}

class _TransformableObjectState extends State<TransformableObject> {
  // Gap between the content and the selection border — kept small so the
  // border hugs the content closely. Handles are screen-space billboards (see
  // the class doc comment), so this no longer has to keep them clear of the
  // content's hit box; it's purely a visual choice now.
  static const double _pad = kObjectContentPadding;

  // Handles are drawn small but hit-tested large: `_hitSize` is the invisible
  // touch target, `_dotSize`/`_actionSize` are what's painted inside it. 44dp
  // is the platform minimum tappable target on both iOS and Android, and it's
  // what keeps the corners usable on a small phone where a 3x-scaled sticker's
  // corners sit only a few px apart.
  static const double _hitSize = 44;
  static const double _dotSize = 18;
  static const double _actionSize = 30;

  // Screen-space gap between the object's edge and the delete/rotate handles.
  // Applied *after* scaling (see [_outward]) so the handles sit the same
  // distance away whether the object is at 0.3x or 6x — at 6x a gap expressed
  // in the object's own space would push them right off the canvas.
  static const double _handleGap = 22;

  // How much of the object must stay on the canvas when dragging: its center
  // is clamped this far inside the edges. Clamping the *center* rather than
  // the bounding box is deliberate — users legitimately want an object to
  // bleed off the edge, and this still guarantees a grabbable area remains.
  static const double _edgeMargin = 12;

  // Rotation snaps to the nearest right angle when within this many radians
  // (~4°), so "straight" is easy to hit by hand. Only right angles snap; a
  // finer grid (every 15°) makes free rotation feel notchy.
  static const double _snapWindow = 0.07;

  // Measured once layout completes; used to place the billboard handles at the
  // object's actual corners. A reasonable default covers the very first frame
  // before the real measurement lands, and [_measured] keeps the handles
  // hidden until then so they never visibly jump into place.
  final GlobalKey _boxKey = GlobalKey();
  Size _measuredSize = const Size(160, 160);
  bool _measured = false;

  late Offset _position;
  late double _scale;
  late double _rotation;
  late double? _boxWidth;

  _Mode _mode = _Mode.idle;
  bool get _interacting => _mode != _Mode.idle;

  // --- gesture bases: captured on start, never re-read mid-gesture ----------
  // Every in-flight calculation is derived from these plus the accumulated
  // pointer delta. Reading live values instead would feed each frame's result
  // back into the next frame's input — for a text width drag that's an actual
  // feedback loop (changing the width changes the measured size the anchor
  // math uses), which shows up as jitter that gets worse the faster you drag.
  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  double _baseBoxWidth = kDefaultTextBoxWidth;
  Size _baseSize = Size.zero;
  Offset _dragAccum = Offset.zero;

  // resize
  Offset _anchorLocal = Offset.zero; // the corner held fixed, in local space
  Offset _anchorCanvas = Offset.zero; // where that corner is pinned on canvas
  Offset _grabCanvas = Offset.zero; // where the dragged corner started
  double _grabDist = 1.0;
  double _widthSign = 1.0; // +1 dragging a right corner, -1 a left one

  // rotate
  double _grabAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant TransformableObject oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Never clobber an in-flight gesture with the controller's (older) values —
    // the gesture is the source of truth until it commits on end.
    if (!_interacting) _sync();
    // The object's footprint changes whenever its content does — a bigger font,
    // longer words, a different image shape. The handles are placed from the
    // measured footprint, so without this they'd stay at the old corners until
    // the next gesture happened to re-measure. _remeasure only calls setState
    // when the size actually differs, so this is a no-op for the common case of
    // a rebuild that didn't resize anything (e.g. a colour change).
    WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
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
    _boxWidth = widget.boxWidth;
  }

  void _commit() =>
      widget.onTransformEnd(_position, _scale, _rotation, _boxWidth);

  /// Reads the content box's actual (unscaled) layout size once it's available.
  /// Content size only changes when the underlying object changes (text edited,
  /// width resized, shape swapped), so this is cheap and rare — not per-frame.
  void _remeasure() {
    if (!mounted) return;
    final box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && (box.size != _measuredSize || !_measured)) {
      setState(() {
        _measuredSize = box.size;
        _measured = true;
      });
    }
  }

  // ---- geometry -------------------------------------------------------------

  /// Rotates [v] by the object's current rotation. Used to convert between the
  /// object's own axes and the canvas's.
  Offset _rotate(Offset v, double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);
    return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
  }

  /// Maps a point in the object's local (unscaled, unrotated) box coordinates
  /// to canvas coordinates — the same space [_position] lives in.
  ///
  /// Mirrors the paint transform order used in [build]: scale first, then
  /// rotate, both pivoting on the nominal box's own center, which is exactly
  /// what `Transform.scale` + `Transform.rotate` do to the content.
  Offset _localToCanvas(Offset local, {Size? size, double? scale, double? rot}) {
    final s = size ?? _measuredSize;
    final center = Offset(s.width / 2, s.height / 2);
    final scaled = (local - center) * (scale ?? _scale);
    return _position + center + _rotate(scaled, rot ?? _rotation);
  }

  /// A point [dist] screen-space pixels outward from [localAnchor], along the
  /// object-local direction [dir]. [dir] is rotated but NOT scaled, which is
  /// what keeps the gap constant at any zoom.
  Offset _outward(Offset localAnchor, Offset dir, double dist) =>
      _localToCanvas(localAnchor) + _rotate(dir, _rotation) * dist;

  /// Keeps the object's center inside the canvas so it can always be grabbed
  /// back. Returns [pos] untouched if the canvas is too small to clamp within
  /// (which would make the clamp bounds invalid).
  Offset _clampToCanvas(Offset pos, Size boxSize) {
    final cs = widget.canvasSize;
    if (cs.width < 2 * _edgeMargin || cs.height < 2 * _edgeMargin) return pos;
    final center = Offset(boxSize.width / 2, boxSize.height / 2);
    final c = pos + center;
    return Offset(
          c.dx.clamp(_edgeMargin, cs.width - _edgeMargin),
          c.dy.clamp(_edgeMargin, cs.height - _edgeMargin),
        ) -
        center;
  }

  /// Local-space coordinates of the four selection-border corners.
  Offset _cornerLocal(_Corner c, Size s) {
    switch (c) {
      case _Corner.topLeft:
        return const Offset(_pad, _pad);
      case _Corner.topRight:
        return Offset(s.width - _pad, _pad);
      case _Corner.bottomLeft:
        return Offset(_pad, s.height - _pad);
      case _Corner.bottomRight:
        return Offset(s.width - _pad, s.height - _pad);
    }
  }

  _Corner _opposite(_Corner c) {
    switch (c) {
      case _Corner.topLeft:
        return _Corner.bottomRight;
      case _Corner.topRight:
        return _Corner.bottomLeft;
      case _Corner.bottomLeft:
        return _Corner.topRight;
      case _Corner.bottomRight:
        return _Corner.topLeft;
    }
  }

  bool _isRightCorner(_Corner c) =>
      c == _Corner.topRight || c == _Corner.bottomRight;

  // ---- content: move + pinch to resize + twist to rotate --------------------
  // One recognizer, one set of callbacks, all three transforms — see the class
  // doc comment for why this must stay a single GestureDetector.

  void _onScaleStart(ScaleStartDetails d) {
    // One gesture owns the object at a time. Without this, landing a second
    // finger on the body mid-way through a corner drag would overwrite _mode
    // and the captured bases: the resize would freeze (its Update early-returns
    // on the changed mode), and when the fingers lifted, whichever End ran
    // second would early-return too and never commit — so the whole gesture's
    // result was silently dropped and the object snapped back on the next
    // rebuild. Claiming the mode only from idle makes the first gesture win.
    if (_mode != _Mode.idle) return;
    // Set the mode BEFORE onSelect(): selecting brings the object to front,
    // which notifies the controller and rebuilds the canvas. didUpdateWidget
    // must already see an in-flight gesture by then, or it re-syncs this
    // object from the controller's pre-gesture values and the drag visibly
    // snaps back to where it started on its very first frame.
    _mode = _Mode.move;
    _baseScale = _scale;
    _baseRotation = _rotation;
    widget.onSelect();
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    // A handle drag owns the gesture outright; ignore any stray content
    // updates while one is running rather than compounding two transforms.
    if (_mode != _Mode.move) return;
    setState(() {
      // focalPointDelta is in the coordinate space of the *event receiver* —
      // and this recognizer's GestureDetector sits INSIDE Transform.rotate ∘
      // Transform.scale (see build()). So the delta arrives already divided by
      // _scale and counter-rotated by -_rotation, while _position is in canvas
      // space. Adding it raw makes a scaled object drag at the wrong speed
      // (1/3 finger speed at 3x, ~3.3x at the 0.3 minimum, so it shoots away)
      // and a rotated object drag off at an angle to the finger. Undo the
      // transform to get back to canvas space.
      //
      // The handle drags below don't need this: their billboards live outside
      // the transform, so their deltas are already canvas-space.
      final canvasDelta = _rotate(d.focalPointDelta * _scale, _rotation);
      _position = _clampToCanvas(_position + canvasDelta, _measuredSize);
      _scale =
          (_baseScale * d.scale).clamp(kMinObjectScale, kMaxObjectScale);
      if (widget.enableRotation) _rotation = _baseRotation + d.rotation;
    });
  }

  void _onScaleEnd(ScaleEndDetails d) {
    if (_mode != _Mode.move) return;
    _mode = _Mode.idle;
    _commit();
    // The gesture may have changed the content's footprint indirectly (e.g.
    // triggered a rebuild upstream); pick up any resulting size change.
    WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
  }

  // ---- corner handles: resize ----------------------------------------------

  void _onResizeStart(_Corner corner) {
    if (_mode != _Mode.idle) return; // first gesture wins — see _onScaleStart
    _mode = _Mode.resize;
    _dragAccum = Offset.zero;
    _baseScale = _scale;
    _baseSize = _measuredSize;
    _baseBoxWidth = _boxWidth ?? kDefaultTextBoxWidth;
    _widthSign = _isRightCorner(corner) ? 1.0 : -1.0;

    _anchorLocal = _cornerLocal(_opposite(corner), _baseSize);
    _anchorCanvas = _localToCanvas(_anchorLocal, size: _baseSize);
    _grabCanvas = _localToCanvas(_cornerLocal(corner, _baseSize), size: _baseSize);
    _grabDist = (_grabCanvas - _anchorCanvas).distance;
    widget.onSelect();
  }

  void _onResizeUpdate(DragUpdateDetails d) {
    if (_mode != _Mode.resize) return;
    _dragAccum += d.delta;
    setState(() {
      if (widget.boxWidth != null) {
        _resizeWidth();
      } else {
        _resizeProportional();
      }
    });
  }

  /// Images and stickers: uniform scale about the opposite corner, which stays
  /// pinned to the canvas exactly where it was. Driven by how far the dragged
  /// corner now is from that anchor, relative to how far it started — so the
  /// corner tracks the finger regardless of rotation, with no trigonometry per
  /// axis and no way for the two axes to disagree and skew the object.
  void _resizeProportional() {
    if (_grabDist < 1) return; // degenerate: corners started coincident
    final dist = (_grabCanvas + _dragAccum - _anchorCanvas).distance;
    _scale = (_baseScale * dist / _grabDist)
        .clamp(kMinObjectScale, kMaxObjectScale);

    // Re-derive position so the anchor corner lands back on _anchorCanvas at
    // the new scale — the inverse of _localToCanvas solved for _position.
    final center = Offset(_baseSize.width / 2, _baseSize.height / 2);
    // Clamped like every other path that writes _position: growing an object
    // from a corner pushes the anchor-derived position outward without limit,
    // so without this an image or sticker could be resized until its center
    // left the canvas — the exact state _clampToCanvas exists to prevent.
    _position = _clampToCanvas(
      _anchorCanvas - center - _rotate((_anchorLocal - center) * _scale, _rotation),
      _baseSize,
    );
  }

  /// Text: free horizontal resize. The box re-wraps to a new width and the
  /// glyphs keep their size (font size stays the toolbar's job) — this is the
  /// one axis a text object stretches on without distorting.
  ///
  /// [_position] is deliberately left alone, so the box grows and shrinks about
  /// its own center exactly like pinch-scaling does.
  ///
  /// An earlier version shifted position to pin the edge opposite the handle.
  /// The algebra was right, but it assumed the box's measured width tracks
  /// [_boxWidth] one-for-one — and it doesn't. The width is applied as a
  /// *max* (see build()), so a line of text shorter than the box shrink-wraps
  /// and widening the box changes the measured width by nothing at all. The
  /// position shift still ran, so dragging a short caption's corner slid it
  /// across the canvas without resizing anything. Not shifting has no such
  /// failure mode: when the width can't grow, nothing moves.
  void _resizeWidth() {
    // Project the drag onto the object's own horizontal axis, then undo the
    // scale: _boxWidth is in the object's unscaled space.
    final local = _rotate(_dragAccum, -_rotation) / _scale;
    _boxWidth = (_baseBoxWidth + local.dx * _widthSign)
        .clamp(kMinTextBoxWidth, kMaxTextBoxWidth);
  }

  void _onResizeEnd() {
    if (_mode != _Mode.resize) return;
    _mode = _Mode.idle;
    _commit();
    WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
  }

  // ---- rotate handle --------------------------------------------------------

  /// The object's center in canvas space. Rotation pivots here, and since
  /// [_position] is untouched while rotating, it stays fixed for the whole
  /// gesture — so the object spins in place instead of orbiting.
  Offset get _centerCanvas =>
      _position + Offset(_measuredSize.width / 2, _measuredSize.height / 2);

  void _onRotateStart() {
    if (_mode != _Mode.idle) return; // first gesture wins — see _onScaleStart
    _mode = _Mode.rotate;
    _dragAccum = Offset.zero;
    _baseRotation = _rotation;
    _grabCanvas = _rotateHandleCenter();
    final v = _grabCanvas - _centerCanvas;
    _grabAngle = math.atan2(v.dy, v.dx);
    widget.onSelect();
  }

  void _onRotateUpdate(DragUpdateDetails d) {
    if (_mode != _Mode.rotate) return;
    _dragAccum += d.delta;
    final v = _grabCanvas + _dragAccum - _centerCanvas;
    if (v.distance < 1) return; // pointer on the pivot: angle is meaningless
    setState(() {
      _rotation = _snap(_baseRotation + (math.atan2(v.dy, v.dx) - _grabAngle));
    });
  }

  void _onRotateEnd() {
    if (_mode != _Mode.rotate) return;
    _mode = _Mode.idle;
    _commit();
  }

  /// Pulls [angle] to the nearest right angle when it's already close, so
  /// upright/sideways are easy to land on by hand. Also normalizes to
  /// [-pi, pi) so a few full spins don't accumulate into a huge stored value.
  /// (Dart's `%` on doubles is Euclidean — the result is always in [0, 2pi)
  /// here — so no negative correction is needed after it.)
  double _snap(double angle) {
    const quarter = math.pi / 2;
    final nearest = (angle / quarter).roundToDouble() * quarter;
    final snapped = (angle - nearest).abs() < _snapWindow ? nearest : angle;
    return (snapped + math.pi) % (2 * math.pi) - math.pi;
  }

  // ---- build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final s = _measuredSize;
    // Handles are hidden until the content has actually been measured, so they
    // never appear at the placeholder size and then jump to the real corners.
    final showHandles = widget.isSelected && _measured;

    Widget content = widget.child;
    if (_boxWidth != null) {
      // Owned here rather than by the caller so an in-progress width drag
      // renders at the live width — the caller only ever has the committed one.
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _boxWidth!),
        child: content,
      );
    }

    return Positioned.fill(
      // This RepaintBoundary is what makes dragging/pinching/rotating cheap:
      // it isolates EVERYTHING this widget paints (content + border + the
      // billboard handles below) into its own compositing layer, so a
      // per-frame setState here repaints only this one element — never the
      // rest of the canvas. Previously the billboard handle sat outside any
      // boundary at this level, so every drag/resize frame had to repaint
      // starting from the canvas's own top-level RepaintBoundary (in
      // status_canvas.dart) instead of this element's — i.e. the WHOLE canvas
      // repainted on every gesture frame. That cost scales with the canvas's
      // total content, which is exactly why it got worse at high zoom (more/
      // larger pixels to redraw each frame). Keep this boundary wrapping the
      // full per-object Stack, not just the content subtree.
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
                  // clipBehavior: Clip.none so the selection border (inset by
                  // _pad, i.e. outside the content itself) isn't clipped —
                  // this Stack's own size is fixed by the Padding below, so it
                  // never affects the content's actual size/hit box.
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
                          child: content,
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

            // ---- billboard handles ------------------------------------------
            // Siblings of the transformed content, never inside it — see the
            // class doc comment. They're declared after it so they hit-test
            // first (Stack tests children in reverse), which is what makes a
            // corner handle sitting on top of the object's own edge grab the
            // resize rather than starting a drag. Still inside the
            // RepaintBoundary above, so repainting them each gesture frame
            // stays isolated to this object.
            if (showHandles) ...[
              for (final corner in _Corner.values)
                _billboard(
                  center: _localToCanvas(_cornerLocal(corner, s)),
                  child: _resizeDot(corner),
                ),
              _billboard(
                center: _outward(
                    Offset(s.width / 2, _pad), const Offset(0, -1), _handleGap),
                child: _action(
                  Icons.close,
                  Colors.redAccent,
                  onTap: widget.onDelete,
                ),
              ),
              if (widget.enableRotation)
                _billboard(
                  center: _rotateHandleCenter(),
                  child: _rotateKnob(),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// Clamped, because [_onRotateStart] measures the grab angle from this point
  /// and _billboard draws the knob at the clamped one. If the two disagreed,
  /// the angle the gesture starts from wouldn't be the angle under the user's
  /// finger, and the object would kick sideways the instant the drag began.
  Offset _rotateHandleCenter() => _keepOnCanvas(_outward(
        Offset(_measuredSize.width / 2, _measuredSize.height - _pad),
        const Offset(0, 1),
        _handleGap,
      ));

  /// Pulls a handle back inside the canvas if it would otherwise sit outside
  /// it. The canvas Stack clips to its bounds, and clipping removes a widget
  /// from hit-testing as well as from painting — so a handle placed off-canvas
  /// isn't just invisible, it's dead. That's reachable in normal use: the
  /// delete and rotate handles are deliberately offset _handleGap px beyond the
  /// object's edge, so any object dragged to the top or bottom of the canvas
  /// pushes one of them over the line. Clamping slides it back along the edge,
  /// where it still reads as belonging to the object (and still hit-tests
  /// before the content, being declared after it).
  Offset _keepOnCanvas(Offset center) {
    final cs = widget.canvasSize;
    const r = _hitSize / 2;
    if (cs.width < _hitSize || cs.height < _hitSize) return center;
    return Offset(
      center.dx.clamp(r, cs.width - r),
      center.dy.clamp(r, cs.height - r),
    );
  }

  /// Positions [child] centered on [center], in an upright `_hitSize` touch
  /// target regardless of how the object below is transformed.
  Widget _billboard({required Offset center, required Widget child}) {
    final c = _keepOnCanvas(center);
    return Positioned(
      left: c.dx - _hitSize / 2,
      top: c.dy - _hitSize / 2,
      width: _hitSize,
      height: _hitSize,
      child: Center(child: child),
    );
  }

  Widget _resizeDot(_Corner corner) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Pan, not scale: a corner handle is a one-finger drag by definition, and
      // a pan recognizer here can't be confused with the content's scale
      // recognizer over in the other subtree.
      onPanStart: (_) => _onResizeStart(corner),
      onPanUpdate: _onResizeUpdate,
      onPanEnd: (_) => _onResizeEnd(),
      onPanCancel: _onResizeEnd,
      // The opaque box fills the full _hitSize target; the visible dot is
      // smaller so four of them don't crowd a small object.
      child: SizedBox(
        width: _hitSize,
        height: _hitSize,
        child: Center(
          child: Container(
            width: _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3), blurRadius: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rotateKnob() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => _onRotateStart(),
      onPanUpdate: _onRotateUpdate,
      onPanEnd: (_) => _onRotateEnd(),
      onPanCancel: _onRotateEnd,
      child: SizedBox(
        width: _hitSize,
        height: _hitSize,
        child: Center(child: _chip(Icons.rotate_right, AppColors.accent)),
      ),
    );
  }

  Widget _action(IconData icon, Color color, {required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: _hitSize,
        height: _hitSize,
        child: Center(child: _chip(icon, color)),
      ),
    );
  }

  Widget _chip(IconData icon, Color color) {
    return Container(
      width: _actionSize,
      height: _actionSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 4),
        ],
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }
}
