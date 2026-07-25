import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/core/utils/app_snackbar.dart';
import 'package:status_maker/shared/widgets/app_shimmer.dart';
import 'package:status_maker/shared/utils/share_image.dart';
import 'package:status_maker/features/statuses/data/saved_status.dart';

/// A feed card for a *saved* status (a real user creation from Supabase). Shows
/// the rendered thumbnail as the preview, with Customize (reopen the editable
/// design) plus an optional Delete for the owner's own creations.
class SavedStatusCard extends StatefulWidget {
  final SavedStatus status;

  /// Opens the editor pre-loaded with this status's editable design.
  final VoidCallback onCustomize;

  /// When provided, a delete button is shown (used in "My Creations").
  final VoidCallback? onDelete;

  /// Small pill shown over the preview (e.g. the category).
  final String? tag;

  const SavedStatusCard({
    super.key,
    required this.status,
    required this.onCustomize,
    this.onDelete,
    this.tag,
  });

  @override
  State<SavedStatusCard> createState() => _SavedStatusCardState();
}

class _SavedStatusCardState extends State<SavedStatusCard> {
  bool _pressed = false;
  bool _liked = false;
  bool _sharing = false;

  Future<void> _share() async {
    final url = widget.status.thumbUrl;
    if (url == null || url.isEmpty || _sharing) return;
    setState(() => _sharing = true);
    final ok = await shareImageUrl(url, text: widget.status.title);
    if (!mounted) return;
    setState(() => _sharing = false);
    if (!ok) AppSnackBar.error(context, S.t('something_wrong'));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.status;
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18.r,
              offset: Offset(0, 10.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _preview(s),
            _actionBar(s),
          ],
        ),
      ),
    );
  }

  Widget _preview(SavedStatus s) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onCustomize,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusLarge)),
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (s.thumbUrl != null && s.thumbUrl!.isNotEmpty)
                  Image.network(
                    s.thumbUrl!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    // Fade the photo in once decoded (no pop-in).
                    frameBuilder: (context, child, frame, wasSync) {
                      if (wasSync) return child;
                      return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        child: child,
                      );
                    },
                    // Shimmer while the thumbnail downloads.
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const AppShimmer(child: ShimmerBox(radius: 0));
                    },
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: AppColors.cardLight,
                      child: Icon(Icons.broken_image_outlined,
                          color: AppColors.textSecondary, size: 40.w),
                    ),
                  )
                else
                  ColoredBox(
                    color: AppColors.cardLight,
                    child: Icon(Icons.image_outlined,
                        color: AppColors.textSecondary, size: 40.w),
                  ),
                if (widget.tag != null && widget.tag!.isNotEmpty)
                  Positioned(
                    top: 14.h,
                    left: 14.w,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        widget.tag!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBar(SavedStatus s) {
    final likeCount = s.likesCount + (_liked ? 1 : 0);
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 10.h, 12.w, 12.h),
      child: Row(
        children: [
          // Like
          _iconAction(
            icon: _liked ? Icons.favorite : Icons.favorite_border,
            color: _liked ? AppColors.accent : AppColors.textSecondary,
            label: '$likeCount',
            onTap: () => setState(() => _liked = !_liked),
          ),
          // Share (beside like)
          _iconAction(
            icon: Icons.share_outlined,
            color: AppColors.textSecondary,
            label: S.t('share'),
            busy: _sharing,
            onTap: _share,
          ),
          if (widget.onDelete != null)
            _iconAction(
              icon: Icons.delete_outline,
              color: AppColors.textSecondary,
              onTap: widget.onDelete!,
            ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: widget.onCustomize,
            icon: Icon(Icons.edit_outlined, size: 16.w),
            label: Text(
              S.t('customize'),
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              minimumSize: Size(0, 42.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    String? label,
    bool busy = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        child: Row(
          children: [
            busy
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: color),
                  )
                : Icon(icon, size: 20.w, color: color),
            if (label != null && label.isNotEmpty) ...[
              SizedBox(width: 5.w),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
