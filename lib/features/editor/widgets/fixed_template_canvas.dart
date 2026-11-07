import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/fixed_templates.dart';
import 'package:status_maker/features/editor/data/status_design.dart';
import 'package:status_maker/features/editor/utils/canvas_image.dart';
import 'package:status_maker/features/editor/utils/editor_export.dart';
import 'package:status_maker/features/editor/utils/image_shape_utils.dart';
import 'package:status_maker/features/editor/utils/text_style_builder.dart';
import 'package:status_maker/features/editor/widgets/element_painter.dart';
import 'package:status_maker/features/editor/widgets/frame_painter.dart';
import 'package:status_maker/features/editor/widgets/photo_frame_painter.dart';
import 'package:status_maker/features/editor/widgets/template_background.dart';

/// Renders a [StatusDesign] at its authored layout. Nothing can be resized,
/// rotated or deleted here; the interactions are the optional tap callbacks
/// (edit a text's words, fill or replace the photo slot) and — when
/// [onTextMove] is supplied — dragging a text layer to a new position.
///
/// Moving is generic over every text layer of every design: it only changes
/// the layer's `position` (in the same 360×640 design space the template is
/// authored in and exported from), never its width, line allowance or style,
/// so the slot keeps its footprint and the export matches the preview.
///
/// Always lays out at [kFixedCanvasSize] and scales to fit whatever space it's
/// given, so fixed-template coordinates render identically on every device —
/// and the preview cards in the Create tab are pixel-true miniatures.
class FixedTemplateCanvas extends StatelessWidget {
  final StatusDesign design;
  final GlobalKey? repaintKey;

  /// Tapping an object selects it (the screen then shows that object's
  /// contextual toolbar). There are deliberately no drag / pinch / rotate /
  /// delete affordances — the layout is fixed.
  final void Function(TextObject t)? onTextTap;
  final void Function(ImageObject i)? onPhotoTap;

  /// Double-tapping a text jumps straight into editing its words.
  final void Function(TextObject t)? onTextDoubleTap;

  /// Drag-to-move for text layers. All three are null for read-only previews.
  /// [onTextMove] receives the new top-left position in design space (already
  /// clamped so the text's centre stays on the canvas) on every drag frame.
  final void Function(TextObject t)? onTextMoveStart;
  final void Function(TextObject t, Offset position)? onTextMove;
  final void Function(TextObject t)? onTextMoveEnd;

  /// Tapping empty canvas clears the selection.
  final VoidCallback? onBackgroundTap;

  /// Id of the currently selected object — outlined so the user can see what
  /// the toolbar is acting on. Never included in the exported image (the
  /// screen clears the selection before capturing).
  final String? selectedId;

  /// Per-slot line allowance (see [FixedTemplate.lineLimits]). Text longer than
  /// its slot allows is ellipsized rather than pushing the design out of shape.
  /// Unlimited when null or when a slot has no entry.
  final Map<String, int>? lineLimits;

  /// Set only while the editor rasterises the canvas for Save / Post / Share:
  /// editing-only placeholders — an unfilled "Add photo" slot and the
  /// "— Your Name" hint in an empty name slot — are left out of the image.
  final bool exportMode;

  /// A small, non-interactive grid/row card. Generated backgrounds are drawn
  /// from a shared cached bitmap instead of running their shader passes live
  /// for every card — see [TemplateBackground.useCachedRaster].
  final bool preview;

  const FixedTemplateCanvas({
    super.key,
    required this.design,
    this.repaintKey,
    this.onTextTap,
    this.onPhotoTap,
    this.onTextDoubleTap,
    this.onTextMoveStart,
    this.onTextMove,
    this.onTextMoveEnd,
    this.onBackgroundTap,
    this.preview = false,
    this.selectedId,
    this.lineLimits,
    this.exportMode = false,
  });

  static bool _isEmptyImage(ImageObject img) =>
      img.isPlaceholder || img.path.isEmpty;

  /// The localized name hint [FixedTemplate.design] puts in an empty name slot.
  static bool isNamePlaceholder(String text) => text == S.t('name_placeholder');

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: kFixedCanvasSize.width,
        height: kFixedCanvasSize.height,
        // The rounded corners are an on-screen nicety only. The clip sits
        // OUTSIDE the RepaintBoundary, so the exported PNG stays square with
        // fully opaque corners (transparent ones show as black in WhatsApp).
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: RepaintBoundary(
            key: repaintKey,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                TemplateBackground(
                  state: design.background,
                  onTap: onBackgroundTap ?? () {},
                  useCachedRaster: preview,
                ),
                ...design.elements.map(_element),
                ...design.images
                    .where((i) => !(exportMode && _isEmptyImage(i)))
                    .map(_image),
                ..._orderedTexts().map(_text),
                if (design.frame != StatusFrame.none)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: FramePainter(
                          frame: design.frame,
                          color: design.frameColor,
                          width: design.frameWidth,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Text layers in paint order, with the selected one moved last so it paints
  /// — and therefore hit-tests — on top of everything else, exactly like the
  /// free editor brings a selected object to front. Without this, a slot the
  /// user has dragged underneath another (the only way two slots overlap, since
  /// every authored layout keeps its slots in separate bands) could be selected
  /// through its one exposed sliver but never dragged, because the slot on top
  /// of it would keep intercepting the gesture.
  ///
  /// Order is otherwise preserved, and each placed text carries a stable
  /// [ValueKey] (see [_text]) so moving one to the end of the list reattaches
  /// its [_MovableSlot] state rather than resetting a drag in progress.
  List<TextObject> _orderedTexts() {
    final id = selectedId;
    if (id == null) return design.texts;
    final i = design.texts.indexWhere((t) => t.id == id);
    if (i == -1) return design.texts;
    return [
      ...design.texts.where((t) => t.id != id),
      design.texts[i],
    ];
  }

  /// Places [child] exactly like the free editor's TransformableObject does
  /// (same 6px content padding, same center-pivoted scale/rotate), so a design
  /// saved from here reopens in the full editor in the very same spot.
  Widget _placed({
    required Offset position,
    required double scale,
    required double rotation,
    required Widget child,
    Key? slotKey,
    bool selected = false,
    VoidCallback? onTap,
    VoidCallback? onDoubleTap,
    VoidCallback? onMoveStart,
    ValueChanged<Offset>? onMove,
    VoidCallback? onMoveEnd,
  }) {
    // The outline sits in the object's own 6px padding ring, so it hugs the
    // content without changing its size or where it sits.
    Widget content = Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(padding: const EdgeInsets.all(6), child: child),
        if (selected)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accent, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
      ],
    );
    if (onMove != null) {
      content = _MovableSlot(
        position: position,
        scale: scale,
        rotation: rotation,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onMoveStart: onMoveStart,
        onMove: onMove,
        onMoveEnd: onMoveEnd,
        child: content,
      );
    } else if (onTap != null || onDoubleTap != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        child: content,
      );
    }
    return Positioned(
      key: slotKey,
      left: position.dx,
      top: position.dy,
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(scale: scale, child: content),
      ),
    );
  }

  Widget _text(TextObject t) {
    return _placed(
      // Stable across the selected-last reorder in [_orderedTexts], so a slot
      // moved to the top of the paint order keeps its _MovableSlot state and an
      // in-progress drag isn't reset.
      slotKey: ValueKey('txt_${t.id}'),
      position: t.position,
      scale: t.scale,
      rotation: t.rotation,
      selected: selectedId == t.id,
      onTap: onTextTap == null ? null : () => onTextTap!(t),
      onDoubleTap: onTextDoubleTap == null ? null : () => onTextDoubleTap!(t),
      onMoveStart: onTextMoveStart == null ? null : () => onTextMoveStart!(t),
      onMove: onTextMove == null ? null : (p) => onTextMove!(t, p),
      onMoveEnd: onTextMoveEnd == null ? null : () => onTextMoveEnd!(t),
      // A fixed 300-wide block (not just a max) so `textAlign` centers the
      // words reliably no matter what the user types — including a short line
      // that would otherwise shrink-wrap and drift off the canvas's center
      // line. Note this differs from EditableTextWidget, which shrink-wraps to
      // its content: if one of these designs is later reopened in the full
      // editor via "Customize", a centered short line will sit further left
      // there (the user can drag it, since that editor is unlocked anyway).
      child: SizedBox(
        // effectiveBoxWidth, not a literal 300: it resolves to exactly 300 for
        // every fixed template (none of them set boxWidth), but a design that
        // *was* width-resized in the free editor and then rendered here keeps
        // the width it was given instead of snapping back.
        width: t.effectiveBoxWidth,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: t.highlight != null
              ? BoxDecoration(
                  color: t.highlight,
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Text(
            t.text.isEmpty || (exportMode && isNamePlaceholder(t.text))
                ? ' '
                : t.text,
            textAlign: t.textAlign,
            style: buildTextStyle(t),
            maxLines: lineLimits?[t.id],
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _image(ImageObject img) {
    final size = baseSizeForImageShape(img.shape);
    final bool empty = _isEmptyImage(img);

    Widget content;
    if (empty) {
      content = Container(
        width: size.width,
        height: size.height,
        // See EditableImageWidget's placeholder — kept in step with it.
        color: Colors.black.withValues(alpha: 0.30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined,
                color: Colors.white, size: 34),
            const SizedBox(height: 8),
            Text(S.t('add_photo'),
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      );
    } else {
      content = Transform.translate(
        offset: img.photoOffset,
        child: Transform.scale(
          scale: img.photoScale,
          child: canvasImage(
            img.path,
            width: size.width,
            height: size.height,
            fit: BoxFit.cover,
            // Enough pixels for the 3x export at this zoom, capped.
            cacheWidth:
                exportCacheWidth(size.width, img.photoScale * img.scale),
            errorBuilder: (_, __, ___) => Container(
              width: size.width,
              height: size.height,
              color: Colors.white12,
              child: const Icon(Icons.broken_image,
                  color: Colors.white54, size: 40),
            ),
          ),
        ),
      );
    }

    return _placed(
      position: img.position,
      scale: img.scale,
      rotation: img.rotation,
      selected: selectedId == img.id,
      onTap: onPhotoTap == null ? null : () => onPhotoTap!(img),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            clipToImageShape(
              img.shape,
              // Soft edges only apply to a real photo — the "Add photo"
              // placeholder box stays crisp so it reads as a tappable slot.
              empty
                  ? content
                  : softenPhotoEdge(img.shape, img.softEdge, size, content),
            ),
            if (img.framed)
              IgnorePointer(
                child: CustomPaint(
                  painter: PhotoFramePainter(
                    shape: img.shape,
                    color: img.frameColor,
                    style: img.frameStyle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _element(ElementObject el) {
    final size = el.shape == ElementShape.line || el.shape == ElementShape.arrow
        ? const Size(160, 80)
        : const Size(120, 120);
    return _placed(
      position: el.position,
      scale: el.scale,
      rotation: el.rotation,
      child: IgnorePointer(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: el.assetPath != null
              ? Image.asset(
                  el.assetPath!,
                  fit: BoxFit.contain,
                  cacheWidth: exportCacheWidth(size.width, el.scale),
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                )
              : CustomPaint(
                  painter: ElementPainter(
                    shape: el.shape,
                    color: el.color,
                    strokeWidth: el.strokeWidth,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Tap / double-tap / one-finger drag for a placed object.
///
/// Lives INSIDE the object's `Transform.rotate ∘ Transform.scale` (like the
/// free editor's TransformableObject), so the pointer delta arrives in the
/// object's own unscaled, unrotated frame; it is mapped back into design
/// space before being added to the position, otherwise a scaled or rotated
/// text would drag at the wrong speed or at an angle to the finger. The
/// enclosing FittedBox is undone automatically for the same reason.
///
/// The drag is accumulated against the position captured at drag start, so
/// the owner rebuilding with the new position each frame can't feed back into
/// the gesture.
class _MovableSlot extends StatefulWidget {
  final Offset position;
  final double scale;
  final double rotation;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onMoveStart;
  final ValueChanged<Offset> onMove;
  final VoidCallback? onMoveEnd;
  final Widget child;

  const _MovableSlot({
    required this.position,
    required this.scale,
    required this.rotation,
    required this.onMove,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onMoveStart,
    this.onMoveEnd,
  });

  @override
  State<_MovableSlot> createState() => _MovableSlotState();
}

class _MovableSlotState extends State<_MovableSlot> {
  /// How far inside the canvas edge the text's centre is kept, so a dragged
  /// text can bleed off the edge but can always be grabbed back.
  static const double _edgeMargin = 12;

  Offset _start = Offset.zero;
  Offset _accum = Offset.zero;
  bool _dragging = false;

  Offset _toDesignSpace(Offset local) {
    final v = local * widget.scale;
    final c = math.cos(widget.rotation);
    final s = math.sin(widget.rotation);
    return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
  }

  Offset _clamp(Offset pos) {
    final size = context.size ?? Size.zero;
    final half = Offset(size.width / 2, size.height / 2);
    final c = pos + half;
    const w = kFixedCanvasSize;
    return Offset(
          c.dx.clamp(_edgeMargin, w.width - _edgeMargin),
          c.dy.clamp(_edgeMargin, w.height - _edgeMargin),
        ) -
        half;
  }

  void _end() {
    if (!_dragging) return;
    _dragging = false;
    widget.onMoveEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      onPanStart: (_) {
        _dragging = true;
        _start = widget.position;
        _accum = Offset.zero;
        widget.onMoveStart?.call();
      },
      onPanUpdate: (d) {
        if (!_dragging) return;
        _accum += _toDesignSpace(d.delta);
        widget.onMove(_clamp(_start + _accum));
      },
      onPanEnd: (_) => _end(),
      onPanCancel: _end,
      child: widget.child,
    );
  }
}
