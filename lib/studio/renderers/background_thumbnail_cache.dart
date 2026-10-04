import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:status_maker/studio/models/background_config.dart';
import 'package:status_maker/studio/renderers/background_painter.dart';
import 'package:status_maker/studio/shaders/studio_shaders.dart';

/// Small rasterised previews of generated backgrounds for pickers and grids.
///
/// A sheet showing forty background tiles must not run forty shader passes
/// per scroll frame on a budget phone. Each recipe is painted *once* into a
/// `ui.Image` at tile size and reused; the LRU cap keeps memory bounded
/// (~180 KB per 180×320 RGBA tile → ~8 MB at the cap).
class BackgroundThumbnails {
  BackgroundThumbnails._();

  static const int _cap = 48;
  static final LinkedHashMap<String, ui.Image> _cache = LinkedHashMap();
  static final Map<String, Future<ui.Image>> _pending = {};

  static String _key(BackgroundConfig c, int w, int h) =>
      '${c.signature}@${w}x$h';

  /// The cached tile if it already exists — for a synchronous first build.
  static ui.Image? peek(BackgroundConfig config, {int width = 180, int height = 320}) {
    final k = _key(config, width, height);
    final img = _cache.remove(k);
    if (img != null) _cache[k] = img; // refresh LRU position
    return img;
  }

  /// Renders (or returns) the tile. Waits for the recipe's shaders so the
  /// bitmap is the finished picture, never the fallback gradient.
  static Future<ui.Image> render(BackgroundConfig config,
      {int width = 180, int height = 320}) {
    final k = _key(config, width, height);
    final hit = peek(config, width: width, height: height);
    if (hit != null) return Future.value(hit);
    return _pending.putIfAbsent(k, () async {
      try {
        await StudioShaders.ensureFor(config);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        paintBackgroundConfig(
            canvas, Size(width.toDouble(), height.toDouble()), config);
        final picture = recorder.endRecording();
        final image = await picture.toImage(width, height);
        picture.dispose();
        _cache[k] = image;
        while (_cache.length > _cap) {
          _cache.remove(_cache.keys.first)?.dispose();
        }
        return image;
      } finally {
        _pending.remove(k);
      }
    });
  }

  /// Drops every cached tile (e.g. on a memory-pressure warning).
  static void clear() {
    for (final img in _cache.values) {
      img.dispose();
    }
    _cache.clear();
  }
}

/// A grid/picker tile for a generated background. Shows the cached bitmap
/// when available and the recipe's gradient while it renders, so the grid is
/// never blank and never jumps.
class BackgroundThumb extends StatefulWidget {
  final BackgroundConfig config;
  final BorderRadius borderRadius;

  /// Render size in device-independent pixels of the *bitmap*; the widget
  /// itself fills whatever box it's given and scales the bitmap to cover it.
  final int width;
  final int height;

  const BackgroundThumb({
    super.key,
    required this.config,
    this.borderRadius = BorderRadius.zero,
    this.width = 180,
    this.height = 320,
  });

  @override
  State<BackgroundThumb> createState() => _BackgroundThumbState();
}

class _BackgroundThumbState extends State<BackgroundThumb> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(BackgroundThumb old) {
    super.didUpdateWidget(old);
    if (old.config != widget.config ||
        old.width != widget.width ||
        old.height != widget.height) {
      _image?.dispose();
      _image = null;
      _load();
    }
  }

  // The widget holds its own handle (`clone()` shares the pixels, not the
  // lifetime) so an LRU eviction in the cache can never dispose an image
  // that's still on screen.
  void _load() {
    final hit = BackgroundThumbnails.peek(widget.config,
        width: widget.width, height: widget.height);
    if (hit != null) {
      _image = hit.clone();
      return;
    }
    BackgroundThumbnails.render(widget.config,
            width: widget.width, height: widget.height)
        .then((img) {
      if (!mounted) return;
      setState(() => _image = img.clone());
    }).catchError((_) {
      // Keep showing the gradient; nothing else to do.
    });
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    final child = img == null
        ? DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.config.gradient,
                begin: widget.config.gradientBegin,
                end: widget.config.gradientEnd,
              ),
            ),
          )
        : RawImage(
            image: img,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
          );
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox.expand(child: child),
    );
  }
}
