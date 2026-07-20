import 'dart:io';
import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
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

  Size _baseSize() {
    switch (image.shape) {
      case ImageShape.square:
      case ImageShape.circle:
        return const Size(220, 220);
      case ImageShape.roundedRectangle:
        return const Size(220, 270);
      case ImageShape.oval:
        return const Size(200, 260);
      case ImageShape.heart:
        return const Size(240, 220);
    }
  }

  Widget _clip(Widget img) {
    switch (image.shape) {
      case ImageShape.square:
        return img;
      case ImageShape.roundedRectangle:
        return ClipRRect(borderRadius: BorderRadius.circular(24), child: img);
      case ImageShape.circle:
      case ImageShape.oval:
        return ClipOval(child: img);
      case ImageShape.heart:
        return ClipPath(clipper: HeartClipper(), child: img);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = _baseSize();

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
        : Image.file(
            File(image.path),
            width: size.width,
            height: size.height,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => Container(
              width: size.width,
              height: size.height,
              color: Colors.white12,
              child:
                  const Icon(Icons.broken_image, color: Colors.white54, size: 40),
            ),
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
            _clip(img),
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
