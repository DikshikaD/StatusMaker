import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/responsive_utils.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(context.wp(15), 0, context.wp(15), context.hp(3)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.wp(4), vertical: context.hp(1.2)),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(context.wp(8)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGradientStart.withOpacity(0.4),
              blurRadius: context.wp(4),
              offset: Offset(0, context.hp(1)),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavItem(
              icon: CupertinoIcons.home,
              isSelected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: CupertinoIcons.plus_app,
              isSelected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _NavItem(
              icon: CupertinoIcons.wand_rays,
              isSelected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavItem(
              icon: CupertinoIcons.person,
              isSelected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.wp(3), vertical: context.hp(1)),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
          size: isSelected ? context.sp(24) : context.sp(22),
        ),
      ),
    );
  }
}
