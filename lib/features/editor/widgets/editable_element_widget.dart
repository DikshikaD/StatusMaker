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
  final void Function(Offset position, double scale, double rotation)
      onTransformEnd;

  const EditableElementWidget({
    super.key,
    required this.element,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
    required this.onTransformEnd,
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
    return TransformableObject(
      position: element.position,
      scale: element.scale,
      rotation: element.rotation,
      isSelected: isSelected,
      onSelect: onSelect,
      onDelete: onDelete,
      onTransformEnd: onTransformEnd,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: CustomPaint(
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
