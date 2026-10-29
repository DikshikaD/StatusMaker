import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:status_maker/core/constants/app_version.dart';

void main() {
  test('Settings version matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*([^+\s]+)', multiLine: true)
        .firstMatch(pubspec);
    expect(match, isNotNull);
    expect(kAppVersion, match!.group(1));
  });
}
