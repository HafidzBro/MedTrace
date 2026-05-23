import 'package:medtrace/core/error/exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String mapAuthErrorMessage(Object error) {
  if (error is InvalidDoctorCodeException) {
    return 'Kode dokter tidak valid, sudah kedaluwarsa, atau sudah mencapai batas penggunaan.';
  }

  if (error is AuthenticationException) {
    return error.message;
  }

  if (error is AuthException) {
    final message = error.message.toLowerCase();

    if (error.statusCode == '400' && message.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Silakan cek inbox email pasien atau konfirmasi akun dari Supabase Auth.';
    }

    if (message.contains('invalid login credentials')) {
      return 'Email atau password salah.';
    }

    return error.message;
  }

  final text = error.toString();
  if (text.contains('email_not_confirmed') ||
      text.toLowerCase().contains('email not confirmed')) {
    return 'Email belum dikonfirmasi. Silakan cek inbox email pasien atau konfirmasi akun dari Supabase Auth.';
  }

  if (text.toLowerCase().contains('invalid or expired doctor code')) {
    return 'Kode dokter tidak valid, sudah kedaluwarsa, atau sudah mencapai batas penggunaan.';
  }

  return text;
}
