import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Supabase migration audit', () {
    final migrationDirectory = Directory('supabase/migrations');

    test('uses only canonical timestamped migrations in the active folder', () {
      final sqlFiles = migrationDirectory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.sql'))
          .map((file) => file.uri.pathSegments.last)
          .toList()
        ..sort();

      expect(
        sqlFiles,
        equals([
          '20240101000000_init_schema.sql',
          '20240101000001_rls_policies.sql',
          '20260507000000_security_hardening.sql',
        ]),
      );
    });

    test('canonical schema keeps the app-facing patient relationship shape',
        () {
      final initSchema =
          File('supabase/migrations/20240101000000_init_schema.sql')
              .readAsStringSync();
      final hardening =
          File('supabase/migrations/20260507000000_security_hardening.sql')
              .readAsStringSync();
      final combinedSql = '$initSchema\n$hardening';

      expect(combinedSql,
          contains("role TEXT NOT NULL CHECK (role IN ('doctor', 'patient'))"));
      expect(combinedSql,
          contains('patient_id UUID NOT NULL REFERENCES public.profiles(id)'));
      expect(
          combinedSql,
          contains(
              'CREATE OR REPLACE FUNCTION public.complete_patient_registration'));
      expect(
          combinedSql, isNot(contains("role IN ('doctor','patient','admin')")));
      expect(combinedSql, isNot(contains('profile_id uuid UNIQUE')));
      expect(combinedSql,
          isNot(contains('CREATE EXTENSION IF NOT EXISTS postgis')));
    });
  });
}
