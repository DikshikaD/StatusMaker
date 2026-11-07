import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/template_motif.dart';
import 'package:status_maker/features/editor/utils/canvas_image.dart';
import 'package:status_maker/features/editor/widgets/motif_painter.dart';
import 'package:status_maker/studio/renderers/background_thumbnail_cache.dart';
import 'package:status_maker/studio/renderers/generated_background.dart';

/// Renders the status background: a generated studio recipe, a gallery image,
/// a built-in gradient, or a built-in solid colour. Isolated in a RepaintBoundary so foreground edits
/// never repaint it.
class TemplateBackground extends StatelessWidget {
  final BackgroundState state;
  final VoidCallback onTap;

  /// Draw a generated background from a cached bitmap instead of painting its
  /// shader layers live. For grids/rows of preview cards only: every card that
  /// shares a recipe shares one raster, rendered once off the build path, and
  /// a card scrolling back into view costs a blit rather than 3–4 full-rect
  /// shader passes. The editor and the export keep painting live, so they stay
  /// crisp at any resolution.
  final bool useCachedRaster;

  const TemplateBackground({
    super.key,
    required this.state,
    required this.onTap,
    this.useCachedRaster = false,
  });

  /// Raster size for [useCachedRaster] — the design space itself, which is
  /// already more pixels than a two-column grid card shows on a phone.
  static const int _rasterWidth = 360;
  static const int _rasterHeight = 640;

  @override
  Widget build(BuildContext context) {
    Widget bg;
    if (state.isGenerated) {
      // Procedural studio background — painted live (and re-evaluated at
      // export resolution), see GeneratedBackground.
      bg = useCachedRaster
          ? BackgroundThumb(
              config: state.generated!,
              width: _rasterWidth,
              height: _rasterHeight,
            )
          : GeneratedBackground(config: state.generated!);
    } else if (state.isAsset) {
      bg = Image.asset(
        state.assetPath!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF0F172A)),
      );
    } else if (state.isImage) {
      bg = canvasImage(
        state.imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF0F172A)),
      );
    } else if (state.isGradient) {
      bg = DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: state.gradientColors!,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    } else {
      bg = ColoredBox(color: state.color ?? const Color(0xFF0F172A));
    }

    // A photo can be visually busy, so overlay a soft dark scrim (stronger at
    // the top/bottom, lighter in the middle) whenever the background is an
    // image. This keeps text readable no matter where it's placed, and — since
    // it bakes into the export — the saved status stays legible too.
    final bool isPhoto = state.isImage || state.isAsset;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              bg,
              if (isPhoto)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x59000000), // ~35% black (top)
                        Color(0x1A000000), // ~10% black (middle)
                        Color(0x66000000), // ~40% black (bottom)
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              if (state.motif != TemplateMotif.none)
                Positioned.fill(
                  child: CustomPaint(
                    painter: MotifPainter(
                      state.motif,
                      state.motifColor ?? Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
