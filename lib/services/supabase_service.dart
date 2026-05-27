import 'package:logger/logger.dart';
import 'package:medtrace/core/error/exceptions.dart';
import 'package:medtrace/data/models/doctor_code_model.dart';
import 'package:medtrace/data/models/profile_model.dart';
import 'package:medtrace/data/models/therapy_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client;
  final Logger logger = Logger();

  SupabaseService({required this.client});

  // ============================================================
  // AUTH SERVICE
  // ============================================================

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
    try {
      final normalizedDoctorCode = doctorCode.toUpperCase();

      // Step 1: Validate doctor code
      final response = await client
          .from('doctor_codes')
          .select()
          .eq('code', normalizedDoctorCode)
          .maybeSingle();

      if (response == null) {
        throw InvalidDoctorCodeException(
          message: 'Invalid or expired doctor code',
        );
      }

      final code = DoctorCodeModel.fromJson(response);
      if (!code.canBeUsed) {
        throw InvalidDoctorCodeException(
          message: 'Doctor code has expired or exceeded maximum uses',
        );
      }

      if (client.auth.currentUser != null) {
        await client.auth.signOut();
      }

      // Step 2: Register user with Supabase Auth
      final authResponse = await client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (authResponse.user == null) {
        throw AuthenticationException(message: 'Registration failed');
      }

      final userId = authResponse.user!.id;

      if (authResponse.session == null ||
          client.auth.currentUser?.id != userId) {
        throw EmailVerificationRequiredException(
          email: email.trim().toLowerCase(),
        );
      }

      return completePatientRegistrationAfterVerification(
        userId: userId,
        email: email,
        fullName: fullName,
        doctorCode: code.code,
        dateOfBirth: dateOfBirth,
        phoneNumber: phoneNumber,
        gender: gender,
        address: address,
      );
    } catch (e) {
      logger.e('Patient registration error', error: e);
      rethrow;
    }
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
    try {
      final profile = await client.rpc(
        'complete_patient_registration',
        params: {
          'p_user_id': userId,
          'p_email': email.trim().toLowerCase(),
          'p_full_name': fullName,
          'p_doctor_code': doctorCode.toUpperCase(),
        },
      ).single();

      final profileUpdates = <String, dynamic>{};
      if (dateOfBirth != null) {
        profileUpdates['date_of_birth'] = _toDateOnly(dateOfBirth);
      }
      if (phoneNumber?.trim().isNotEmpty == true) {
        profileUpdates['phone_number'] = phoneNumber!.trim();
      }
      if (gender?.trim().isNotEmpty == true) {
        profileUpdates['gender'] = gender!.trim();
      }

      if (profileUpdates.isNotEmpty) {
        await client.from('profiles').update(profileUpdates).eq('id', userId);
      }

      final patientUpdates = <String, dynamic>{};
      if (phoneNumber?.trim().isNotEmpty == true) {
        patientUpdates['phone_number'] = phoneNumber!.trim();
      }
      if (address?.trim().isNotEmpty == true) {
        patientUpdates['address'] = address!.trim();
      }

      if (patientUpdates.isNotEmpty) {
        await client.from('patients').update(patientUpdates).eq('id', userId);
      }

      if (profileUpdates.isEmpty) {
        return UserModel.fromJson(profile);
      }
      return await getUser(userId);
    } catch (e) {
      logger.e('Complete patient registration error', error: e);
      rethrow;
    }
  }

  Future<void> resendPatientVerificationEmail(String email) async {
    try {
      await client.auth.resend(
        type: OtpType.signup,
        email: email.trim().toLowerCase(),
      );
    } catch (e) {
      logger.e('Resend verification email error', error: e);
      rethrow;
    }
  }

  Future<UserModel> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AuthenticationException(
          message: 'Login failed. Invalid credentials.',
        );
      }

      return await getUser(response.user!.id);
    } catch (e) {
      logger.e('Login error', error: e);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      logger.e('Logout error', error: e);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
    } catch (e) {
      logger.e('Password reset error', error: e);
      rethrow;
    }
  }

  // ============================================================
  // USER SERVICE
  // ============================================================

  Future<UserModel> getUser(String userId) async {
    try {
      final response =
          await client.from('profiles').select().eq('id', userId).single();

      return UserModel.fromJson(response);
    } catch (e) {
      logger.e('Get user error', error: e);
      rethrow;
    }
  }

  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
    String? country,
    String? city,
    String? gender,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (bio != null) updateData['bio'] = bio;
      if (country != null) updateData['country'] = country;
      if (city != null) updateData['city'] = city;
      if (gender != null) updateData['gender'] = gender;

      await client.from('profiles').update(updateData).eq('id', userId);

      return await getUser(userId);
    } catch (e) {
      logger.e('Update profile error', error: e);
      rethrow;
    }
  }

  // ============================================================
  // DOCTOR CODE SERVICE
  // ============================================================

  Future<String> generateDoctorCode({
    required String doctorId,
    int maxUses = 1,
    int expiryDays = 30,
  }) async {
    try {
      final code = _generateRandomCode();
      final expiresAt = DateTime.now().add(Duration(days: expiryDays));

      await client.from('doctor_codes').insert({
        'doctor_id': doctorId,
        'code': code,
        'max_uses': maxUses,
        'expires_at': expiresAt.toIso8601String(),
      });

      return code;
    } catch (e) {
      logger.e('Generate doctor code error', error: e);
      rethrow;
    }
  }

  Future<DoctorCodeModel> validateDoctorCode(String code) async {
    try {
      final response = await client
          .from('doctor_codes')
          .select()
          .eq('code', code.toUpperCase())
          .maybeSingle();

      if (response == null) {
        throw InvalidDoctorCodeException(
          message: 'Invalid or expired doctor code',
        );
      }

      return DoctorCodeModel.fromJson(response);
    } catch (e) {
      logger.e('Validate doctor code error', error: e);
      throw InvalidDoctorCodeException(
        message: 'Invalid or expired doctor code',
      );
    }
  }

  // ============================================================
  // DOCTOR-PATIENT SERVICE
  // ============================================================

  Future<List<UserModel>> getMyPatients(String doctorId) async {
    try {
      final response = await client
          .from('doctor_patients')
          .select('patient_id')
          .eq('doctor_id', doctorId);

      final patientIds =
          (response as List).map((e) => e['patient_id'] as String).toList();

      if (patientIds.isEmpty) return [];

      final patients = await client
          .from('profiles')
          .select()
          .filter('id', 'in', '(${patientIds.join(',')})');

      return (patients as List).map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      logger.e('Get my patients error', error: e);
      rethrow;
    }
  }

  Future<UserModel?> getMyDoctor(String patientId) async {
    try {
      final response = await client
          .from('doctor_patients')
          .select('doctor_id')
          .eq('patient_id', patientId)
          .maybeSingle();

      if (response == null) return null;

      final doctorId = response['doctor_id'];
      final doctor =
          await client.from('profiles').select().eq('id', doctorId).single();

      return UserModel.fromJson(doctor);
    } catch (e) {
      logger.e('Get my doctor error', error: e);
      return null;
    }
  }

  // ============================================================
  // TREATMENT SERVICE
  // ============================================================

  Future<TreatmentModel> createTreatment({
    required String patientId,
    required String doctorId,
    required DateTime diagnosisDate,
    required DateTime startDate,
    String phase = 'intensive',
  }) async {
    try {
      final response = await client
          .from('treatments')
          .insert({
            'patient_id': patientId,
            'doctor_id': doctorId,
            'diagnosis_date': diagnosisDate.toIso8601String(),
            'start_date': startDate.toIso8601String(),
            'phase': phase,
            'status': 'ongoing',
            'adherence_percentage': 0.0,
          })
          .select()
          .single();

      return TreatmentModel.fromJson(response);
    } catch (e) {
      logger.e('Create treatment error', error: e);
      rethrow;
    }
  }

  Future<TreatmentModel?> getPatientTreatment(String patientId) async {
    try {
      final response = await client
          .from('treatments')
          .select()
          .eq('patient_id', patientId)
          .eq('status', 'ongoing')
          .order('created_at', ascending: false)
          .maybeSingle();

      if (response == null) return null;
      return TreatmentModel.fromJson(response);
    } catch (e) {
      logger.e('Get patient treatment error', error: e);
      return null;
    }
  }

  Future<List<TreatmentModel>> getDoctorPatientsTreatments(
    String doctorId,
  ) async {
    try {
      final response = await client
          .from('treatments')
          .select()
          .eq('doctor_id', doctorId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => TreatmentModel.fromJson(e)).toList();
    } catch (e) {
      logger.e('Get doctor patients treatments error', error: e);
      rethrow;
    }
  }

  Future<TreatmentModel> updateTreatment({
    required String treatmentId,
    String? phase,
    String? status,
    double? adherencePercentage,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (phase != null) updateData['phase'] = phase;
      if (status != null) updateData['status'] = status;
      if (adherencePercentage != null) {
        updateData['adherence_percentage'] = adherencePercentage;
      }
      if (notes != null) updateData['notes'] = notes;

      final response = await client
          .from('treatments')
          .update(updateData)
          .eq('id', treatmentId)
          .select()
          .single();

      return TreatmentModel.fromJson(response);
    } catch (e) {
      logger.e('Update treatment error', error: e);
      rethrow;
    }
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().microsecond;
    String code = '';
    for (var i = 0; i < 6; i++) {
      code += chars[(random + i) % chars.length];
    }
    return code;
  }

  String _toDateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
