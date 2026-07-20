import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/utils/page_transitions.dart';
import 'package:status_maker/features/category/presentation/category_screen.dart';
import 'package:status_maker/features/preview/presentation/status_preview_screen.dart';
import 'package:status_maker/features/editor/presentation/status_personalizer_screen.dart';
import 'package:status_maker/core/utils/responsive.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('explore_title')),
        centerTitle: false,
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            SizedBox(height: AppDimensions.paddingLarge),
            _buildTrendingSearches(context),
            SizedBox(height: AppDimensions.paddingLarge),
            _buildDiscoverMore(context),
            SizedBox(height: 80.h), // Padding for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            FadeSlidePageRoute(
              page: const StatusPersonalizerScreen(templateName: 'New Status'),
            ),
          );
        },
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.r),
        ),
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: S.t('search_hint'),
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.r),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20.w),
        ),
      ),
    );
  }

  Widget _buildTrendingSearches(BuildContext context) {
    final searches = ['Birthday', 'Anniversary', 'Good Morning', 'Festivals', 'Inspiration'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.t('trending_searches'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: AppDimensions.paddingMedium),
        Wrap(
          spacing: 8.w,
          runSpacing: 12.h,
          children: searches.map((search) {
            final isSelected = search == 'Birthday';
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  FadeSlidePageRoute(page: CategoryScreen(categoryName: search)),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected ? AppColors.accent.withValues(alpha: 0.3) : AppColors.border,
                  ),
                ),
                child: Text(
                  search,
                  style: TextStyle(
                    color: isSelected ? AppColors.accent : AppColors.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDiscoverMore(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              S.t('discover_more'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 16.sp,
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(S.t('filters_soon')),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                S.t('filter'),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
              ),
            ),
          ],
        ),
        SizedBox(height: AppDimensions.paddingMedium),
        // Staggered grid look using Row and Columns
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildDiscoveryCard(context, 'Serene Awakening', 'Morning', 'https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?q=80&w=2070&auto=format&fit=crop', 240.h),
                  SizedBox(height: 12.h),
                  _buildDiscoveryCard(context, 'Birthday Bash', 'Celebration', 'https://images.unsplash.com/photo-1557683316-973673baf926?q=80&w=2000&auto=format&fit=crop', 160.h),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                children: [
                  _buildDiscoveryCard(context, 'Morning Serenity', 'Nature', 'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?q=80&w=2000&auto=format&fit=crop', 160.h),
                  SizedBox(height: 12.h),
                  _buildDiscoveryCard(context, 'Our Anniversary', 'Love', 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?q=80&w=2000&auto=format&fit=crop', 240.h),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiscoveryCard(BuildContext context, String title, String subtitle, String imageUrl, double height) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          FadeSlidePageRoute(page: StatusPreviewScreen(imageUrl: imageUrl)),
        );
      },
      child: Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        color: AppColors.cardLight,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.cardLight,
                child: const Icon(Icons.broken_image, color: AppColors.textSecondary),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
            padding: EdgeInsets.all(12.w),
            alignment: Alignment.bottomLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
