import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/features/editor/presentation/status_personalizer_screen.dart';
import 'package:status_maker/core/utils/page_transitions.dart';
import 'package:status_maker/core/utils/responsive.dart';

class StatusPreviewScreen extends StatelessWidget {
  final String imageUrl;
  
  const StatusPreviewScreen({
    super.key,
    this.imageUrl = 'https://images.unsplash.com/photo-1557683316-973673baf926?q=80&w=2000&auto=format&fit=crop',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(S.t('preview_title'), style: TextStyle(fontSize: 16.sp)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(S.t('more_soon')),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
              child: Center(
                child: Hero(
                  tag: imageUrl,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20.r,
                          offset: Offset(0, 10.h),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                      child: Stack(
                        children: [
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            height: MediaQuery.of(context).size.height * 0.65,
                            width: double.infinity,
                            // Full-bleed hero: decode at ~phone width, not the
                            // 2000px source, and fade in with a placeholder.
                            cacheWidth: 1080,
                            frameBuilder: (context, child, frame, wasSync) {
                              if (wasSync) return child;
                              return AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 300),
                                child: child,
                              );
                            },
                            loadingBuilder: (context, child, progress) =>
                                progress == null
                                    ? child
                                    : Container(color: AppColors.cardLight),
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.cardLight,
                              alignment: Alignment.center,
                              child: Icon(Icons.broken_image,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          // Overlay Elements based on Figma "Status Preview"
                          Positioned(
                            top: 30.h,
                            left: 20.w,
                            child: Row(
                              children: [
                                Icon(Icons.spa, color: Colors.white, size: 24.w),
                                SizedBox(width: 8.w),
                                Text(
                                  'RK',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 120,
                            left: 0,
                            right: 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Crafting your',
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    color: Colors.white,
                                    fontSize: 28.sp,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 4.r,
                                        offset: Offset(0, 2.h),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'daily moment',
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    color: AppColors.accent,
                                    fontSize: 28.sp,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 4.r,
                                        offset: Offset(0, 2.h),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Heart Icon on Image
                          Positioned(
                            bottom: 20.h,
                            right: 20.w,
                            child: CircleAvatar(
                              radius: 20.r,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              child: Icon(Icons.favorite, color: Colors.white, size: 20.w),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: AppDimensions.paddingMedium),
          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionIcon(context, Icons.download_outlined, S.t('save'), S.t('saved_device')),
                _buildActionIcon(context, Icons.ios_share, S.t('share'), S.t('sharing')),
                _buildActionIcon(context, Icons.photo_library_outlined, S.t('drafts'), S.t('opening_drafts')),
              ],
            ),
            SizedBox(height: AppDimensions.paddingLarge),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    FadeSlidePageRoute(page: const StatusPersonalizerScreen()),
                  );
                },
                icon: Icon(Icons.edit, size: 20.w),
                label: Text(
                  S.t('customize'),
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon(
      BuildContext context, IconData icon, String label, String message) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
        );
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 28.r,
            backgroundColor: AppColors.cardLight,
            child: Icon(icon, color: AppColors.textPrimary, size: 24.w),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
