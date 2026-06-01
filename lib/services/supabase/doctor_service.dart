import 'package:medtrace/core/error/exceptions.dart';
import 'package:medtrace/data/models/doctor_code_model.dart';
import 'package:medtrace/data/models/doctor_model.dart';
import 'package:medtrace/data/models/profile_model.dart';
import 'package:medtrace/services/supabase/profile_service.dart';
import 'package:medtrace/services/supabase/supabase_service_context.dart';

class DoctorService {
  final SupabaseServiceContext context;
  final ProfileService profiles;

  const DoctorService(this.context, this.profiles);

  Future<String> resolveDoctorId(String idOrAuthUserId) async {
    final direct = await context.client
        .from('doctors')
        .select('doctor_id')
        .eq('doctor_id', idOrAuthUserId)
        .maybeSingle();
    if (direct != null) return direct['doctor_id'] as String;

    final byUser = await context.client
        .from('doctors')
        .select('doctor_id, profiles!inner(user_id)')
        .eq('profiles.user_id', idOrAuthUserId)
        .maybeSingle();
    if (byUser != null) return byUser['doctor_id'] as String;

    final byProfile = await context.client
        .from('doctors')
        .select('doctor_id')
        .eq('profile_id', idOrAuthUserId)
        .maybeSingle();
    if (byProfile != null) return byProfile['doctor_id'] as String;

    throw NotFoundException(message: 'Doctor profile not found');
  }

  Future<DoctorModel?> getByAuthUserId(String authUserId) async {
    final response = await context.client
        .from('doctors')
        .select()
        .eq('profile_id', authUserId)
        .maybeSingle();
    if (response != null) return DoctorModel.fromJson(response);

    final byUser = await context.client
        .from('doctors')
        .select(
            'doctor_id, profile_id, facility_name, created_at, updated_at, profiles!inner(user_id)')
        .eq('profiles.user_id', authUserId)
        .maybeSingle();
    if (byUser == null) return null;
    return DoctorModel.fromJson(byUser);
  }

  Future<String> generateCode({
    required String doctorId,
    int maxUses = 1,
    int expiryDays = 30,
  }) async {
    final resolvedDoctorId = await resolveDoctorId(doctorId);
    final code = context.generateCode();
    final expiresAt = DateTime.now().add(Duration(days: expiryDays));

    await context.client.from('doctor_codes').insert({
      'doctor_id': resolvedDoctorId,
      'code': code,
      'max_uses': maxUses,
      'expires_at': expiresAt.toIso8601String(),
    });

    return code;
  }

  Future<DoctorCodeModel> validateCode(String code) async {
    final response = await context.client
        .from('doctor_codes')
        .select()
        .eq('code', code.toUpperCase())
        .maybeSingle();

    if (response == null) {
      throw InvalidDoctorCodeException(
          message: 'Invalid or expired doctor code');
    }

    final doctorCode = DoctorCodeModel.fromJson(response);
    if (!doctorCode.canBeUsed) {
      throw InvalidDoctorCodeException(
          message: 'Invalid or expired doctor code');
    }

    return doctorCode;
  }

  Future<List<UserModel>> getPatients(String doctorId) async {
    final resolvedDoctorId = await resolveDoctorId(doctorId);
    final response = await context.client
        .from('patients')
        .select('profiles(*)')
        .eq('doctor_id', resolvedDoctorId)
        .order('created_at', ascending: false);

    return (response as List).map((row) {
      final data = row as Map<String, dynamic>;
      return UserModel.fromJson(data['profiles'] as Map<String, dynamic>);
    }).toList();
  }

  Future<UserModel?> getDoctorForPatient(String patientIdOrAuthUserId) async {
    final patient = await _resolvePatientRow(patientIdOrAuthUserId);
    if (patient == null) return null;

    final doctorId = patient['doctor_id'] as String?;
    if (doctorId == null || doctorId.isEmpty) return null;

    final doctor = await context.client
        .from('doctors')
        .select('profile_id, profiles(*)')
        .eq('doctor_id', doctorId)
        .maybeSingle();
    if (doctor == null) return null;

    final nestedProfile = doctor['profiles'];
    if (nestedProfile is Map<String, dynamic>) {
      return UserModel.fromJson(nestedProfile);
    }

    final profileId = doctor['profile_id'] as String?;
    if (profileId == null || profileId.isEmpty) return null;
    return profiles.getByProfileId(profileId);
  }

  Future<String?> getFacilityForPatient(String patientIdOrAuthUserId) async {
    final patient = await _resolvePatientRow(patientIdOrAuthUserId);
    if (patient == null) return null;

    final doctorId = patient['doctor_id'] as String?;
    if (doctorId == null || doctorId.isEmpty) return null;

    final doctor = await context.client
        .from('doctors')
        .select('facility_name')
        .eq('doctor_id', doctorId)
        .maybeSingle();

    return doctor?['facility_name'] as String?;
  }

  Future<Map<String, dynamic>?> _resolvePatientRow(
      String idOrAuthUserId) async {
    final direct = await context.client
        .from('patients')
        .select()
        .eq('patient_id', idOrAuthUserId)
        .maybeSingle();
    if (direct != null) return direct;

    final byUser = await context.client
        .from('patients')
        .select('*, profiles!inner(user_id)')
        .eq('profiles.user_id', idOrAuthUserId)
        .maybeSingle();
    return byUser;
  }
}
