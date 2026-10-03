import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/shared/widgets/empty_state.dart';
import 'package:status_maker/shared/widgets/app_shimmer.dart';
import 'package:status_maker/core/supabase/supabase_service.dart';
import 'package:status_maker/core/utils/app_snackbar.dart';
import 'package:status_maker/shared/widgets/saved_status_card.dart';
import 'package:status_maker/shared/widgets/confirm_dialog.dart';
import 'package:status_maker/features/editor/presentation/status_personalizer_screen.dart';
import 'package:status_maker/features/statuses/data/likes_store.dart';
import 'package:status_maker/features/statuses/data/saved_status.dart';
import 'package:status_maker/features/statuses/data/status_repository.dart';
import 'package:status_maker/core/utils/page_transitions.dart';
import 'package:status_maker/features/preview/presentation/template_detail_screen.dart';
import 'package:status_maker/core/utils/responsive.dart';

class FavoritesScreen extends StatefulWidget {
  /// Bumped by [MainLayout] when this tab should open on "My Creations" and
  /// reload it — e.g. straight after the user saves a status.
  final ValueNotifier<int>? showCreationsSignal;

  const FavoritesScreen({super.key, this.showCreationsSignal});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  static const int _creationsTabIndex = 1;

  late final TabController _tabs = TabController(length: 2, vsync: this);

  /// Forwarded to the creations list so it refetches when a new status lands.
  final ValueNotifier<int> _reload = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    widget.showCreationsSignal?.addListener(_onShowCreations);
  }

  @override
  void dispose() {
    widget.showCreationsSignal?.removeListener(_onShowCreations);
    _reload.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _onShowCreations() {
    if (!mounted) return;
    _tabs.animateTo(_creationsTabIndex);
    _reload.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(S.t('favorites_title')),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle:
              TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
          tabs: [
            Tab(text: S.t('saved_templates')),
            Tab(text: S.t('my_creations')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          const _LikedTab(),
          _MyCreationsTab(reloadSignal: _reload),
        ],
      ),
    );
  }
}

/// Statuses the user has liked ("Saved Templates").
///
/// This tab used to be a hardcoded empty state — liking something had nowhere to
/// show up. It now reads the `likes` join table, and refetches whenever
/// [LikesStore] changes so unliking from anywhere removes the card here too.
class _LikedTab extends StatefulWidget {
  const _LikedTab();

  @override
  State<_LikedTab> createState() => _LikedTabState();
}

class _LikedTabState extends State<_LikedTab>
    with AutomaticKeepAliveClientMixin {
  final StatusRepository _repo = StatusRepository();

  List<SavedStatus> _statuses = [];
  bool _loading = true;
  bool _failed = false;

  /// The set of liked ids the current list was built from, so a like made
  /// elsewhere triggers a refetch but a mere count change doesn't.
  Set<String> _shownIds = <String>{};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    LikesStore.instance.addListener(_onLikesChanged);
    _load();
  }

  @override
  void dispose() {
    LikesStore.instance.removeListener(_onLikesChanged);
    super.dispose();
  }

  void _onLikesChanged() {
    if (!mounted || _loading) return;
    // Only refetch when the *membership* changed — LikesStore also notifies for
    // count updates, which don't change what belongs in this list.
    final liked = _statuses.map((s) => s.id).toSet();
    final stillCorrect = liked.every(LikesStore.instance.isLiked) &&
        _shownIds.every(LikesStore.instance.isLiked);
    if (stillCorrect) return;
    _load();
  }

  Future<void> _load() async {
    // Reached from `.then(...)` after the editor route pops — the tab may
    // already be disposed by then.
    if (!mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      await LikesStore.instance.ensureLoaded();
      final items = await _repo.fetchLiked();
      if (!mounted) return;
      LikesStore.instance.syncFromRows(items);
      setState(() {
        _statuses = items;
        _shownIds = items.map((s) => s.id).toSet();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  /// Tapping a card shows the status as-is. Reloads on return because the
  /// detail view can unlike it, which removes it from this tab.
  void _openDetail(SavedStatus status) {
    Navigator.push(
      context,
      FadeSlidePageRoute(page: TemplateDetailScreen(status: status)),
    ).then((_) => _load());
  }

  void _openEditor(SavedStatus status) {
    // A liked status can be the user's own — editing it must update the row,
    // while someone else's opens as a remix.
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
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppDimensions.paddingMedium),
        itemCount: 3,
        separatorBuilder: (_, __) =>
            SizedBox(height: AppDimensions.paddingLarge),
        itemBuilder: (_, __) => const StatusCardShimmer(),
      );
    }
    if (_failed) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        title: S.t('something_wrong'),
        message: S.t('try_again_msg'),
        actionLabel: S.t('retry'),
        onAction: _load,
      );
    }
    if (_statuses.isEmpty) {
      return EmptyState(
        icon: Icons.bookmark_border,
        title: S.t('fav_empty_title'),
        message: S.t('fav_empty_msg'),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: EdgeInsets.all(AppDimensions.paddingMedium),
        itemCount: _statuses.length,
        separatorBuilder: (_, __) =>
            SizedBox(height: AppDimensions.paddingLarge),
        itemBuilder: (context, i) {
          final status = _statuses[i];
          return RepaintBoundary(
            child: SavedStatusCard(
              status: status,
              tag: status.category == null ? null : S.cat(status.category!),
              onOpen: () => _openDetail(status),
              onCustomize: () => _openEditor(status),
            ),
          );
        },
      ),
    );
  }
}

/// The user's own creations (everything they Saved, public or private), newest
/// first. Tapping Customize reopens the editable design; the trash icon deletes.
class _MyCreationsTab extends StatefulWidget {
  /// Bumped when a newly saved status should appear — this tab is kept alive,
  /// so without an explicit signal it would keep showing its stale list.
  final ValueNotifier<int> reloadSignal;

  const _MyCreationsTab({required this.reloadSignal});

  @override
  State<_MyCreationsTab> createState() => _MyCreationsTabState();
}

class _MyCreationsTabState extends State<_MyCreationsTab>
    with AutomaticKeepAliveClientMixin {
  final StatusRepository _repo = StatusRepository();

  List<SavedStatus> _statuses = [];
  bool _loading = true;
  bool _failed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.reloadSignal.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.reloadSignal.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    // Reached from `.then(...)` after the editor route pops — the tab may
    // already be disposed by then.
    if (!mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final items = await _repo.fetchMine();
      if (!mounted) return;
      setState(() {
        _statuses = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  Future<void> _confirmAndDelete(SavedStatus status) async {
    final confirmed = await showConfirmDialog(
      context,
      title: S.t('delete_status_title'),
      message: S.t('delete_status_msg'),
    );
    if (confirmed == true) _delete(status);
  }

  Future<void> _delete(SavedStatus status) async {
    // Optimistically remove, then call the backend.
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

  /// Tapping a card shows the status as-is, same as a notification tap.
  void _openDetail(SavedStatus status) {
    Navigator.push(
      context,
      FadeSlidePageRoute(page: TemplateDetailScreen(status: status)),
    ).then((_) => _load());
  }

  void _openEditor(SavedStatus status) {
    Navigator.push(
      context,
      FadeSlidePageRoute(
        page: StatusPersonalizerScreen(
          templateName: status.title ?? 'Status',
          category: status.category ?? '',
          initialDesign: status.toDesign(),
          // Everything in My Creations is the user's own — saves from this
          // editor must update the row, not duplicate it.
          existingId: status.id,
        ),
      ),
    ).then((_) => _load()); // refresh in case they saved changes
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppDimensions.paddingMedium),
        itemCount: 3,
        separatorBuilder: (_, __) =>
            SizedBox(height: AppDimensions.paddingLarge),
        itemBuilder: (_, __) => const StatusCardShimmer(),
      );
    }
    if (_failed) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        title: S.t('something_wrong'),
        message: S.t('try_again_msg'),
        actionLabel: S.t('retry'),
        onAction: _load,
      );
    }
    if (_statuses.isEmpty) {
      return EmptyState(
        icon: Icons.brush_outlined,
        title: S.t('creations_empty_title'),
        message: S.t('creations_empty_msg'),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: EdgeInsets.all(AppDimensions.paddingMedium),
        itemCount: _statuses.length,
        separatorBuilder: (_, __) =>
            SizedBox(height: AppDimensions.paddingLarge),
        itemBuilder: (context, i) {
          final status = _statuses[i];
          return RepaintBoundary(
            child: SavedStatusCard(
              status: status,
              tag: status.isPublic ? S.t('tag_public') : S.t('tag_private'),
              onOpen: () => _openDetail(status),
              onCustomize: () => _openEditor(status),
              onDelete: () => _confirmAndDelete(status),
            ),
          );
        },
      ),
    );
  }
}
