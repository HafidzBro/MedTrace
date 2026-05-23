import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medtrace/core/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String _env(String name) => Platform.environment[name] ?? '';

SupabaseClient _client({
  String? accessToken,
  bool autoRefreshToken = false,
}) {
  final url = _env('MEDTRACE_SUPABASE_URL').isNotEmpty
      ? _env('MEDTRACE_SUPABASE_URL')
      : AppConfig.supabaseUrl;
  final anonKey = _env('MEDTRACE_SUPABASE_ANON_KEY').isNotEmpty
      ? _env('MEDTRACE_SUPABASE_ANON_KEY')
      : AppConfig.supabaseAnonKey;

  return SupabaseClient(
    url,
    anonKey,
    accessToken: accessToken == null ? null : () async => accessToken,
    authOptions: AuthClientOptions(autoRefreshToken: autoRefreshToken),
  );
}

void main() {
  group('Supabase Phase 1 real database checks', () {
    test('anon key can reach the real profiles endpoint', () async {
      final response =
          await _client().from('profiles').select('id, role').limit(1);

      expect(response, isA<List<dynamic>>());
    });

    test('patient registration RPC exists and rejects anonymous calls',
        () async {
      Object? thrown;

      try {
        await _client().rpc(
          'complete_patient_registration',
          params: {
            'p_user_id': '00000000-0000-0000-0000-000000000000',
            'p_email': 'phase1-rpc-check@invalid.local',
            'p_full_name': 'Phase 1 RPC Check',
            'p_doctor_code': 'INVALID',
          },
        );
      } catch (error) {
        thrown = error;
      }

      expect(thrown, isNotNull);
      expect(thrown.toString(), contains('Unauthorized registration request'));
    });

    final doctorEmail = _env('MEDTRACE_DOCTOR_EMAIL');
    final doctorPassword = _env('MEDTRACE_DOCTOR_PASSWORD');
    final patientEmail = _env('MEDTRACE_PATIENT_EMAIL');
    final patientPassword = _env('MEDTRACE_PATIENT_PASSWORD');

    final hasDoctorCredentials =
        doctorEmail.isNotEmpty && doctorPassword.isNotEmpty;
    final hasPatientCredentials =
        patientEmail.isNotEmpty && patientPassword.isNotEmpty;

    test(
      'real doctor account signs in and has doctor role',
      () async {
        final client = _client();
        final auth = await client.auth.signInWithPassword(
          email: doctorEmail,
          password: doctorPassword,
        );

        final userId = auth.user?.id;
        expect(userId, isNotNull);

        final profile = await client
            .from('profiles')
            .select('id, role')
            .eq('id', userId!)
            .single();

        expect(profile['role'], equals('doctor'));
      },
      skip: hasDoctorCredentials
          ? false
          : 'Set MEDTRACE_DOCTOR_EMAIL and MEDTRACE_DOCTOR_PASSWORD for real Supabase auth verification.',
    );

    test(
      'real patient account signs in and has patient role',
      () async {
        final client = _client();
        final auth = await client.auth.signInWithPassword(
          email: patientEmail,
          password: patientPassword,
        );

        final userId = auth.user?.id;
        expect(userId, isNotNull);

        final profile = await client
            .from('profiles')
            .select('id, role')
            .eq('id', userId!)
            .single();

        expect(profile['role'], equals('patient'));
      },
      skip: hasPatientCredentials
          ? false
          : 'Set MEDTRACE_PATIENT_EMAIL and MEDTRACE_PATIENT_PASSWORD for real Supabase auth verification.',
    );

    test(
      'RLS prevents patient account from reading all profiles',
      () async {
        final client = _client();
        final auth = await client.auth.signInWithPassword(
          email: patientEmail,
          password: patientPassword,
        );
        final userId = auth.user!.id;

        final profiles = await client.from('profiles').select('id, role');
        final ids = profiles
            .cast<Map<String, dynamic>>()
            .map((profile) => profile['id'] as String)
            .toSet();

        expect(ids, contains(userId));
        expect(
          profiles.length,
          lessThanOrEqualTo(2),
          reason:
              'A patient should only see their own profile and, if assigned, their doctor profile.',
        );
      },
      skip: hasPatientCredentials
          ? false
          : 'Set MEDTRACE_PATIENT_EMAIL and MEDTRACE_PATIENT_PASSWORD for real Supabase RLS verification.',
    );
  });
}
