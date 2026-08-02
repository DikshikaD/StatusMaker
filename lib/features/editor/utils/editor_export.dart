import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// Rasterises whatever is inside the RepaintBoundary marked by [key] to PNG
/// bytes. Deselect first so no selection frame is baked into the export.
Future<Uint8List?> captureCanvas(GlobalKey key, {double pixelRatio = 3.0}) async {
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

/// Writes the PNG to the app's documents directory and returns the path.
Future<String> saveToFile(Uint8List bytes) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/${_fileName()}');
  await file.writeAsBytes(bytes);
  return file.path;
}

/// Writes the PNG to the temp/cache directory and returns the path, ready to
/// hand to a share target — see `NativeShare.shareImage`, which takes a path
/// (the native targeted-share channel can't carry raw bytes).
///
/// The cache dir is deliberate: `share_paths.xml` exposes it to the share
/// FileProvider, and the OS reclaims it without us having to clean up.
Future<String> writeTempPng(Uint8List bytes) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/${_fileName()}');
  await file.writeAsBytes(bytes);
  return file.path;
}
