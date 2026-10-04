import 'package:flutter/material.dart';

import 'package:status_maker/studio/models/background_config.dart';
import 'package:status_maker/studio/renderers/background_painter.dart';

/// Fills its box with a live-painted [BackgroundConfig].
///
/// Painted (not an image) on purpose: the canvas's `RepaintBoundary` already
/// caches the raster between foreground edits, and painting rather than
/// blitting means the 3x export re-evaluates the shaders at export
/// resolution — crisp grain and smooth gradients instead of an upscaled
/// screen-resolution bitmap. Grids with many tiles use [BackgroundThumb]
/// (see background_thumbnail_cache.dart), which *does* cache bitmaps.
class GeneratedBackground extends StatelessWidget {
  final BackgroundConfig config;

  const GeneratedBackground({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BackgroundConfigPainter(config),
      // Several full-rect shader passes — worth caching as its own layer and
      // never animated.
      isComplex: true,
      willChange: false,
      child: const SizedBox.expand(),
    );
  }
}
