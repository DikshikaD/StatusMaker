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

    Widget img = Image.file(
      File(image.path),
      width: size.width,
      height: size.height,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Container(
        width: size.width,
        height: size.height,
        color: Colors.white12,
        child: const Icon(Icons.broken_image, color: Colors.white54, size: 40),
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
        child: _clip(img),
      ),
    );
  }
}
