import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/shared/widgets/status_card.dart';
import 'package:status_maker/features/explore/presentation/explore_screen.dart';
import 'package:status_maker/features/editor/presentation/status_personalizer_screen.dart';
import 'package:status_maker/features/editor/data/templates_data.dart';
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

  // Pseudo like counts so cards feel alive (display only).
  static const _likeLabels = ['2.4k', '1.2k', '980', '3.1k', '760', '1.8k',
    '540', '2.0k'];

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
            // Smoothly cross-fade + slide the header and feed when the
            // selected category changes.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0.02),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.topCenter,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              ),
              child: Column(
                key: ValueKey(_selected ?? '_all'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(),
                  SizedBox(height: AppDimensions.paddingMedium),
                  _buildFeed(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 46.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding:
            EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
        // +1 for the leading "All" chip.
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          // Builder gives each chip its own context so the row can slide it
          // into view when tapped.
          return Builder(
            builder: (chipContext) {
              if (index == 0) {
                return _categoryChip(
                  icon: Icons.apps_rounded,
                  label: S.t('all'),
                  isActive: _selected == null,
                  onTap: () {
                    setState(() => _selected = null);
                    _centerChip(chipContext);
                  },
                );
              }
              final category = _categories[index - 1];
              final name = category['name'] as String;
              return _categoryChip(
                icon: category['icon'] as IconData,
                label: S.cat(name),
                isActive: name == _selected,
                onTap: () {
                  setState(() =>
                      _selected = _selected == name ? null : name);
                  _centerChip(chipContext);
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Smoothly slides the tapped chip toward the centre of the row.
  void _centerChip(BuildContext chipContext) {
    Scrollable.ensureVisible(
      chipContext,
      alignment: 0.5,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _categoryChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: 10.w),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedScale(
          scale: isActive ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(colors: AppColors.accentGradient)
                : null,
            color: isActive ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isActive ? Colors.transparent : AppColors.border,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 12.r,
                      offset: Offset(0, 4.h),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18.w,
                color: isActive ? Colors.white : AppColors.accent,
              ),
              SizedBox(width: 7.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    final title =
        _selected == null ? S.t('popular_templates') : S.cat(_selected!);
    final count = templatesForCategory(_selected).length;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4.w,
            height: 20.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.accentGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            '$count ${S.t('designs')}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeed(BuildContext context) {
    final templates = templatesForCategory(_selected);
    final tag = _selected == null ? null : S.cat(_selected!);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
      child: Column(
        children: [
          for (var i = 0; i < templates.length; i++) ...[
            // Each card paints a gradient + CustomPaint motif + styled text.
            // Isolating it in its own layer means scrolling or one card's
            // press/like animation never repaints the others.
            RepaintBoundary(
              child: StatusCard(
                template: templates[i],
                tag: tag,
                likes: _likeLabels[i % _likeLabels.length],
                onCustomize: () => _openEditor(context, templates[i]),
              ),
            ),
            SizedBox(height: AppDimensions.paddingLarge),
          ],
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, StatusTemplate template) {
    Navigator.push(
      context,
      FadeSlidePageRoute(
        page: StatusPersonalizerScreen(
          templateName: 'Template',
          category: _selected ?? '',
          template: template,
        ),
      ),
    );
  }
}
