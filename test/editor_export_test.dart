import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:status_maker/features/editor/utils/editor_export.dart';

void main() {
  test('purgeLegacyExports removes only old status_<n>.png exports', () async {
    final dir = await Directory.systemTemp.createTemp('legacy_exports');
    addTearDown(() => dir.delete(recursive: true));
    for (final n in ['status_1.png', 'status_1700000000000.png']) {
      await File('${dir.path}/$n').writeAsBytes([1, 2, 3]);
    }
    for (final n in ['keep.png', 'status_x.png', 'status_1.png.bak']) {
      await File('${dir.path}/$n').writeAsBytes([1]);
    }
    final removed = await purgeLegacyExports(dir);
    expect(removed, 2);
    final left = dir.listSync().map((e) => e.uri.pathSegments.last).toSet();
    expect(left, {'keep.png', 'status_x.png', 'status_1.png.bak'});
  });

  test('purgeLegacyExports never throws on a missing directory', () async {
    final missing = Directory('${Directory.systemTemp.path}/nope_${DateTime.now().microsecondsSinceEpoch}');
    expect(await purgeLegacyExports(missing), 0);
  });
}
