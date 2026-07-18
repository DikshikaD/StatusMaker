import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/shared/widgets/status_card.dart';
import 'package:status_maker/features/category/presentation/category_screen.dart';
import 'package:status_maker/features/preview/presentation/status_preview_screen.dart';
import 'package:status_maker/features/explore/presentation/explore_screen.dart';
import 'package:status_maker/features/editor/presentation/status_personalizer_screen.dart';
import 'package:status_maker/core/utils/page_transitions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            const Text('Status Artist'),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                FadeSlidePageRoute(page: const ExploreScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You\'re all caught up!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDimensions.paddingSmall),
            _buildCategories(),
            const SizedBox(height: AppDimensions.paddingLarge),
            _buildFeed(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'icon': Icons.wb_sunny_outlined, 'name': 'Good Morning', 'active': true},
      {'icon': Icons.cake_outlined, 'name': 'Birthday', 'active': false},
      {'icon': Icons.celebration_outlined, 'name': 'Festival', 'active': false},
      {'icon': Icons.bolt_outlined, 'name': 'Motivation', 'active': false},
      {'icon': Icons.favorite_border, 'name': 'Love', 'active': false},
    ];

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isActive = category['active'] as bool;
          return Padding(
            padding: const EdgeInsets.only(right: AppDimensions.paddingMedium),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  FadeSlidePageRoute(page: CategoryScreen(categoryName: category['name'] as String)),
                );
              },
              child: Column(
                children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isActive ? AppColors.accent.withValues(alpha: 0.15) : AppColors.cardLight,
                  child: Icon(
                    category['icon'] as IconData,
                    color: isActive ? AppColors.accent : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingSmall),
                Text(
                  category['name'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeed(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
      child: Column(
        children: [
          StatusCard(
            title: "The sun is a daily reminder that we too can rise again from the darkness.",
            tag: "Daily Highlight",
            likes: "2.4k",
            shares: "840",
            imageUrl: "https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?q=80&w=2070&auto=format&fit=crop",
            isHighlight: true,
            onCustomize: () {
              Navigator.push(
                context,
                FadeSlidePageRoute(page: const StatusPreviewScreen(imageUrl: "https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?q=80&w=2070&auto=format&fit=crop")),
              );
            },
            onOneTap: () {
              Navigator.push(
                context,
                FadeSlidePageRoute(
                  page: const StatusPersonalizerScreen(
                    templateName: 'Daily Highlight',
                    category: 'Good Morning',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          StatusCard(
            title: "Small steps lead to big results.",
            tag: "Motivation • Trending now",
            likes: "1.2k",
            shares: "340",
            imageUrl: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=2073&auto=format&fit=crop",
            onCustomize: () {
              Navigator.push(
                context,
                FadeSlidePageRoute(page: const StatusPreviewScreen(imageUrl: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=2073&auto=format&fit=crop")),
              );
            },
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
        ],
      ),
    );
  }
}
