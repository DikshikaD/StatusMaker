import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/template_motif.dart';
import 'package:status_maker/features/editor/utils/canvas_image.dart';
import 'package:status_maker/features/editor/widgets/motif_painter.dart';
import 'package:status_maker/studio/renderers/generated_background.dart';

/// Renders the status background: a generated studio recipe, a gallery image,
/// a built-in gradient, or a built-in solid colour. Isolated in a RepaintBoundary so foreground edits
/// never repaint it.
class TemplateBackground extends StatelessWidget {
  final BackgroundState state;
  final VoidCallback onTap;

  const TemplateBackground({super.key, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget bg;
    if (state.isGenerated) {
      // Procedural studio background — painted live (and re-evaluated at
      // export resolution), see GeneratedBackground.
      bg = GeneratedBackground(config: state.generated!);
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
