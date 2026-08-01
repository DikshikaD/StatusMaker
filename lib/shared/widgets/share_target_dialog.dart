import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/shared/utils/native_share.dart';

/// Asks *where* a finished status should go — straight to WhatsApp / Instagram
/// / Facebook, or out to the system chooser — as a centered popup.
///
/// Resolves to the chosen [ShareTarget], or null if the user dismissed it. The
/// caller owns the capture-and-send work, so the popup stays instant to open and
/// never holds a half-exported PNG.
Future<ShareTarget?> showShareTargetDialog(BuildContext context) {
  return showDialog<ShareTarget>(
    context: context,
    // Tapping outside is the same as Cancel — nothing has been exported yet.
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (_) => const ShareTargetDialog(),
  );
}

/// The popup's contents. Prefer [showShareTargetDialog] over building this
/// directly.
///
/// The brand marks are drawn, not bundled: no logo assets to ship or keep in
/// sync, and they sit correctly on both themes.
class ShareTargetDialog extends StatefulWidget {
  const ShareTargetDialog({super.key});

  @override
  State<ShareTargetDialog> createState() => _ShareTargetDialogState();
}

class _ShareTargetDialogState extends State<ShareTargetDialog> {
  /// Null until the platform answers — every tile stays enabled meanwhile, so
  /// the popup never flickers from dimmed to bright as it opens.
  Set<ShareTarget>? _installed;

  @override
  void initState() {
    super.initState();
    NativeShare.installedTargets().then((s) {
      if (mounted) setState(() => _installed = s);
    });
  }

  bool _enabled(ShareTarget t) =>
      t == ShareTarget.more || _installed == null || _installed!.contains(t);

  void _pick(ShareTarget t) => Navigator.of(context).pop(t);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: ConstrainedBox(
        // Keeps the tiles a readable cluster on tablets instead of stretching
        // them across a very wide popup.
        constraints: BoxConstraints(maxWidth: 400.w),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30.r,
                offset: Offset(0, 12.h),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 10.h),
          // Scrolls rather than overflowing on short screens with the system
          // font scaled up.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  S.t('share_to'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Text(
                    S.t('share_to_msg'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5.sp,
                      height: 1.35,
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                // Wraps to a second run on very narrow / large-font devices
                // rather than squeezing four tiles into one cramped row.
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4.w,
                  runSpacing: 10.h,
                  children: [
                    _tile(
                      target: ShareTarget.whatsapp,
                      label: 'WhatsApp',
                      glyph: const _WhatsAppGlyph(),
                      gradient: const [Color(0xFF25D366), Color(0xFF128C7E)],
                    ),
                    _tile(
                      target: ShareTarget.instagram,
                      label: 'Instagram',
                      glyph: const _InstagramGlyph(),
                      gradient: const [
                        Color(0xFF7B2FF7),
                        Color(0xFFE1306C),
                        Color(0xFFFDA034),
                      ],
                    ),
                    _tile(
                      target: ShareTarget.facebook,
                      label: 'Facebook',
                      glyph: const _FacebookGlyph(),
                      gradient: const [Color(0xFF1877F2), Color(0xFF0A55C8)],
                    ),
                    _tile(
                      target: ShareTarget.more,
                      label: S.t('share_more'),
                      glyph: const _MoreGlyph(),
                      gradient: AppColors.accentGradient,
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                _cancel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One share destination: brand disc, label, and a subtle "not installed"
  /// hint so a dimmed tile explains itself instead of just looking broken.
  Widget _tile({
    required ShareTarget target,
    required String label,
    required Widget glyph,
    required List<Color> gradient,
  }) {
    final enabled = _enabled(target);
    final size = 56.w;

    return SizedBox(
      width: 80.w,
      child: InkWell(
        onTap: () => _pick(target),
        borderRadius: BorderRadius.circular(18.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 2.w),
          child: Column(
            children: [
              Opacity(
                opacity: enabled ? 1 : 0.4,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(size / 2),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.last.withValues(alpha: 0.35),
                        blurRadius: 10.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SizedBox(
                      width: size * 0.54,
                      height: size * 0.54,
                      child: glyph,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 7.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      enabled ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!enabled)
                Text(
                  S.t('not_installed'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9.5.sp,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cancel() => TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          S.t('cancel'),
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

// ---- brand marks ----------------------------------------------------------
// Simple, recognisable glyphs sized to whatever box they're given.

/// White speech bubble with the brand-green handset sitting inside it.
class _WhatsAppGlyph extends StatelessWidget {
  const _WhatsAppGlyph();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) {
          final s = math.min(c.maxWidth, c.maxHeight);
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(size: Size(s, s), painter: _BubblePainter()),
              Padding(
                // Nudged up out of the bubble's tail so the handset sits
                // centred in the round part, not across the point.
                padding: EdgeInsets.only(bottom: s * 0.1),
                child: Icon(
                  Icons.call,
                  color: const Color(0xFF1EBE5D),
                  size: s * 0.46,
                ),
              ),
            ],
          );
        },
      );
}

/// A circle with one pulled-out corner at the bottom-left — the chat-bubble
/// silhouette, drawn rather than shipped as a logo asset.
class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(size.width / 2, size.height / 2 - s * 0.04);
    final r = s * 0.45;

    final path = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    path.addPolygon([
      Offset(c.dx - r * 0.80, c.dy + r * 0.40),
      Offset(c.dx - r * 1.02, c.dy + r * 1.18),
      Offset(c.dx - r * 0.10, c.dy + r * 0.88),
    ], true);

    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InstagramGlyph extends StatelessWidget {
  const _InstagramGlyph();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _InstagramPainter());
}

/// Rounded-square camera outline with a lens and a small flash dot.
class _InstagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.11
      ..strokeCap = StrokeCap.round;

    final box = Rect.fromLTWH(s * 0.06, s * 0.06, s * 0.88, s * 0.88);
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, Radius.circular(s * 0.28)),
      stroke,
    );
    canvas.drawCircle(box.center, s * 0.23, stroke);
    canvas.drawCircle(
      Offset(box.right - s * 0.16, box.top + s * 0.16),
      s * 0.055,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The lower-case "f" wordmark, set in the app's own type rather than an
/// imported logo glyph.
class _FacebookGlyph extends StatelessWidget {
  const _FacebookGlyph();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => FittedBox(
          fit: BoxFit.contain,
          child: Text(
            'f',
            style: TextStyle(
              color: Colors.white,
              fontSize: math.min(c.maxWidth, c.maxHeight) * 1.35,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      );
}

class _MoreGlyph extends StatelessWidget {
  const _MoreGlyph();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => Icon(
          Icons.ios_share,
          color: Colors.white,
          size: math.min(c.maxWidth, c.maxHeight),
        ),
      );
}
