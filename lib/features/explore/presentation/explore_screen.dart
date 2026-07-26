import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/utils/page_transitions.dart';
import 'package:status_maker/features/category/presentation/category_screen.dart';
import 'package:status_maker/features/editor/data/templates_data.dart';
import 'package:status_maker/features/editor/presentation/status_personalizer_screen.dart';
import 'package:status_maker/features/editor/widgets/bottom_sheets/category_picker_sheet.dart';
import 'package:status_maker/shared/widgets/empty_state.dart';
import 'package:status_maker/core/utils/responsive.dart';

/// Every real category in the app — the corpus search matches against
/// (category name or any of its ready-made quotes).
const List<String> _searchableCategories = [
  'Good Morning',
  'Birthday',
  'Festival',
  'Motivation',
  'Love',
  'Business',
  'Devotional',
  'Suprabhat',
  'Good Night',
  'Suvichar',
];

class _SearchHit {
  final StatusTemplate template;
  final String category;
  const _SearchHit(this.template, this.category);
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Matches [query] against every category's name and its ready-made quotes,
  /// so typing either a mood ("sunshine") or a category ("birthday") works.
  List<_SearchHit> _search(String query) {
    final q = query.toLowerCase();
    final hits = <_SearchHit>[];
    for (final cat in _searchableCategories) {
      final categoryMatches =
          S.cat(cat).toLowerCase().contains(q) || cat.toLowerCase().contains(q);
      for (final t in templatesForCategory(cat)) {
        if (categoryMatches || t.text.toLowerCase().contains(q)) {
          hits.add(_SearchHit(t, cat));
        }
      }
    }
    return hits;
  }

  @override
  Widget build(BuildContext context) {
    final hits = _query.isEmpty ? const <_SearchHit>[] : _search(_query);

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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(AppDimensions.paddingMedium),
              child: _buildSearchBar(),
            ),
            Expanded(
              child: _query.isEmpty
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTrendingSearches(context),
                          SizedBox(height: 80.h), // Padding for FAB
                        ],
                      ),
                    )
                  : _buildResults(hits),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _startCreate(context),
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

  /// Create flow: ask for a category first, then open the editor with quotes
  /// matching that category already surfaced.
  Future<void> _startCreate(BuildContext context) async {
    final category = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CategoryPickerSheet(),
    );
    // Dismissed without choosing → do nothing.
    if (category == null || !context.mounted) return;
    Navigator.push(
      context,
      FadeSlidePageRoute(
        page: StatusPersonalizerScreen(
          templateName: 'New Status',
          category: category,
          showQuotesOnStart: true,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
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
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: S.t('search_hint'),
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => _searchController.clear(),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.r),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20.w),
        ),
      ),
    );
  }

  Widget _buildTrendingSearches(BuildContext context) {
    const searches = [
      'Good Morning',
      'Birthday',
      'Festival',
      'Motivation',
      'Love',
    ];

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
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  S.cat(search),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResults(List<_SearchHit> hits) {
    if (hits.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: S.t('no_results_title'),
        message: S.t('no_results_msg'),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(AppDimensions.paddingMedium, 0,
          AppDimensions.paddingMedium, AppDimensions.paddingLarge),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
      ),
      itemCount: hits.length,
      itemBuilder: (context, i) {
        final hit = hits[i];
        return RepaintBoundary(
          child: TemplateCard(template: hit.template, category: hit.category),
        );
      },
    );
  }
}
