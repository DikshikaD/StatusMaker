import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/utils/canvas_image.dart';
import 'package:status_maker/features/editor/utils/image_shape_utils.dart';
import 'package:status_maker/features/editor/widgets/heart_clipper.dart';
import 'package:status_maker/features/editor/widgets/transformable_object.dart';

class EditableImageWidget extends StatelessWidget {
  final ImageObject image;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final void Function(Offset position, double scale, double rotation) onTransformEnd;

  const EditableImageWidget({
    super.key,
    required this.image,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
    required this.onTransformEnd,
  });

  @override
  Widget build(BuildContext context) {
    final size = baseSizeForImageShape(image.shape);

    final bool empty = image.isPlaceholder || image.path.isEmpty;

    final Widget img = empty
        ? Container(
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
          )
        : canvasImage(
            image.path,
            width: size.width,
            height: size.height,
            fit: BoxFit.cover,
            // Decode at the resolution actually shown on screen (scaled up a
            // little extra to stay sharp when the user zooms in via the photo
            // reposition screen) instead of the full camera resolution —
            // massively lowers memory per photo.
            cacheWidth: (size.width * 2 * image.photoScale)
                .round()
                .clamp(1, 2400),
            errorBuilder: (_, __, ___) => Container(
              width: size.width,
              height: size.height,
              color: Colors.white12,
              child:
                  const Icon(Icons.broken_image, color: Colors.white54, size: 40),
            ),
          );

    // The user's chosen pan/zoom of the photo *inside* the shape — applied
    // before clipping so it crops exactly like the reposition screen showed.
    final Widget positionedImg = empty
        ? img
        : Transform.translate(
            offset: image.photoOffset,
            child: Transform.scale(scale: image.photoScale, child: img),
          );

    return TransformableObject(
      position: image.position,
      scale: image.scale,
      rotation: image.rotation,
      isSelected: isSelected,
      onSelect: onSelect,
      onDelete: onDelete,
      onTransformEnd: onTransformEnd,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            clipToImageShape(image.shape, positionedImg),
            if (image.framed)
              IgnorePointer(
                child: CustomPaint(
                  painter: _ShapeBorderPainter(
                    shape: image.shape,
                    color: image.frameColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Strokes the outline of an image's shape to make a photo frame/border.
class _ShapeBorderPainter extends CustomPainter {
  final ImageShape shape;
  final Color color;

  const _ShapeBorderPainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..isAntiAlias = true;
    final inset = paint.strokeWidth / 2;
    final rect = Rect.fromLTWH(inset, inset, w - 2 * inset, h - 2 * inset);

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
        final path = HeartClipper().getClip(Size(w, h));
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ShapeBorderPainter old) =>
      old.shape != shape || old.color != color;
}
