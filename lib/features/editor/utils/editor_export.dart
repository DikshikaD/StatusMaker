import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:status_maker/shared/utils/share_dir.dart';
import 'package:path_provider/path_provider.dart';

/// The pixel ratio every editor export is rasterised at (see [captureCanvas]).
const double kExportPixelRatio = 3.0;

/// Upper bound for any decode size, so a zoomed-in photo can't blow memory.
const int kMaxDecodeWidth = 2048;

/// Decode width for an image drawn [boxWidth] logical px wide on the canvas
/// and further enlarged by [scale] (in-shape zoom × object scale): enough
/// pixels to stay sharp in a [kExportPixelRatio] export, clamped to
/// [kMaxDecodeWidth].
int exportCacheWidth(double boxWidth, [double scale = 1.0]) {
  final s = scale.isFinite && scale > 0 ? scale : 1.0;
  return (boxWidth * kExportPixelRatio * s).round().clamp(1, kMaxDecodeWidth);
}

/// Rasterises whatever is inside the RepaintBoundary marked by [key] to PNG
/// bytes. Deselect first so no selection frame is baked into the export.
Future<Uint8List?> captureCanvas(GlobalKey key,
    {double pixelRatio = kExportPixelRatio}) async {
  final obj = key.currentContext?.findRenderObject();
  if (obj is! RenderRepaintBoundary) return null;
  final image = await obj.toImage(pixelRatio: pixelRatio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } finally {
    // ui.Image holds native memory that GC only reclaims non-deterministically
    // — at 3x a canvas export is several MB, so repeated saves in one session
    // would grow unbounded without this.
    image.dispose();
  }
}

String _fileName() => 'status_${DateTime.now().millisecondsSinceEpoch}.png';

/// Saves used to also write every export to the app's documents directory. That
/// folder is private to the app and nothing ever read it back, so each Save
/// just left a multi-MB PNG behind forever (and "Delete my data" could not
/// reach them). Saves no longer write there; this removes what earlier
/// versions left. [dir] is injectable for tests. Never throws.
Future<int> purgeLegacyExports([Directory? dir]) async {
  var removed = 0;
  try {
    final root = dir ?? await getApplicationDocumentsDirectory();
    final pattern = RegExp(r'^status_\d+\.png$');
    await for (final e in root.list(followLinks: false)) {
      if (e is! File) continue;
      final name = e.uri.pathSegments.last;
      if (!pattern.hasMatch(name)) continue;
      try {
        await e.delete();
        removed++;
      } catch (_) {}
    }
  } catch (_) {}
  return removed;
}

/// Writes the PNG to the temp/cache directory and returns the path, ready to
/// hand to a share target — see `NativeShare.shareImage`, which takes a path
/// (the native targeted-share channel can't carry raw bytes).
///
/// Written to [shareDir], the one folder the share FileProvider exposes.
Future<String> writeTempPng(Uint8List bytes) async {
  final dir = await shareDir();
  final file = File('${dir.path}/${_fileName()}');
  await file.writeAsBytes(bytes);
  return file.path;
}
