import 'package:flutter_test/flutter_test.dart';
import 'package:status_maker/features/statuses/data/status_repository.dart';

void main() {
  test('uniqueStorageName is unpredictable, unique and keeps the extension', () {
    final names = {for (var i = 0; i < 2000; i++) uniqueStorageName('png')};
    expect(names.length, 2000);
    final re = RegExp(r'^\d+_[0-9a-f]{24}\.png$');
    expect(names.every(re.hasMatch), isTrue);
  });
}
