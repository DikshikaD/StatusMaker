import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/theme/theme_controller.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/utils/responsive.dart';

/// A lightweight, dependency-free shimmer. Sweeps a soft highlight band across
/// its child using a [ShaderMask] driven by a single repeating controller, so
/// it's cheap to run even for a whole screen of placeholders.
class AppShimmer extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const AppShimmer({super.key, required this.child, this.enabled = true});

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant AppShimmer old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final base = AppColors.cardLight;
    final highlight = Color.alphaBlend(
      Colors.white.withValues(alpha: ThemeController.isDark ? 0.10 : 0.90),
      base,
    );

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value; // 0..1
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = bounds.width * (t * 2 - 1); // slide left->right
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(dx),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// Translates a gradient horizontally so the highlight band moves across.
class _SlideGradient extends GradientTransform {
  final double dx;
  const _SlideGradient(this.dx);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, 0, 0);
}

/// A solid rounded block used as a shimmer placeholder building-block.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  /// Null falls back to the scaled default. Kept nullable (rather than
  /// defaulting to `8.r`) so the constructor can stay `const`.
  final double? radius;

  const ShimmerBox({super.key, this.width, this.height, this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(radius ?? 8.r),
      ),
    );
  }
}

/// A placeholder that mirrors [SavedStatusCard]'s layout (9:16 preview + a
/// small action bar) so the feed doesn't jump when the real cards arrive.
/// Keep the aspect ratio in sync with [SavedStatusCard].
class StatusCardShimmer extends StatelessWidget {
  const StatusCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          color: AppColors.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 9 / 16,
              child: ShimmerBox(radius: AppDimensions.radiusLarge),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
              child: Row(
                children: [
                  ShimmerBox(width: 44.w, height: 16.h, radius: 20.r),
                  const Spacer(),
                  ShimmerBox(width: 96.w, height: 40.h, radius: 22.r),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
