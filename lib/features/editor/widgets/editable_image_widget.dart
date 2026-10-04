import 'package:flutter/material.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/utils/canvas_image.dart';
import 'package:status_maker/features/editor/utils/image_shape_utils.dart';
import 'package:status_maker/features/editor/widgets/photo_frame_painter.dart';
import 'package:status_maker/features/editor/widgets/transformable_object.dart';

class EditableImageWidget extends StatelessWidget {
  final ImageObject image;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final Size canvasSize;
  final void Function(
    Offset position,
    double scale,
    double rotation,
    double? boxWidth,
  ) onTransformEnd;

  const EditableImageWidget({
    super.key,
    required this.image,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
    required this.onTransformEnd,
    required this.canvasSize,
  });

  @override
  Widget build(BuildContext context) {
    final size = baseSizeForImageShape(image.shape);

    final bool empty = image.isPlaceholder || image.path.isEmpty;

    final Widget img = empty
        ? Container(
            width: size.width,
            height: size.height,
            // 0.18 was too weak to carry white text over a light or pastel
            // background template — and this placeholder is what gets exported
            // if the slot is never filled.
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
      canvasSize: canvasSize,
      // Null boxWidth => corner handles scale the photo proportionally.
      // Stretching one axis of a photo only distorts it.
      onSelect: onSelect,
      onDelete: onDelete,
      onTransformEnd: onTransformEnd,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            clipToImageShape(
              image.shape,
              empty
                  ? positionedImg
                  : softenPhotoEdge(
                      image.shape, image.softEdge, size, positionedImg),
            ),
            if (image.framed)
              IgnorePointer(
                child: CustomPaint(
                  painter: PhotoFramePainter(
                    shape: image.shape,
                    color: image.frameColor,
                    style: image.frameStyle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
