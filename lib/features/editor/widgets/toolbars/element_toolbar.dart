import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/core/utils/responsive.dart';

/// Contextual toolbar for a selected vector element: recolour or delete.
class ElementToolbar extends StatelessWidget {
  final ElementObject element;
  final ValueChanged<Color> onColor;
  final ValueChanged<double> onStroke;
  final VoidCallback onDelete;

  const ElementToolbar({
    super.key,
    required this.element,
    required this.onColor,
    required this.onStroke,
    required this.onDelete,
  });

  static const List<Color> _palette = [
    Colors.white,
    Colors.black,
    Color(0xFFE38870),
    Color(0xFFFFD54F),
    Color(0xFFEF5350),
    Color(0xFF66BB6A),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFFFF7043),
    Color(0xFF26C6DA),
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stroke width — affects outline shapes (ring, line, arrow).
              Row(
                children: [
                  Icon(Icons.line_weight,
                      color: AppColors.textSecondary, size: 20.w),
                  SizedBox(width: 6.w),
                  Text(S.t('width'),
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12.sp)),
                  Expanded(
                    child: Slider(
                      value: element.strokeWidth.clamp(0.4, 3.0),
                      min: 0.4,
                      max: 3.0,
                      activeColor: AppColors.accent,
                      onChanged: onStroke,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40.h,
                      child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _palette.length,
                    separatorBuilder: (_, __) => SizedBox(width: 10.w),
                    itemBuilder: (_, i) {
                      final c = _palette[i];
                      final selected = c == element.color;
                      return GestureDetector(
                        onTap: () => onColor(c),
                        child: Container(
                          width: 36.w,
                          height: 36.h,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? AppColors.accent
                                  : AppColors.border,
                              width: selected ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDelete,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 22.w),
                    ),
                    SizedBox(height: 4.h),
                    Text(S.t('delete'),
                        style: TextStyle(
                            color: Colors.redAccent, fontSize: 11.sp)),
                  ],
                ),
              ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
