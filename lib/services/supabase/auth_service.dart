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
    String? phoneNumber,
    String? gender,
    String? address,
  }) async {
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
      phoneNumber: phoneNumber,
      gender: gender,
      address: address,
    );
  }

  Future<UserModel> completePatientRegistrationAfterVerification({
    required String userId,
    required String email,
    required String fullName,
    required String doctorCode,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? gender,
    String? address,
  }) async {
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

    return profiles.getByAuthUserId(userId);
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
