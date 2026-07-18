import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Rasterises whatever is inside the RepaintBoundary marked by [key] to PNG
/// bytes. Deselect first so no selection frame is baked into the export.
Future<Uint8List?> captureCanvas(GlobalKey key, {double pixelRatio = 3.0}) async {
  final obj = key.currentContext?.findRenderObject();
  if (obj is! RenderRepaintBoundary) return null;
  final image = await obj.toImage(pixelRatio: pixelRatio);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data?.buffer.asUint8List();
}

String _fileName() => 'status_${DateTime.now().millisecondsSinceEpoch}.png';

/// Writes the PNG to the app's documents directory and returns the path.
Future<String> saveToFile(Uint8List bytes) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/${_fileName()}');
  await file.writeAsBytes(bytes);
  return file.path;
}

/// Writes the PNG to a temp file and opens the system share sheet.
Future<void> shareBytes(Uint8List bytes) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/${_fileName()}');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path)]);
}
