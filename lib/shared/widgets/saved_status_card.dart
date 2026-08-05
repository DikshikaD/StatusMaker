import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/core/utils/app_snackbar.dart';
import 'package:status_maker/shared/widgets/app_shimmer.dart';
import 'package:status_maker/shared/utils/share_image.dart';
import 'package:status_maker/shared/widgets/share_target_dialog.dart';
import 'package:status_maker/features/statuses/data/likes_store.dart';
import 'package:status_maker/features/statuses/data/saved_status.dart';

/// A feed card for a *saved* status (a real user creation from Supabase). Shows
/// the rendered thumbnail as the preview, with Customize (reopen the editable
/// design) plus an optional Delete for the owner's own creations.
class SavedStatusCard extends StatefulWidget {
  final SavedStatus status;

  /// Opens the editor pre-loaded with this status's editable design.
  /// Wired to the explicit Customize button — editing is a deliberate act, not
  /// something a tap on the artwork should trigger.
  final VoidCallback onCustomize;

  /// Opens the read-only detail view for this status — what tapping the
  /// preview does, and the same destination a notification tap lands on.
  /// Falls back to [onCustomize] when not supplied, so older call sites keep
  /// their previous behaviour.
  final VoidCallback? onOpen;

  /// When provided, a delete button is shown (used in "My Creations").
  final VoidCallback? onDelete;

  /// Small pill shown over the preview (e.g. the category).
  final String? tag;

  const SavedStatusCard({
    super.key,
    required this.status,
    required this.onCustomize,
    this.onOpen,
    this.onDelete,
    this.tag,
  });

  @override
  State<SavedStatusCard> createState() => _SavedStatusCardState();
}

class _SavedStatusCardState extends State<SavedStatusCard> {
  bool _pressed = false;
  bool _sharing = false;

  /// Like state is NOT held here. It used to be a local bool, which is why the
  /// heart reset and the count reverted as soon as the card rebuilt — the tap
  /// never reached the backend. [LikesStore] owns it now.
  Future<void> _toggleLike() async {
    try {
      await LikesStore.instance.toggle(widget.status);
    } catch (_) {
      if (mounted) AppSnackBar.error(context, S.t('something_wrong'));
    }
  }

  /// Same destination popup as the editor: pick WhatsApp / Instagram / Facebook
  /// / any other app first, then download the thumbnail and hand it over. The
  /// popup opens before the download so it appears instantly.
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
      onTap: widget.onOpen ?? widget.onCustomize,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusLarge)),
        child: AspectRatio(
          // Must match the editor canvas's own aspect ratio (see
          // StatusPersonalizerScreen) — that's the ratio the thumbnail was
          // actually captured at. A mismatched ratio here forced BoxFit.cover
          // to crop the top/bottom off every real saved status.
          aspectRatio: 9 / 16,
          child: RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (s.thumbUrl != null && s.thumbUrl!.isNotEmpty)
                  Image.network(
                    s.thumbUrl!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    // Decode at most at the card's on-screen width. Without
                    // this a feed of full-resolution thumbnails decodes each
                    // at source size, which janks and OOM-kills low-end
                    // Android while the card only ever paints screen-wide.
                    cacheWidth: (ScreenUtil.screenWidth *
                            MediaQuery.devicePixelRatioOf(context))
                        .round(),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 10.h, 12.w, 12.h),
      child: Row(
        children: [
          // The icon actions vary in both count (remix and delete are
          // conditional) and width (counts grow to 3-4 digits, "Share"
          // translates, and the system font scale multiplies all of it), so
          // their natural width can exceed the row — it overflowed by 8.5px
          // with remix and delete both showing. Expanded caps the group at
          // whatever the CTA leaves behind, and the scroll view absorbs the
          // rest instead of asserting. This also replaces the Spacer that used
          // to push the CTA right: Expanded already fills that space.
          //
          // Deliberately NOT a width heuristic (e.g. hiding the Share label
          // below some breakpoint): the row's natural width depends on the
          // locale and the user's font scale, so any fixed threshold is wrong
          // for someone. This can't overflow for anyone.
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Like — rebuilds from the shared store, so the heart and
                  // count are correct on every rebuild and stay in step with
                  // the other tabs.
                  ListenableBuilder(
                    listenable: LikesStore.instance,
                    builder: (context, _) {
                      final liked = LikesStore.instance.isLiked(s.id);
                      return _iconAction(
                        icon: liked ? Icons.favorite : Icons.favorite_border,
                        color:
                            liked ? AppColors.accent : AppColors.textSecondary,
                        label: '${LikesStore.instance.countFor(s)}',
                        onTap: _toggleLike,
                      );
                    },
                  ),
                  // Remix count comes straight from the row
                  // (`statuses.remix_count`, kept in sync by a DB trigger
                  // whenever someone saves a personalization of this template)
                  // — there's nothing to toggle here, so tapping it opens the
                  // detail view, same as tapping the artwork.
                  if (s.remixCount > 0)
                    _iconAction(
                      icon: Icons.repeat,
                      color: AppColors.textSecondary,
                      label: '${s.remixCount}',
                      onTap: widget.onOpen ?? widget.onCustomize,
                    ),
                  // Share
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
                ],
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: widget.onCustomize,
            // Explicit white on the icon — see the matching button in
            // TemplateDetailScreen.
            icon: Icon(Icons.edit_outlined,
                size: 16.w, color: AppColors.onPrimary),
            label: Text(
              S.t('customize'),
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.onPrimary,
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
      // The visual stays compact; only the tappable box grows. A 20.w icon with
      // 6.h padding gave a 32dp-tall target on the app's most-tapped controls
      // (like / share / delete) — under both the 44dp and 48dp floors, and worse
      // on a small phone where the width scale clamps to 0.82.
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 48.h, minWidth: 44.w),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
      ),
    );
  }
}
