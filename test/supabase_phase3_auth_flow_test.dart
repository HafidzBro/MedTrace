import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medtrace/core/config/app_config.dart';
import 'package:medtrace/core/error/auth_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String _env(String name) => Platform.environment[name] ?? '';

SupabaseClient _client() {
  final url = _env('MEDTRACE_SUPABASE_URL').isNotEmpty
      ? _env('MEDTRACE_SUPABASE_URL')
      : AppConfig.supabaseUrl;
  final anonKey = _env('MEDTRACE_SUPABASE_ANON_KEY').isNotEmpty
      ? _env('MEDTRACE_SUPABASE_ANON_KEY')
      : AppConfig.supabaseAnonKey;

  return SupabaseClient(
    url,
    anonKey,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
}

void main() {
  group('Supabase Phase 3 real auth flow checks', () {
    test('invalid login returns a useful user-facing error', () async {
      Object? thrown;

      try {
        await _client().auth.signInWithPassword(
              email: 'medtrace-invalid-login@invalid.local',
              password: 'not-a-real-password',
            );
      } catch (error) {
        thrown = error;
      }

      expect(thrown, isNotNull);
      expect(
        mapAuthErrorMessage(thrown!),
        anyOf(
          equals('Email atau password salah.'),
          contains('Email atau password'),
        ),
      );
    });

    final doctorEmail = _env('MEDTRACE_DOCTOR_EMAIL');
    final doctorPassword = _env('MEDTRACE_DOCTOR_PASSWORD');
    final patientEmail = _env('MEDTRACE_PATIENT_EMAIL');
    final patientPassword = _env('MEDTRACE_PATIENT_PASSWORD');
    final activeDoctorCode = _env('MEDTRACE_ACTIVE_DOCTOR_CODE');

    final hasDoctorCredentials =
        doctorEmail.isNotEmpty && doctorPassword.isNotEmpty;
    final hasPatientCredentials =
        patientEmail.isNotEmpty && patientPassword.isNotEmpty;

    test(
      'real doctor login resolves to doctor role',
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

        expect(profile['role'], 'doctor');
      },
      skip: hasDoctorCredentials
          ? false
          : 'Set MEDTRACE_DOCTOR_EMAIL and MEDTRACE_DOCTOR_PASSWORD for real doctor login verification.',
    );

    test(
      'real patient login resolves to patient role',
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

        expect(profile['role'], 'patient');
      },
      skip: hasPatientCredentials
          ? false
          : 'Set MEDTRACE_PATIENT_EMAIL and MEDTRACE_PATIENT_PASSWORD for real patient login verification.',
    );

    test(
      'active doctor code is readable and can be used for registration',
      () async {
        final code = await _client()
            .from('doctor_codes')
            .select('code, is_active, current_uses, max_uses, expires_at')
            .eq('code', activeDoctorCode.toUpperCase())
            .single();

        expect(code['is_active'], true);
        expect(code['current_uses'] as int, lessThan(code['max_uses'] as int));
        expect(
            DateTime.parse(code['expires_at'] as String)
                .isAfter(DateTime.now()),
            true);
      },
      skip: activeDoctorCode.isNotEmpty
          ? false
          : 'Set MEDTRACE_ACTIVE_DOCTOR_CODE for real doctor-code verification.',
    );
  });
}
