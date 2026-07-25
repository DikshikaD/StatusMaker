import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/shared/widgets/saved_status_card.dart';
import 'package:status_maker/shared/widgets/empty_state.dart';
import 'package:status_maker/features/explore/presentation/explore_screen.dart';
import 'package:status_maker/features/editor/presentation/status_personalizer_screen.dart';
import 'package:status_maker/features/statuses/data/saved_status.dart';
import 'package:status_maker/features/statuses/data/status_repository.dart';
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

  final StatusRepository _repo = StatusRepository();

  String? _selected;
  List<SavedStatus> _statuses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Loads the PUBLIC feed (only creations users chose to Post), filtered by
  /// the selected category chip.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repo.fetchPublic(category: _selected);
      if (!mounted) return;
      setState(() {
        _statuses = items;
        _loading = false;
      });
    } on StatusRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = S.t('feed_error_msg');
        _loading = false;
      });
    }
  }

  void _selectCategory(String? name) {
    setState(() => _selected = name);
    _load();
  }

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
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppDimensions.paddingSmall),
              _buildCategories(),
              SizedBox(height: AppDimensions.paddingLarge),
              _buildSectionHeader(),
              SizedBox(height: AppDimensions.paddingMedium),
              _buildBody(context),
              SizedBox(height: AppDimensions.paddingLarge),
            ],
          ),
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
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          return Builder(
            builder: (chipContext) {
              if (index == 0) {
                return _categoryChip(
                  icon: Icons.apps_rounded,
                  label: S.t('all'),
                  isActive: _selected == null,
                  onTap: () {
                    _selectCategory(null);
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
                  _selectCategory(_selected == name ? null : name);
                  _centerChip(chipContext);
                },
              );
            },
          );
        },
      ),
    );
  }

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
        _selected == null ? S.t('community_feed') : S.cat(_selected!);
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
          if (!_loading && _error == null)
            Text(
              '${_statuses.length} ${S.t('designs')}',
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

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 80.h),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: EmptyState(
          icon: Icons.wifi_off_rounded,
          title: S.t('feed_error_title'),
          message: _error!,
          actionLabel: S.t('retry'),
          onAction: _load,
        ),
      );
    }
    if (_statuses.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: EmptyState(
          icon: Icons.auto_awesome_outlined,
          title: S.t('feed_empty_title'),
          message: S.t('feed_empty_msg'),
        ),
      );
    }

    final tag = _selected == null ? null : S.cat(_selected!);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
      child: Column(
        children: [
          for (final status in _statuses) ...[
            RepaintBoundary(
              child: SavedStatusCard(
                status: status,
                tag: tag,
                onCustomize: () => _openEditor(context, status),
              ),
            ),
            SizedBox(height: AppDimensions.paddingLarge),
          ],
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, SavedStatus status) {
    Navigator.push(
      context,
      FadeSlidePageRoute(
        page: StatusPersonalizerScreen(
          templateName: status.title ?? 'Status',
          category: status.category ?? '',
          initialDesign: status.toDesign(),
          remixOf: status.id,
        ),
      ),
    );
  }
}
