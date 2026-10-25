import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/supabase/supabase_service.dart';
import 'package:status_maker/core/utils/app_snackbar.dart';
import 'package:status_maker/shared/widgets/saved_status_card.dart';
import 'package:status_maker/shared/widgets/app_shimmer.dart';
import 'package:status_maker/shared/widgets/confirm_dialog.dart';
import 'package:status_maker/shared/widgets/empty_state.dart';
import 'package:status_maker/features/explore/presentation/explore_screen.dart';
import 'package:status_maker/features/editor/presentation/status_personalizer_screen.dart';
import 'package:status_maker/features/preview/presentation/template_detail_screen.dart';
import 'package:status_maker/features/statuses/data/likes_store.dart';
import 'package:status_maker/features/moderation/moderation_store.dart';
import 'package:status_maker/features/statuses/data/saved_status.dart';
import 'package:status_maker/features/statuses/data/status_repository.dart';
import 'package:status_maker/core/utils/page_transitions.dart';
import 'package:status_maker/core/utils/responsive.dart';

class HomeScreen extends StatefulWidget {
  /// Fires whenever the Home tab is (re)selected so the feed refreshes without
  /// the user pulling down. Supplied by [MainLayout].
  final Listenable? refreshSignal;

  const HomeScreen({super.key, this.refreshSignal});

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

  final ScrollController _scroll = ScrollController();

  String? _selected;
  List<SavedStatus> _statuses = [];
  bool _loading = true;
  bool _failed = false;

  /// A background refresh of the first page is in flight (tab focus, pull to
  /// refresh, back from the editor). The feed stays on screen meanwhile.
  bool _refreshing = false;

  // Pagination: the next page is fetched as the user nears the end.
  bool _hasMore = true;
  bool _loadingMore = false;
  bool _moreFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
    widget.refreshSignal?.addListener(_onFocus);
    ModerationStore.instance.addListener(_onModerationChanged);
    ModerationStore.instance.ensureLoaded();
  }

  /// A post was reported / hidden or a creator blocked — redraw without it.
  void _onModerationChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ModerationStore.instance.removeListener(_onModerationChanged);
    widget.refreshSignal?.removeListener(_onFocus);
    _scroll.dispose();
    super.dispose();
  }

  /// Called when the Home tab regains focus — silently refresh the feed.
  void _onFocus() {
    if (mounted && !_loading) _load(silent: true);
  }

  /// Start the next page about a screen before the end, so it has usually
  /// landed by the time the user gets there.
  void _onScroll() {
    final pos = _scroll.position;
    if (pos.extentAfter < pos.viewportDimension) _loadMore();
  }

  /// Loads the PUBLIC feed (only creations users chose to Post), filtered by
  /// the selected category chip.
  /// Bumped per [_load]; a response is only applied if it's still the latest,
  /// so a slow "Love" reply can't land after a fast "All" one and show Love
  /// posts under the All chip.
  int _loadSeq = 0;

  ///
  /// [silent] keeps the current feed on screen (no shimmer) and merges the
  /// fresh first page into it, so the scroll position and the pages already
  /// loaded survive. With nothing loaded yet it behaves like a normal load.
  Future<void> _load({bool silent = false}) async {
    final seq = ++_loadSeq;
    silent = silent && _statuses.isNotEmpty && !_failed;
    setState(() {
      _loading = !silent;
      _refreshing = silent;
      _failed = false;
      // Any in-flight page belongs to the old feed; its result is dropped.
      _loadingMore = false;
      _moreFailed = false;
    });
    try {
      // Which of these the user has already liked, so the hearts are right on
      // the first frame instead of all starting empty. Requested alongside
      // the feed rather than before it — two round trips in parallel, not in
      // series. Both are bounded by StatusRepository.readTimeout, so an
      // offline phone reaches the Retry state instead of shimmering forever.
      final likes = LikesStore.instance.ensureLoaded();
      final items = await _repo.fetchPublic(category: _selected);
      await likes;
      if (!mounted || seq != _loadSeq) return;
      // Seed the counts from server truth before showing them.
      LikesStore.instance.syncFromRows(items);
      final merged = silent ? _mergeFirstPage(items) : null;
      setState(() {
        if (merged != null) {
          _statuses = merged;
        } else {
          _statuses = items;
          _hasMore = items.length == StatusRepository.feedPageSize;
        }
        _loading = false;
        _refreshing = false;
      });
    } catch (_) {
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        // A failed background refresh leaves the feed the user is reading.
        _failed = !silent;
        _loading = false;
        _refreshing = false;
      });
    }
  }

  /// Puts a freshly fetched first page on top of the posts already loaded:
  /// [fresh] is authoritative down to its oldest post (new posts appear,
  /// deleted ones go, counts update) and everything older is kept as is.
  ///
  /// Returns null when the two don't overlap — more than a page was posted
  /// since — because keeping the old pages would leave a hole between them;
  /// the caller then starts over from [fresh].
  List<SavedStatus>? _mergeFirstPage(List<SavedStatus> fresh) {
    if (fresh.length < StatusRepository.feedPageSize) return null;
    final known = {for (final s in _statuses) s.id};
    if (!fresh.any((s) => known.contains(s.id))) return null;
    final cutoff = fresh.last.createdAt;
    if (cutoff == null) return null;
    final freshIds = {for (final s in fresh) s.id};
    return [
      ...fresh,
      for (final s in _statuses)
        if (!freshIds.contains(s.id) &&
            s.createdAt != null &&
            s.createdAt!.isBefore(cutoff))
          s,
    ];
  }

  /// Appends the next page, keyed off the oldest post already shown.
  Future<void> _loadMore() async {
    if (_loading || _refreshing || _loadingMore || _moreFailed || !_hasMore) {
      return;
    }
    final cursor = _statuses.isEmpty ? null : _statuses.last.createdAt;
    if (cursor == null) return;
    final seq = _loadSeq;
    setState(() => _loadingMore = true);
    try {
      final page = await _repo.fetchPublic(category: _selected, before: cursor);
      if (!mounted || seq != _loadSeq) return;
      LikesStore.instance.syncFromRows(page);
      final known = {for (final s in _statuses) s.id};
      setState(() {
        _statuses = [
          ..._statuses,
          ...page.where((s) => !known.contains(s.id)),
        ];
        _hasMore = page.length == StatusRepository.feedPageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || seq != _loadSeq) return;
      // Stays failed until the user taps Retry in the footer — retrying on
      // every scroll tick would hammer a dead connection.
      setState(() {
        _loadingMore = false;
        _moreFailed = true;
      });
    }
  }

  void _retryMore() {
    setState(() => _moreFailed = false);
    _loadMore();
  }

  void _selectCategory(String? name) {
    setState(() => _selected = name);
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _load();
  }

  /// True when the body is a full-viewport empty/error state rather than a feed.
  bool get _showsEmptyState =>
      !_loading && (_failed || _statuses.isEmpty);

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
        // The indicator is its own progress UI — no shimmer behind it.
        onRefresh: () => _load(silent: true),
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          // Build a screen ahead (the default is 250px, less than a card), so
          // the next thumbnail is already downloading/decoding before it
          // scrolls into view instead of popping in under the user's thumb.
          cacheExtent: MediaQuery.sizeOf(context).height,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppDimensions.paddingSmall),
                  _buildCategories(),
                  SizedBox(height: AppDimensions.paddingMedium),
                ],
              ),
            ),
            _buildSliverBody(context),
            if (!_showsEmptyState && !_loading) _buildFooter(),
            // Bottom breathing room for the feed only. With an empty state
            // showing, the body already fills the remaining viewport, and extra
            // extent below it would make the screen scroll and shift the
            // centred state off-centre.
            if (!_showsEmptyState)
              SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.paddingLarge),
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
      // No tap feedback of any kind on these chips:
      //  • GestureDetector, not InkWell, so there's no ink splash.
      //  • no scale animation — an easeOutBack overshoot pops the chip outward
      //    and back, which reads as a ripple.
      //  • a plain Container, not AnimatedContainer. Animating this decoration
      //    meant lerping a solid colour into a gradient: mid-transition Flutter
      //    composites a half-faded surface colour under a half-faded peach
      //    gradient, which is lighter than either end state and flashes. The
      //    selected colour now just switches.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
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
    );
  }

  Widget _buildSliverBody(BuildContext context) {
    // Loading — show a few shimmer cards so the screen has shape immediately.
    if (_loading) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
        sliver: SliverList.separated(
          itemCount: 3,
          separatorBuilder: (_, __) =>
              SizedBox(height: AppDimensions.paddingLarge),
          itemBuilder: (_, __) => const StatusCardShimmer(),
        ),
      );
    }

    // SliverFillRemaining gives the state the whole leftover viewport instead of
    // just its own content height, so EmptyState's own Center actually centres
    // it on screen rather than parking it right under the category chips.
    if (_failed) {
      // Name the real problem when we know it: a server that can't be
      // reached (no connectivity, or the backend project is down) reads very
      // differently from a query that errored.
      final unreachable =
          StatusRepository.lastFailure == BackendFailure.unreachable ||
              StatusRepository.lastFailure == BackendFailure.timeout;
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.cloud_off_rounded,
          title: unreachable
              ? S.t('server_unreachable_title')
              : S.t('something_wrong'),
          message: unreachable
              ? S.t('server_unreachable_msg')
              : S.t('try_again_msg'),
          actionLabel: S.t('retry'),
          onAction: _load,
        ),
      );
    }

    if (_statuses.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.auto_awesome_outlined,
          title: S.t('feed_empty_title'),
          message: S.t('feed_empty_msg'),
        ),
      );
    }

    final tag = _selected == null ? null : S.cat(_selected!);
    // Paging still runs on the full list (the cursor is its last row); only
    // what's drawn skips posts the user has hidden or blocked.
    final shown = ModerationStore.instance.visible(_statuses);
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
      sliver: SliverList.separated(
        itemCount: shown.length,
        separatorBuilder: (_, __) =>
            SizedBox(height: AppDimensions.paddingLarge),
        itemBuilder: (context, i) {
          final status = shown[i];
          // Only the owner can delete their post from the feed; the card also
          // swaps Customize → Edit and shows a "Your status" badge for these.
          final isOwn = status.userId != null &&
              status.userId == SupabaseService.userId;
          return RepaintBoundary(
            // Keyed by id so a card's own state (share spinner, press scale)
            // stays with its post when a refresh inserts new ones above it.
            key: ValueKey(status.id),
            child: SavedStatusCard(
              status: status,
              tag: tag,
              onOpen: () => _openDetail(context, status),
              onCustomize: () => _openEditor(context, status),
              onDelete: isOwn ? () => _confirmAndDelete(status) : null,
            ),
          );
        },
      ),
    );
  }

  /// Under the last card: a spinner while the next page loads, or Retry if it
  /// failed. Nothing once the feed is exhausted.
  Widget _buildFooter() {
    Widget? child;
    if (_loadingMore) {
      child = SizedBox(
        width: 24.w,
        height: 24.w,
        child: const CircularProgressIndicator(
            strokeWidth: 2.5, color: AppColors.accent),
      );
    } else if (_moreFailed) {
      child = TextButton.icon(
        onPressed: _retryMore,
        icon: const Icon(Icons.refresh, color: AppColors.accent),
        label: Text(
          S.t('retry'),
          style: const TextStyle(color: AppColors.accent),
        ),
      );
    }
    if (child == null) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(top: AppDimensions.paddingLarge),
        child: Center(child: child),
      ),
    );
  }

  /// Tapping a card shows the status as it is, rather than dropping straight
  /// into the editor. Same destination a notification tap opens (see
  /// PushService._openFromData), so both routes feel like the same place.
  void _openDetail(BuildContext context, SavedStatus status) {
    Navigator.push(
      context,
      FadeSlidePageRoute(page: TemplateDetailScreen(status: status)),
    );
  }

  /// Same confirm → optimistic-remove → restore-on-failure flow as the
  /// "My Creations" tab (see FavoritesScreen), applied to the public feed.
  Future<void> _confirmAndDelete(SavedStatus status) async {
    final confirmed = await showConfirmDialog(
      context,
      title: S.t('delete_status_title'),
      message: S.t('delete_status_msg'),
    );
    if (confirmed != true) return;

    final previous = List<SavedStatus>.from(_statuses);
    setState(() => _statuses.removeWhere((s) => s.id == status.id));
    try {
      await _repo.delete(status.id);
      if (mounted) AppSnackBar.success(context, S.t('deleted_ok'));
    } catch (_) {
      if (!mounted) return;
      setState(() => _statuses = previous); // restore on failure
      AppSnackBar.error(context, S.t('something_wrong'));
    }
  }

  void _openEditor(BuildContext context, SavedStatus status) {
    // Editing your own post updates it in place; opening someone else's
    // creates a new status linked back to the original as a remix.
    final isOwn =
        status.userId != null && status.userId == SupabaseService.userId;
    Navigator.push(
      context,
      FadeSlidePageRoute(
        page: StatusPersonalizerScreen(
          templateName: status.title ?? 'Status',
          category: status.category ?? '',
          initialDesign: status.toDesign(),
          existingId: isOwn ? status.id : null,
          remixOf: isOwn ? null : status.id,
        ),
      ),
    ).then((_) {
      // Reflect in-place edits in the feed without losing the user's place.
      if (mounted && !_loading) _load(silent: true);
    });
  }
}
