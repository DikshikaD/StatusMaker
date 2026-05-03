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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(right: context.wp(2)), // ~16px
        width: context.wp(50), // ~115px
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.wp(6)), // More rounded corners
          color: AppColors.surfaceWhite,
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
            colorFilter: isSelected
                ? null
                : ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.5), 
                    BlendMode.darken,
                  ),
          ),
          border: isSelected
              ? Border.all(color: AppColors.primaryGradientStart, width: context.wp(0.2))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: context.wp(10),
              offset: Offset(0, context.hp(0.5)),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.wp(6)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.8),
              ],
              stops: const [0.4, 1.0], 
            ),
          ),
          alignment: Alignment.bottomCenter,
          padding: EdgeInsets.symmetric(horizontal: context.wp(2.5), vertical: context.hp(1.5)),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2, 
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: context.sp(14),
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
