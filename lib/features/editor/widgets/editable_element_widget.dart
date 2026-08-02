import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/widgets/element_painter.dart';
import 'package:status_maker/features/editor/widgets/transformable_object.dart';

/// A draggable / resizable / rotatable vector element on the canvas.
class EditableElementWidget extends StatelessWidget {
  final ElementObject element;
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

  const EditableElementWidget({
    super.key,
    required this.element,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
    required this.onTransformEnd,
    required this.canvasSize,
  });

  // Lines/arrows read better as a wider box; the rest stay square.
  Size _baseSize() {
    switch (element.shape) {
      case ElementShape.line:
      case ElementShape.arrow:
        return const Size(160, 80);
      default:
        return const Size(120, 120);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = _baseSize();
    final path = element.assetPath;
    return TransformableObject(
      position: element.position,
      scale: element.scale,
      rotation: element.rotation,
      isSelected: isSelected,
      canvasSize: canvasSize,
      // Null boxWidth => corner handles scale the sticker proportionally.
      onSelect: onSelect,
      onDelete: onDelete,
      onTransformEnd: onTransformEnd,
      child: SizedBox(
        width: size.width,
        height: size.height,
        // An illustrated sticker image renders as-is (it already has its own
        // colours/shading); everything else is drawn in code by
        // ElementPainter and recolours to whatever the user picked.
        child: path != null
            ? Image.asset(
                path,
                fit: BoxFit.contain,
                cacheWidth: (size.width * 2).round(),
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 40,
                ),
              )
            : CustomPaint(
                painter: ElementPainter(
                  shape: element.shape,
                  color: element.color,
                  strokeWidth: element.strokeWidth,
                ),
              ),
      ),
    );
  }
}
