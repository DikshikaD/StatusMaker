import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// `<cache>/share/` — the only folder the share FileProvider exposes to other
/// apps (android/app/src/main/res/xml/share_paths.xml). Every file handed to
/// WhatsApp & co. is written here; the OS reclaims the cache on its own.
Future<Directory> shareDir() async {
  final dir = Directory('${(await getTemporaryDirectory()).path}/share');
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}
