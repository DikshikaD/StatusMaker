import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Downloads a remote image (e.g. a saved status thumbnail) to a temp file and
/// opens the system share sheet so it can go straight to WhatsApp etc. Falls
/// back to sharing the link as text if the download fails. Uses dart:io's
/// HttpClient directly (this is the app fetching its own asset, not the
/// assistant's restricted web tools).
Future<bool> shareImageUrl(String url, {String? text}) async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      client.close();
      throw HttpException('status ${response.statusCode}');
    }
    final bytes = await consolidateHttpClientResponseBytes(response);
    client.close();

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/share_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: text);
    return true;
  } catch (e) {
    debugPrint('shareImageUrl failed, falling back to link: $e');
    try {
      await Share.share(text == null ? url : '$text\n$url');
      return true;
    } catch (_) {
      return false;
    }
  }
}
