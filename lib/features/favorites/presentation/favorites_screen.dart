import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/shared/widgets/empty_state.dart';
import 'package:status_maker/shared/widgets/app_shimmer.dart';
import 'package:status_maker/core/utils/app_snackbar.dart';
import 'package:status_maker/shared/widgets/saved_status_card.dart';
import 'package:status_maker/shared/widgets/confirm_dialog.dart';
import 'package:status_maker/features/editor/presentation/status_personalizer_screen.dart';
import 'package:status_maker/features/statuses/data/saved_status.dart';
import 'package:status_maker/features/statuses/data/status_repository.dart';
import 'package:status_maker/core/utils/page_transitions.dart';
import 'package:status_maker/core/utils/responsive.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(S.t('favorites_title')),
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          bottom: TabBar(
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
          children: [
            EmptyState(
              icon: Icons.bookmark_border,
              title: S.t('fav_empty_title'),
              message: S.t('fav_empty_msg'),
            ),
            const _MyCreationsTab(),
          ],
        ),
      ),
    );
  }
}

/// The user's own creations (everything they Saved, public or private), newest
/// first. Tapping Customize reopens the editable design; the trash icon deletes.
class _MyCreationsTab extends StatefulWidget {
  const _MyCreationsTab();

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
    _load();
  }

  Future<void> _load() async {
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

  void _openEditor(SavedStatus status) {
    Navigator.push(
      context,
      FadeSlidePageRoute(
        page: StatusPersonalizerScreen(
          templateName: status.title ?? 'Status',
          category: status.category ?? '',
          initialDesign: status.toDesign(),
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
              onCustomize: () => _openEditor(status),
              onDelete: () => _confirmAndDelete(status),
            ),
          );
        },
      ),
    );
  }
}
