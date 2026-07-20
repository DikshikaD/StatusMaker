import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/core/utils/responsive.dart';

/// Contextual toolbar for the selected image: pick a shape, add/replace the
/// photo, or delete. Light theme to match the app.
class ImageToolbar extends StatefulWidget {
  final ImageObject image;
  final ValueChanged<ImageShape> onShape;
  final VoidCallback onDelete;
  final VoidCallback onReplace;
  final VoidCallback onToggleFrame;

  const ImageToolbar({
    super.key,
    required this.image,
    required this.onShape,
    required this.onDelete,
    required this.onReplace,
    required this.onToggleFrame,
  });

  @override
  State<ImageToolbar> createState() => _ImageToolbarState();
}

class _ImageToolbarState extends State<ImageToolbar> {
  bool _showShapes = true;

  // Third field is a translation key resolved at build time.
  static const _shapes = <(ImageShape, IconData, String)>[
    (ImageShape.square, Icons.crop_square, 'square'),
    (ImageShape.roundedRectangle, Icons.rounded_corner, 'rounded'),
    (ImageShape.circle, Icons.circle_outlined, 'circle'),
    (ImageShape.oval, Icons.crop_landscape, 'oval'),
    (ImageShape.heart, Icons.favorite_border, 'heart'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16.r,
            offset: Offset(0, -4.h),
          ),
        ],
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
                      padding: EdgeInsets.fromLTRB(12.w, 14.h, 12.w, 2.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _shapes.map(_shapeButton).toList(),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _action(
                      icon: Icons.category_outlined,
                      label: S.t('shape'),
                      active: _showShapes,
                      onTap: () => setState(() => _showShapes = !_showShapes),
                    ),
                    SizedBox(width: 18.w),
                    _action(
                      icon: Icons.border_style,
                      label: S.t('frame'),
                      active: widget.image.framed,
                      onTap: widget.onToggleFrame,
                    ),
                    SizedBox(width: 18.w),
                    _action(
                      icon: Icons.add_photo_alternate_outlined,
                      label: widget.image.isPlaceholder
                          ? S.t('add_photo')
                          : S.t('replace'),
                      active: false,
                      onTap: widget.onReplace,
                    ),
                    SizedBox(width: 18.w),
                    _action(
                      icon: Icons.delete_outline,
                      label: S.t('delete'),
                      active: false,
                      color: Colors.redAccent,
                      onTap: widget.onDelete,
                    ),
                  ],
                ),
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
            width: 54.w,
            height: 54.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : AppColors.cardLight,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(s.$2,
                color: selected ? Colors.white : AppColors.textPrimary,
                size: 26.w),
          ),
          SizedBox(height: 5.h),
          Text(S.t(s.$3),
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 11.sp)),
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
    final tint = color ?? AppColors.textPrimary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.accent
                  : (color != null
                      ? color.withValues(alpha: 0.12)
                      : AppColors.cardLight),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon,
                color: active ? Colors.white : tint, size: 22.w),
          ),
          SizedBox(width: 8.w),
          Text(label,
              style: TextStyle(
                  color: tint, fontSize: 14.sp, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
