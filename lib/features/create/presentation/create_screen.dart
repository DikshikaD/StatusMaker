import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/utils/page_transitions.dart';
import 'package:status_maker/features/category/presentation/category_screen.dart';
import 'package:status_maker/features/editor/presentation/status_personalizer_screen.dart';
import 'package:status_maker/core/utils/responsive.dart';

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(S.t('create_title')),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAIBlock(context),
            SizedBox(height: AppDimensions.paddingXLarge),

            Text(
              S.t('themes'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: AppDimensions.paddingMedium),
            _buildThemeGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAIBlock(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, Color(0xFFF3B49E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white),
              SizedBox(width: 8.w),
              Text(
                S.t('start_creating'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            S.t('start_creating_desc'),
            style: TextStyle(color: Colors.white, fontSize: 13.sp),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                FadeSlidePageRoute(
                  page: const StatusPersonalizerScreen(templateName: 'New Status'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.accent,
              elevation: 0,
            ),
            child: Text(S.t('open_editor')),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeGrid(BuildContext context) {
    final themes = [
      // Traditional themes — loved by families & elders (Hindi content).
      {'icon': Icons.self_improvement, 'name': 'Devotional', 'color': Colors.orange.shade50},
      {'icon': Icons.wb_twilight, 'name': 'Suprabhat', 'color': Colors.amber.shade50},
      {'icon': Icons.nightlight_round, 'name': 'Good Night', 'color': Colors.indigo.shade50},
      {'icon': Icons.format_quote, 'name': 'Suvichar', 'color': Colors.teal.shade50},
      {'icon': Icons.cake_outlined, 'name': 'Birthday', 'color': Colors.pink.shade50},
      {'icon': Icons.celebration_outlined, 'name': 'Festival', 'color': Colors.orange.shade50},
      {'icon': Icons.bolt_outlined, 'name': 'Motivation', 'color': Colors.yellow.shade50},
      {'icon': Icons.favorite_outline, 'name': 'Love', 'color': Colors.red.shade50},
      {'icon': Icons.wb_sunny_outlined, 'name': 'Morning', 'color': Colors.blue.shade50},
      {'icon': Icons.business_center_outlined, 'name': 'Business', 'color': Colors.grey.shade100},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: themes.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemBuilder: (context, index) {
        final theme = themes[index];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.push(
              context,
              FadeSlidePageRoute(
                page: CategoryScreen(categoryName: theme['name'] as String),
              ),
            );
          },
          child: Column(
            children: [
              Container(
                height: 70.h,
                width: 70.w,
                decoration: BoxDecoration(
                  color: theme['color'] as Color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  theme['icon'] as IconData,
                  color: AppColors.primary,
                  size: 28.w,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                S.cat(theme['name'] as String),
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}
