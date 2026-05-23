import 'package:flutter_test/flutter_test.dart';
import 'package:medtrace/core/error/exceptions.dart';
import 'package:medtrace/core/error/auth_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapAuthErrorMessage', () {
    test('maps unconfirmed email errors to an actionable message', () {
      final message = mapAuthErrorMessage(
        AuthApiException(
          'Email not confirmed',
          statusCode: '400',
          code: 'email_not_confirmed',
        ),
      );

      expect(message, contains('Email belum dikonfirmasi'));
      expect(message, isNot(contains('AuthApiException')));
    });

    test('maps invalid credentials to a short login message', () {
      final message = mapAuthErrorMessage(
        AuthApiException(
          'Invalid login credentials',
          statusCode: '400',
          code: 'invalid_credentials',
        ),
      );

      expect(message, 'Email atau password salah.');
    });

    test('maps invalid doctor code errors to a registration message', () {
      final message = mapAuthErrorMessage(
        InvalidDoctorCodeException(message: 'Invalid or expired doctor code'),
      );

      expect(message, contains('Kode dokter tidak valid'));
    });
  });
}
