import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:status_maker/shared/utils/native_share.dart';

/// Downloads a remote image (e.g. a saved status thumbnail) to the cache dir
/// and returns the file path, or null if it couldn't be fetched.
///
/// The cache dir is deliberate: `share_paths.xml` exposes it to the share
/// FileProvider, so the file can be handed to another app. Uses dart:io's
/// HttpClient directly (this is the app fetching its own asset, not the
/// assistant's restricted web tools).
Future<String?> downloadImageToTemp(String url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException('status ${response.statusCode}');
    }
    final bytes = await consolidateHttpClientResponseBytes(response);

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/share_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    return file.path;
  } catch (e) {
    debugPrint('downloadImageToTemp failed: $e');
    return null;
  } finally {
    client.close();
  }
}

/// Sends a remote image to [target] — the feed's counterpart to the editor's
/// share, which already has the PNG in hand.
///
/// Falls back to sharing the link as text when the image can't be downloaded, so
/// a flaky network still leaves the user with something to send. Returns false
/// only if even that failed.
Future<bool> shareRemoteImage({
  required String url,
  required ShareTarget target,
  String? text,
}) async {
  final path = await downloadImageToTemp(url);
  if (path != null) {
    await NativeShare.shareImage(path: path, target: target, text: text);
    return true;
  }
  try {
    await Share.share(text == null ? url : '$text\n$url');
    return true;
  } catch (e) {
    debugPrint('shareRemoteImage link fallback failed: $e');
    return false;
  }
}
