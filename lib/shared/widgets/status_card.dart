import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/utils/responsive.dart';

class StatusCard extends StatefulWidget {
  final String title;
  final String tag;
  final String likes;
  final String shares;
  final String imageUrl;
  final bool isHighlight;
  final VoidCallback? onCustomize;
  final VoidCallback? onOneTap;

  const StatusCard({
    super.key,
    required this.title,
    required this.tag,
    required this.likes,
    required this.shares,
    required this.imageUrl,
    this.isHighlight = false,
    this.onCustomize,
    this.onOneTap,
  });

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard> {
  bool _isPressed = false;

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) {
        void act(String message) {
          Navigator.pop(sheetContext);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 8.h),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: Text(S.t('add_favorites')),
                onTap: () => act(S.t('added_favorites')),
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: Text(S.t('share')),
                onTap: () => act(S.t('sharing')),
              ),
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined),
                title: Text(S.t('not_interested')),
                onTap: () => act(S.t('fewer_like_this')),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15.r,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image part with text overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
                    child: Image.network(
                      widget.imageUrl,
                      height: 320.h,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(height: 320.h, color: AppColors.cardLight),
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.0),
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Tag
                  Positioned(
                    top: AppDimensions.paddingMedium,
                    left: AppDimensions.paddingMedium,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: widget.isHighlight ? AppColors.accent : Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        widget.tag,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // More options icon
                  Positioned(
                    top: AppDimensions.paddingMedium,
                    right: AppDimensions.paddingSmall,
                    child: IconButton(
                      icon: const Icon(Icons.more_horiz, color: Colors.white),
                      onPressed: () => _showOptions(context),
                    ),
                  ),
                  // Quote Text
                  Positioned(
                    bottom: AppDimensions.paddingMedium,
                    left: AppDimensions.paddingMedium,
                    right: AppDimensions.paddingMedium,
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 24.sp,
                            height: 1.3,
                          ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              // Action Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium, vertical: 12.h),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Icon(Icons.favorite_border, size: 20.w, color: AppColors.textSecondary),
                        SizedBox(height: 2.h),
                        Text(widget.likes, style: TextStyle(color: AppColors.textSecondary, fontSize: 10.sp, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    SizedBox(width: 16.w),
                    Column(
                      children: [
                        Icon(Icons.share_outlined, size: 20.w, color: AppColors.textSecondary),
                        SizedBox(height: 2.h),
                        Text(widget.shares, style: TextStyle(color: AppColors.textSecondary, fontSize: 10.sp, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const Spacer(),
                    
                    // Buttons
                    if (widget.isHighlight) ...[
                      ElevatedButton(
                        onPressed: widget.onOneTap ?? widget.onCustomize,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                          foregroundColor: AppColors.accent,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
                          minimumSize: Size(0, 40.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                        ),
                        child: Text(S.t('one_tap_create'), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    ElevatedButton.icon(
                      onPressed: widget.onCustomize ?? () {},
                      icon: Icon(Icons.edit, size: 14.w),
                      label: Text(S.t('customize'), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
                        minimumSize: Size(0, 40.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
