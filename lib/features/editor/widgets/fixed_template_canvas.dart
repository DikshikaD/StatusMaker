import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/fixed_templates.dart';
import 'package:status_maker/features/editor/data/status_design.dart';
import 'package:status_maker/features/editor/utils/canvas_image.dart';
import 'package:status_maker/features/editor/utils/image_shape_utils.dart';
import 'package:status_maker/features/editor/utils/text_style_builder.dart';
import 'package:status_maker/features/editor/widgets/element_painter.dart';
import 'package:status_maker/features/editor/widgets/frame_painter.dart';
import 'package:status_maker/features/editor/widgets/heart_clipper.dart';
import 'package:status_maker/features/editor/widgets/template_background.dart';

/// Renders a [StatusDesign] with a completely LOCKED layout: every object is
/// drawn exactly where the design says, with no drag / pinch / rotate / delete
/// affordances at all. The only interactions are the optional tap callbacks
/// (edit a text's words, fill or replace the photo slot).
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

  const FixedTemplateCanvas({
    super.key,
    required this.design,
    this.repaintKey,
    this.onTextTap,
    this.onPhotoTap,
    this.onTextDoubleTap,
    this.onBackgroundTap,
    this.selectedId,
    this.lineLimits,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: kFixedCanvasSize.width,
        height: kFixedCanvasSize.height,
        child: RepaintBoundary(
          key: repaintKey,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: TemplateBackground(
                  state: design.background,
                  onTap: onBackgroundTap ?? () {},
                ),
              ),
              ...design.elements.map(_element),
              ...design.images.map(_image),
              ...design.texts.map(_text),
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
    );
  }

  /// Places [child] exactly like the free editor's TransformableObject does
  /// (same 6px content padding, same center-pivoted scale/rotate), so a design
  /// saved from here reopens in the full editor in the very same spot.
  Widget _placed({
    required Offset position,
    required double scale,
    required double rotation,
    required Widget child,
    bool selected = false,
    VoidCallback? onTap,
    VoidCallback? onDoubleTap,
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
    if (onTap != null || onDoubleTap != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        child: content,
      );
    }
    return Positioned(
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
      position: t.position,
      scale: t.scale,
      rotation: t.rotation,
      selected: selectedId == t.id,
      onTap: onTextTap == null ? null : () => onTextTap!(t),
      onDoubleTap: onTextDoubleTap == null ? null : () => onTextDoubleTap!(t),
      // A fixed 300-wide block (not just a max) so `textAlign` centers the
      // words reliably no matter what the user types — including a short line
      // that would otherwise shrink-wrap and drift off the canvas's center
      // line. Note this differs from EditableTextWidget, which shrink-wraps to
      // its content: if one of these designs is later reopened in the full
      // editor via "Customize", a centered short line will sit further left
      // there (the user can drag it, since that editor is unlocked anyway).
      child: SizedBox(
        width: 300,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: t.highlight != null
              ? BoxDecoration(
                  color: t.highlight,
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Text(
            t.text.isEmpty ? ' ' : t.text,
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
    final bool empty = img.isPlaceholder || img.path.isEmpty;

    Widget content;
    if (empty) {
      content = Container(
        width: size.width,
        height: size.height,
        color: Colors.black.withValues(alpha: 0.18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_a_photo_outlined, color: Colors.white, size: 34),
            SizedBox(height: 8),
            Text('Add photo',
                style: TextStyle(color: Colors.white, fontSize: 13)),
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
            cacheWidth:
                (size.width * 2 * img.photoScale).round().clamp(1, 2400),
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
            clipToImageShape(img.shape, content),
            if (img.framed)
              IgnorePointer(
                child: CustomPaint(
                  painter: _SlotBorderPainter(
                    shape: img.shape,
                    color: img.frameColor,
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
                  cacheWidth: (size.width * 2).round(),
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

/// Strokes the outline of a photo slot's shape — same look as the free
/// editor's framed photos.
class _SlotBorderPainter extends CustomPainter {
  final ImageShape shape;
  final Color color;

  const _SlotBorderPainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..isAntiAlias = true;
    final inset = paint.strokeWidth / 2;
    final rect = Rect.fromLTWH(
        inset, inset, size.width - 2 * inset, size.height - 2 * inset);

    switch (shape) {
      case ImageShape.square:
        canvas.drawRect(rect, paint);
        break;
      case ImageShape.roundedRectangle:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(24)),
          paint,
        );
        break;
      case ImageShape.circle:
      case ImageShape.oval:
        canvas.drawOval(rect, paint);
        break;
      case ImageShape.heart:
        canvas.drawPath(
            HeartClipper().getClip(Size(size.width, size.height)), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _SlotBorderPainter old) =>
      old.shape != shape || old.color != color;
}
