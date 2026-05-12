import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/responsive_utils.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(right: context.wp(4.5)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // The Story Bubble
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.all(isSelected ? context.wp(1.2) : context.wp(0.5)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected 
                    ? AppColors.primaryGradient 
                    : LinearGradient(
                        colors: [Colors.grey.shade300, Colors.grey.shade300],
                      ),
              ),
              child: Container(
                padding: EdgeInsets.all(context.wp(0.8)), // Inner white spacing
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: Image.asset(
                    imageUrl,
                    width: context.wp(15),
                    height: context.wp(15),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(height: context.hp(1)),
            // The Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: context.sp(13.5),
                letterSpacing: 0.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
