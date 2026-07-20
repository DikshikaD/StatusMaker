import 'dart:io';
import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/template_motif.dart';
import 'package:status_maker/features/editor/widgets/motif_painter.dart';

/// Renders the status background: a gallery image, a built-in gradient, or a
/// built-in solid colour. Isolated in a RepaintBoundary so foreground edits
/// never repaint it.
class TemplateBackground extends StatelessWidget {
  final BackgroundState state;
  final VoidCallback onTap;

  const TemplateBackground({super.key, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget bg;
    if (state.isAsset) {
      bg = Image.asset(
        state.assetPath!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF0F172A)),
      );
    } else if (state.isImage) {
      bg = Image.file(
        File(state.imagePath!),
        fit: BoxFit.cover,
        gaplessPlayback: true,
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

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              bg,
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
