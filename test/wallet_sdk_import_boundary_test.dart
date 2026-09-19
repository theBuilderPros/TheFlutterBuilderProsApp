import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('application code cannot import private Wallet SDK internals', () {
    final List<String> violations = Directory('lib/app')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.endsWith('.dart'))
        .where(
          (File file) => file.readAsStringSync().contains('wallet_sdk/src/'),
        )
        .map((File file) => file.path)
        .toList();

    expect(violations, isEmpty);
  });
}
