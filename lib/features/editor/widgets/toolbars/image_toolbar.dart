import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';

/// Contextual toolbar for the selected image: pick a shape, or delete.
/// Move / resize / rotate happen by hand on the canvas, so they need no buttons.
class ImageToolbar extends StatefulWidget {
  final ImageObject image;
  final ValueChanged<ImageShape> onShape;
  final VoidCallback onDelete;

  const ImageToolbar({
    super.key,
    required this.image,
    required this.onShape,
    required this.onDelete,
  });

  @override
  State<ImageToolbar> createState() => _ImageToolbarState();
}

class _ImageToolbarState extends State<ImageToolbar> {
  bool _showShapes = true;

  static const _shapes = <(ImageShape, IconData, String)>[
    (ImageShape.square, Icons.crop_square, 'Square'),
    (ImageShape.roundedRectangle, Icons.rounded_corner, 'Rounded'),
    (ImageShape.circle, Icons.circle_outlined, 'Circle'),
    (ImageShape.oval, Icons.crop_landscape, 'Oval'),
    (ImageShape.heart, Icons.favorite_border, 'Heart'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: _showShapes
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _shapes.map(_shapeButton).toList(),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _action(
                    icon: Icons.category_outlined,
                    label: 'Shape',
                    active: _showShapes,
                    onTap: () => setState(() => _showShapes = !_showShapes),
                  ),
                  const Spacer(),
                  _action(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    active: false,
                    color: Colors.redAccent,
                    onTap: widget.onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shapeButton((ImageShape, IconData, String) s) {
    final selected = widget.image.shape == s.$1;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onShape(s.$1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(s.$2, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 5),
          Text(s.$3,
              style: const TextStyle(
                  color: AppColors.darkTextSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? Colors.white;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.accent.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: c, size: 22),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: c, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
