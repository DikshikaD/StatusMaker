import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/utils/text_style_builder.dart';
import 'package:status_maker/features/editor/widgets/transformable_object.dart';

class EditableTextWidget extends StatelessWidget {
  final TextObject textObject;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onEdit; // double-tap to edit words inline
  final void Function(Offset position, double scale, double rotation) onTransformEnd;

  const EditableTextWidget({
    super.key,
    required this.textObject,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
    required this.onEdit,
    required this.onTransformEnd,
  });

  @override
  Widget build(BuildContext context) {
    return TransformableObject(
      position: textObject.position,
      scale: textObject.scale,
      rotation: textObject.rotation,
      isSelected: isSelected,
      onSelect: onSelect,
      onDelete: onDelete,
      onDoubleTap: onEdit,
      onTransformEnd: onTransformEnd,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            textObject.text.isEmpty ? ' ' : textObject.text,
            textAlign: textObject.textAlign,
            style: buildTextStyle(textObject),
          ),
        ),
      ),
    );
  }
}
