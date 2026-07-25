import 'dart:io';
import 'package:flutter/material.dart';

/// Builds an [Image] for a photo path that may be either a local device file
/// or a remote URL. Designs saved to Supabase have their photo paths rewritten
/// to public storage URLs (so they're portable), while a freshly picked photo
/// is still a local file path. This picks the right loader for each.
Image canvasImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  int? cacheWidth,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  if (path.startsWith('http')) {
    return Image.network(
      path,
      width: width,
      height: height,
      fit: fit,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      errorBuilder: errorBuilder,
    );
  }
  return Image.file(
    File(path),
    width: width,
    height: height,
    fit: fit,
    gaplessPlayback: true,
    cacheWidth: cacheWidth,
    errorBuilder: errorBuilder,
  );
}
