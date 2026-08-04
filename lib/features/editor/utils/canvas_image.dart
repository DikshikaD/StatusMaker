import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
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
    // Deliberately NOT Image.network: that caches only in memory, so every
    // app restart would re-download the image and bill us for the egress
    // again. CachedNetworkImageProvider keeps it on disk. Wrapped in an
    // Image (rather than a CachedNetworkImage widget) so the return type and
    // every existing call site stay unchanged.
    ImageProvider provider = CachedNetworkImageProvider(path);
    if (cacheWidth != null) {
      provider = ResizeImage(provider, width: cacheWidth);
    }
    return Image(
      image: provider,
      width: width,
      height: height,
      fit: fit,
      gaplessPlayback: true,
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
