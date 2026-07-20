import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/shared/widgets/status_card.dart';
import 'package:status_maker/shared/widgets/empty_state.dart';
import 'package:status_maker/features/preview/presentation/status_preview_screen.dart';
import 'package:status_maker/features/explore/presentation/explore_screen.dart';
import 'package:status_maker/features/editor/presentation/status_personalizer_screen.dart';
import 'package:status_maker/core/utils/page_transitions.dart';
import 'package:status_maker/core/utils/responsive.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _categories = [
    {'icon': Icons.wb_sunny_outlined, 'name': 'Good Morning'},
    {'icon': Icons.cake_outlined, 'name': 'Birthday'},
    {'icon': Icons.celebration_outlined, 'name': 'Festival'},
    {'icon': Icons.bolt_outlined, 'name': 'Motivation'},
    {'icon': Icons.favorite_border, 'name': 'Love'},
  ];

  String? _selected;

  IconData get _selectedIcon => _categories.firstWhere(
        (c) => c['name'] == _selected,
        orElse: () => _categories.first,
      )['icon'] as IconData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: AppColors.accent, size: 20.w),
            SizedBox(width: 8.w),
            Text(S.t('app_name')),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              FadeSlidePageRoute(page: const ExploreScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(S.t('youre_caught_up')),
                  duration: const Duration(seconds: 2),
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
            SizedBox(height: AppDimensions.paddingSmall),
            _buildCategories(),
            SizedBox(height: AppDimensions.paddingLarge),
            if (_selected == null)
              _buildFeed(context)
            else
              SizedBox(
                height: 440.h,
                child: EmptyState(
                  icon: _selectedIcon,
                  title: S.isHi
                      ? '${S.cat(_selected!)} के लिए अभी कोई स्टेटस नहीं'
                      : 'No $_selected statuses yet',
                  message: S.isHi
                      ? 'नए ${S.cat(_selected!)} डिज़ाइन जल्द आ रहे हैं। तब तक, अपना बनाने के लिए “${S.t('nav_create')}” पर टैप करें!'
                      : 'Fresh $_selected designs are on the way. Meanwhile, tap Create to make your own!',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 90.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding:
            EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final name = category['name'] as String;
          final isActive = name == _selected;
          return Padding(
            padding: EdgeInsets.only(right: AppDimensions.paddingMedium),
            child: GestureDetector(
              onTap: () => setState(() => _selected = isActive ? null : name),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28.r,
                    backgroundColor: isActive
                        ? AppColors.accent
                        : AppColors.cardLight,
                    child: Icon(
                      category['icon'] as IconData,
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      size: 24.w,
                    ),
                  ),
                  SizedBox(height: AppDimensions.paddingSmall),
                  Text(
                    S.cat(name),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? AppColors.accent : AppColors.textSecondary,
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
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
      child: Column(
        children: [
          StatusCard(
            title:
                "The sun is a daily reminder that we too can rise again from the darkness.",
            tag: "Daily Highlight",
            likes: "2.4k",
            shares: "840",
            imageUrl:
                "https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?q=80&w=2070&auto=format&fit=crop",
            isHighlight: true,
            onCustomize: () {
              Navigator.push(
                context,
                FadeSlidePageRoute(
                    page: const StatusPreviewScreen(
                        imageUrl:
                            "https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?q=80&w=2070&auto=format&fit=crop")),
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
          SizedBox(height: AppDimensions.paddingLarge),
          StatusCard(
            title: "Small steps lead to big results.",
            tag: "Motivation • Trending now",
            likes: "1.2k",
            shares: "340",
            imageUrl:
                "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=2073&auto=format&fit=crop",
            onCustomize: () {
              Navigator.push(
                context,
                FadeSlidePageRoute(
                    page: const StatusPreviewScreen(
                        imageUrl:
                            "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=2073&auto=format&fit=crop")),
              );
            },
          ),
          SizedBox(height: AppDimensions.paddingLarge),
        ],
      ),
    );
  }
}
