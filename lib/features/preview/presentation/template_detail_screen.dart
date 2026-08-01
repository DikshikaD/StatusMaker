import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/utils/app_snackbar.dart';
import 'package:status_maker/core/utils/page_transitions.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/features/editor/presentation/status_personalizer_screen.dart';
import 'package:status_maker/features/statuses/data/likes_store.dart';
import 'package:status_maker/features/statuses/data/saved_status.dart';
import 'package:status_maker/shared/utils/share_image.dart';
import 'package:status_maker/shared/widgets/share_target_dialog.dart';

/// Detail view for one specific template — what a notification tap (e.g.
/// "someone liked your status") opens. Same like/share/customize actions as
/// [SavedStatusCard] in the feeds, just laid out full-screen for a single
/// status instead of a grid.
class TemplateDetailScreen extends StatefulWidget {
  final SavedStatus status;

  const TemplateDetailScreen({super.key, required this.status});

  @override
  State<TemplateDetailScreen> createState() => _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends State<TemplateDetailScreen> {
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    // Ensures `isLiked` reflects the real server state even when this screen
    // is the first thing to open this session (e.g. straight from a
    // notification tap, before any feed has loaded likes).
    LikesStore.instance.ensureLoaded();
  }

  Future<void> _toggleLike() async {
    try {
      await LikesStore.instance.toggle(widget.status);
    } catch (_) {
      if (mounted) AppSnackBar.error(context, S.t('something_wrong'));
    }
  }

  Future<void> _share() async {
    final url = widget.status.thumbUrl;
    if (url == null || url.isEmpty || _sharing) return;
    final target = await showShareTargetDialog(context);
    if (target == null || !mounted) return;

    setState(() => _sharing = true);
    final ok = await shareRemoteImage(
      url: url,
      target: target,
      text: widget.status.title,
    );
    if (!mounted) return;
    setState(() => _sharing = false);
    if (!ok) AppSnackBar.error(context, S.t('something_wrong'));
  }

  void _openEditor() {
    final status = widget.status;
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

  @override
  Widget build(BuildContext context) {
    final s = widget.status;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(s.title ?? S.t('preview_title'),
            style: TextStyle(fontSize: 16.sp)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  child: (s.thumbUrl == null || s.thumbUrl!.isEmpty)
                      ? Container(
                          color: AppColors.cardLight,
                          height: MediaQuery.of(context).size.height * 0.65,
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: Icon(Icons.image_outlined,
                              color: AppColors.textSecondary, size: 40.w),
                        )
                      : Image.network(
                          s.thumbUrl!,
                          fit: BoxFit.cover,
                          height: MediaQuery.of(context).size.height * 0.65,
                          width: double.infinity,
                          cacheWidth: 1080,
                          frameBuilder: (context, child, frame, wasSync) {
                            if (wasSync) return child;
                            return AnimatedOpacity(
                              opacity: frame == null ? 0 : 1,
                              duration: const Duration(milliseconds: 300),
                              child: child,
                            );
                          },
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                                  ? child
                                  : Container(color: AppColors.cardLight),
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.cardLight,
                            alignment: Alignment.center,
                            child: Icon(Icons.broken_image,
                                color: AppColors.textSecondary),
                          ),
                        ),
                ),
              ),
            ),
          ),
          SizedBox(height: AppDimensions.paddingMedium),
          _buildBottomActions(s),
        ],
      ),
    );
  }

  Widget _buildBottomActions(SavedStatus s) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ListenableBuilder(
                  listenable: LikesStore.instance,
                  builder: (context, _) {
                    final liked = LikesStore.instance.isLiked(s.id);
                    return _actionIcon(
                      icon: liked ? Icons.favorite : Icons.favorite_border,
                      color: liked ? AppColors.accent : AppColors.textPrimary,
                      label: '${LikesStore.instance.countFor(s)}',
                      onTap: _toggleLike,
                    );
                  },
                ),
                if (s.remixCount > 0)
                  _actionIcon(
                    icon: Icons.repeat,
                    color: AppColors.textPrimary,
                    label: '${s.remixCount}',
                    onTap: _openEditor,
                  ),
                _actionIcon(
                  icon: Icons.ios_share,
                  color: AppColors.textPrimary,
                  label: S.t('share'),
                  busy: _sharing,
                  onTap: _share,
                ),
              ],
            ),
            SizedBox(height: AppDimensions.paddingLarge),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton.icon(
                onPressed: _openEditor,
                icon: Icon(Icons.edit, size: 20.w),
                label: Text(
                  S.t('customize'),
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required String label,
    bool busy = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28.r,
            backgroundColor: AppColors.cardLight,
            child: busy
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  )
                : Icon(icon, color: color, size: 24.w),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
