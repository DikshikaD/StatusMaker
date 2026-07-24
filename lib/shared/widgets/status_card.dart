import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/features/editor/data/templates_data.dart';
import 'package:status_maker/features/editor/data/template_motif.dart';
import 'package:status_maker/features/editor/widgets/motif_painter.dart';

/// A feed card that shows a ready-made status *template* (gradient + motif +
/// styled text) as a live preview, with Like, Share and Customize actions.
class StatusCard extends StatefulWidget {
  final StatusTemplate template;

  /// Small pill shown over the preview (e.g. the category).
  final String? tag;

  /// Approximate like count shown next to the heart (display only).
  final String likes;

  /// Opens the editor pre-loaded with this template.
  final VoidCallback onCustomize;

  /// Optional share handler; falls back to a "sharing" snackbar.
  final VoidCallback? onShare;

  const StatusCard({
    super.key,
    required this.template,
    required this.onCustomize,
    this.tag,
    this.likes = '',
    this.onShare,
  });

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard> {
  bool _pressed = false;
  bool _liked = false;

  StatusTemplate get _t => widget.template;

  // The template is immutable, so its text style never changes. Resolving a
  // GoogleFonts style on every rebuild (each like tap / press) is wasteful, so
  // we compute it once and reuse it. Invalidated if the template swaps in.
  TextStyle? _cachedTextStyle;

  @override
  void didUpdateWidget(covariant StatusCard old) {
    super.didUpdateWidget(old);
    if (old.template != widget.template) _cachedTextStyle = null;
  }

  TextStyle get _textStyle => _cachedTextStyle ??= GoogleFonts.getFont(
        _t.fontFamily,
        color: _t.textColor,
        fontSize: (_t.fontSize * 0.5).sp,
        fontWeight: _t.bold ? FontWeight.w800 : FontWeight.w500,
        letterSpacing: _t.letterSpacing,
        height: 1.25,
      );

  void _toggleLike() => setState(() => _liked = !_liked);

  void _share() {
    if (widget.onShare != null) {
      widget.onShare!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.t('sharing')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            _preview(),
            _actionBar(),
          ],
        ),
      ),
    );
  }

  // ---- template preview -----------------------------------------------------
  Widget _preview() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onCustomize,
      child: ClipRRect(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
        child: AspectRatio(
          aspectRatio: 4 / 5,
          // Cache the (expensive) gradient + motif + text as its own layer so a
          // like/press setState only repaints the action bar, not this preview.
          child: RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Gradient background.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _t.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Subtle decorative motif.
              if (_t.motif != TemplateMotif.none)
                Positioned.fill(
                  child: CustomPaint(
                    painter: MotifPainter(
                      _t.motif,
                      _t.textColor.withValues(alpha: 0.16),
                    ),
                  ),
                ),
              // Styled template text.
              Padding(
                padding: EdgeInsets.all(22.w),
                child: Align(
                  alignment: _textAlignment(),
                  child: _templateText(),
                ),
              ),
              // Category pill.
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

  Alignment _textAlignment() {
    final y = _t.anchor == TemplateAnchor.top
        ? -0.75
        : _t.anchor == TemplateAnchor.bottom
            ? 0.75
            : 0.0;
    final x = _t.align == TextAlign.left
        ? -1.0
        : _t.align == TextAlign.right
            ? 1.0
            : 0.0;
    return Alignment(x, y);
  }

  Widget _templateText() {
    final text = Text(
      _t.text,
      textAlign: _t.align,
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
      style: _textStyle,
    );

    if (_t.highlight == null) return text;
    // Templates with a highlight paint the text on a colour block.
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _t.highlight,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: text,
    );
  }

  // ---- action bar -----------------------------------------------------------
  Widget _actionBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
      child: Row(
        children: [
          _iconAction(
            icon: _liked ? Icons.favorite : Icons.favorite_border,
            color: _liked ? AppColors.accent : AppColors.textSecondary,
            label: widget.likes,
            onTap: _toggleLike,
          ),
          SizedBox(width: 6.w),
          _iconAction(
            icon: Icons.share_outlined,
            color: AppColors.textSecondary,
            label: S.t('share'),
            onTap: _share,
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
              backgroundColor: AppColors.primary,
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
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        child: Row(
          children: [
            Icon(icon, size: 20.w, color: color),
            if (label.isNotEmpty) ...[
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
