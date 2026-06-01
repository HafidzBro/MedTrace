import 'package:medtrace/core/error/exceptions.dart';
import 'package:medtrace/data/models/profile_model.dart';
import 'package:medtrace/services/supabase/doctor_code_service.dart';
import 'package:medtrace/services/supabase/profile_service.dart';
import 'package:medtrace/services/supabase/supabase_service_context.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseServiceContext context;
  final ProfileService profiles;
  final DoctorCodeService doctorCodes;

  const AuthService(this.context, this.profiles, this.doctorCodes);

  Future<UserModel> registerPatient({
    required String email,
    required String password,
    required String doctorCode,
    required String fullName,
    DateTime? dateOfBirth,
    String? nik,
    DateTime? diagnosisDate,
    String? tbCaseCategory,
    String? tbCaseDescription,
    String? phoneNumber,
    String? gender,
    String? address,
    double? latitude,
    double? longitude,
    double? locationAccuracy,
  }) async {
    final _ = locationAccuracy;
    final normalizedEmail = email.trim().toLowerCase();
    final code = await doctorCodes.validate(doctorCode.trim().toUpperCase());

    if (context.client.auth.currentUser != null) {
      await context.client.auth.signOut();
    }

    final authResponse = await context.client.auth.signUp(
      email: normalizedEmail,
      password: password,
    );

    if (authResponse.user == null) {
      throw AuthenticationException(message: 'Registration failed');
    }

    final userId = authResponse.user!.id;
    if (authResponse.session == null ||
        context.client.auth.currentUser?.id != userId) {
      throw EmailVerificationRequiredException(email: normalizedEmail);
    }

    return completePatientRegistrationAfterVerification(
      userId: userId,
      email: normalizedEmail,
      fullName: fullName,
      doctorCode: code.code,
      dateOfBirth: dateOfBirth,
      nik: nik,
      diagnosisDate: diagnosisDate,
      tbCaseCategory: tbCaseCategory,
      tbCaseDescription: tbCaseDescription,
      phoneNumber: phoneNumber,
      gender: gender,
      address: address,
      latitude: latitude,
      longitude: longitude,
      locationAccuracy: locationAccuracy,
    );
  }

  Future<UserModel> completePatientRegistrationAfterVerification({
    required String userId,
    required String email,
    required String fullName,
    required String doctorCode,
    DateTime? dateOfBirth,
    String? nik,
    DateTime? diagnosisDate,
    String? tbCaseCategory,
    String? tbCaseDescription,
    String? phoneNumber,
    String? gender,
    String? address,
    double? latitude,
    double? longitude,
    double? locationAccuracy,
  }) async {
    final _ = locationAccuracy;
    final profile = await context.client.rpc(
      'complete_patient_registration',
      params: {
        'p_user_id': userId,
        'p_email': email.trim().toLowerCase(),
        'p_full_name': fullName,
        'p_doctor_code': doctorCode.trim().toUpperCase(),
      },
    ).single();

    final user = UserModel.fromJson(profile);

    final profileUpdates = <String, dynamic>{};
    if (phoneNumber?.trim().isNotEmpty == true) {
      profileUpdates['phone'] = phoneNumber!.trim();
    }
    if (profileUpdates.isNotEmpty) {
      await context.client
          .from('profiles')
          .update(profileUpdates)
          .eq('profile_id', user.profileId);
    }

    final patientUpdates = <String, dynamic>{};
    if (dateOfBirth != null) {
      patientUpdates['birth_date'] = context.toDateOnly(dateOfBirth);
    }
    if (nik?.trim().isNotEmpty == true) {
      patientUpdates['nik'] = nik!.trim();
    }
    if (gender?.trim().isNotEmpty == true) {
      patientUpdates['gender'] = gender!.trim();
    }
    if (address?.trim().isNotEmpty == true) {
      patientUpdates['address'] = address!.trim();
    }
    if (patientUpdates.isNotEmpty) {
      await context.client
          .from('patients')
          .update(patientUpdates)
          .eq('profile_id', user.profileId);
    }

    if (diagnosisDate != null || (latitude != null && longitude != null)) {
      final patient = await context.client
          .from('patients')
          .select('patient_id, patient_code')
          .eq('profile_id', user.profileId)
          .single();

      final patientId = patient['patient_id'] as String;
      if ((patient['patient_code'] as String?)?.trim().isNotEmpty != true) {
        await context.client
            .from('patients')
            .update({'patient_code': _generatePatientCode(patientId)}).eq(
                'patient_id', patientId);
      }

      if (diagnosisDate != null) {
        final tbCase = await context.client
            .from('tb_cases')
            .insert({
              'patient_id': patientId,
              'diagnosis_date': context.toDateOnly(diagnosisDate),
              'tb_category': tbCaseCategory,
              'description': tbCaseDescription?.trim().isEmpty == true
                  ? null
                  : tbCaseDescription?.trim(),
            })
            .select('tb_case_id')
            .single();

        await context.client.rpc(
          'create_default_patient_therapy',
          params: {
            'p_patient_id': patientId,
            'p_tb_case_id': tbCase['tb_case_id'],
            'p_description': tbCaseDescription?.trim().isEmpty == true
                ? null
                : tbCaseDescription?.trim(),
          },
        );
      }

      if (latitude != null && longitude != null) {
        await context.client.from('patient_locations').insert({
          'patient_id': patientId,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'is_current': true,
          'recorded_at': DateTime.now().toIso8601String(),
        });
      }
    }

    return profiles.getByAuthUserId(userId);
  }

  String _generatePatientCode(String patientId) {
    final compact = patientId.replaceAll('-', '').toUpperCase();
    return 'MT-${compact.substring(0, 4)}-${compact.substring(compact.length - 4)}';
  }

  Future<void> resendPatientVerificationEmail(String email) async {
    await context.client.auth.resend(
      type: OtpType.signup,
      email: email.trim().toLowerCase(),
    );
  }

  Future<UserModel> loginUser({
    required String email,
    required String password,
  }) async {
    final response = await context.client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    if (response.user == null) {
      throw AuthenticationException(
          message: 'Login failed. Invalid credentials.');
    }

    return profiles.getByAuthUserId(response.user!.id);
  }

  Future<void> logout() => context.client.auth.signOut();

  Future<void> resetPassword(String email) {
    return context.client.auth
        .resetPasswordForEmail(email.trim().toLowerCase());
  }
}
