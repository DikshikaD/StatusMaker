import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The two images a saved/posted status is stored as: the full export
/// (detail view, Share from the feed) and a small feed preview.
@immutable
class EncodedExport {
  /// The full-resolution image, ready to upload.
  final Uint8List full;

  /// File extension for [full] (`jpg` or `png`).
  final String fullExt;

  /// MIME type for [full] — the storage buckets only accept image/jpeg,
  /// image/png and image/webp, and `image/jpg` is not a real type.
  final String fullMime;

  /// ~540 px lossy WebP for the feed, or null when no encoder was available
  /// (the feed then falls back to [full], as it always has).
  final Uint8List? preview;

  const EncodedExport({
    required this.full,
    required this.fullExt,
    required this.fullMime,
    this.preview,
  });
}

/// Turns a captured canvas into upload-ready bytes in ONE native pass.
///
/// The old pipeline was: Flutter PNG-encodes the 3x capture (the slowest step
/// on the device — hundreds of ms for a 1080×1920 image with grain or a
/// photo) → the 2–5 MB PNG is uploaded as-is → the same PNG is sent back over
/// the platform channel, decoded by Android, downscaled and re-encoded as the
/// WebP preview. Everything ran one after the other.
///
/// Now the raw pixels go to Android once; it builds one Bitmap and encodes
/// both the full image (JPEG q95 — visually indistinguishable from the PNG at
/// this resolution, typically 5–10x smaller, so the upload that dominated
/// posting time shrinks accordingly) and the preview, on a background thread.
/// No PNG is encoded or decoded at all on this path.
///
/// Anywhere the native encoder isn't available (non-Android, or it fails) the
/// previous lossless PNG path is used unchanged, so nothing regresses.
class ExportEncoder {
  ExportEncoder._();

  static const MethodChannel _native =
      MethodChannel('status_maker/native_share');

  /// JPEG quality for the full image. 95 keeps text edges and gradients clean.
  static const int fullQuality = 95;
  static const int previewMaxWidth = 540;
  static const int previewQuality = 80;

  /// Does not dispose [image]; the caller owns it.
  static Future<EncodedExport> encode(ui.Image image) async {
    if (!kIsWeb && Platform.isAndroid) {
      final native = await _encodeNative(image);
      if (native != null) return native;
    }
    return _encodePngFallback(image);
  }

  static Future<EncodedExport?> _encodeNative(ui.Image image) async {
    try {
      final raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (raw == null) return null;
      final res = await _native.invokeMapMethod<String, dynamic>(
        'encodeExport',
        {
          'rgba': raw.buffer.asUint8List(raw.offsetInBytes, raw.lengthInBytes),
          'width': image.width,
          'height': image.height,
          'quality': fullQuality,
          'previewMaxWidth': previewMaxWidth,
          'previewQuality': previewQuality,
        },
      );
      final full = res?['full'];
      if (full is! Uint8List || full.isEmpty) return null;
      final preview = res?['preview'];
      return EncodedExport(
        full: full,
        fullExt: 'jpg',
        fullMime: 'image/jpeg',
        preview: preview is Uint8List && preview.isNotEmpty ? preview : null,
      );
    } catch (e) {
      debugPrint('ExportEncoder native encode failed, using PNG: $e');
      return null;
    }
  }

  static Future<EncodedExport> _encodePngFallback(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw StateError('Could not encode the status image');
    }
    final png = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    return EncodedExport(
      full: png,
      fullExt: 'png',
      fullMime: 'image/png',
      preview: await _legacyPreview(png),
    );
  }

  /// The pre-existing PNG → WebP preview path (Android only).
  static Future<Uint8List?> _legacyPreview(Uint8List png) async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      return await _native.invokeMethod<Uint8List>('encodePreview', {
        'bytes': png,
        'maxWidth': previewMaxWidth,
        'quality': previewQuality,
      });
    } catch (e) {
      debugPrint('ExportEncoder preview encode failed: $e');
      return null;
    }
  }
}
