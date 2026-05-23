import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('runtime no-mock-data audit', () {
    test('runtime Dart files do not contain obvious clinical mock fixtures',
        () {
      final runtimeFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      const forbiddenPatterns = <String>[
        'mockPatient',
        'mockPatients',
        'dummyPatient',
        'samplePatient',
        'fakePatient',
        'John Doe',
        'Jane Doe',
        'Budi',
        'Siti',
        'Ahmad',
      ];

      final violations = <String>[];
      for (final file in runtimeFiles) {
        final content = file.readAsStringSync();
        for (final pattern in forbiddenPatterns) {
          if (content.contains(pattern)) {
            violations.add('${file.path}: $pattern');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Runtime code must use Supabase/provider-backed data, not mock clinical fixtures.',
      );
    });
  });
}
