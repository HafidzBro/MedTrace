import 'package:medtrace/core/error/exceptions.dart';
import 'package:medtrace/data/models/patient_model.dart';
import 'package:medtrace/data/models/profile_model.dart';
import 'package:medtrace/services/supabase/doctor_service.dart';
import 'package:medtrace/services/supabase/supabase_service_context.dart';

class PatientService {
  final SupabaseServiceContext context;
  final DoctorService doctors;

  const PatientService(this.context, this.doctors);

  Future<String> resolvePatientId(String idOrAuthUserId) async {
    final direct = await context.client
        .from('patients')
        .select('patient_id')
        .eq('patient_id', idOrAuthUserId)
        .maybeSingle();
    if (direct != null) return direct['patient_id'] as String;

    final byUser = await context.client
        .from('patients')
        .select('patient_id, profiles!inner(user_id)')
        .eq('profiles.user_id', idOrAuthUserId)
        .maybeSingle();
    if (byUser != null) return byUser['patient_id'] as String;

    final byProfile = await context.client
        .from('patients')
        .select('patient_id')
        .eq('profile_id', idOrAuthUserId)
        .maybeSingle();
    if (byProfile != null) return byProfile['patient_id'] as String;

    throw NotFoundException(message: 'Patient profile not found');
  }

  Future<PatientModel> getById(String patientId) async {
    final resolvedPatientId = await resolvePatientId(patientId);
    final response = await context.client
        .from('patients')
        .select()
        .eq('patient_id', resolvedPatientId)
        .single();

    return PatientModel.fromJson(response);
  }

  Future<UserModel> getProfile(String patientId) async {
    final resolvedPatientId = await resolvePatientId(patientId);
    final response = await context.client
        .from('patients')
        .select('profiles(*)')
        .eq('patient_id', resolvedPatientId)
        .single();

    return UserModel.fromJson(response['profiles'] as Map<String, dynamic>);
  }

  Future<List<UserModel>> listForDoctor(String doctorId) async {
    return doctors.getPatients(doctorId);
  }

  Future<PatientModel> updatePatient({
    required String patientId,
    String? nik,
    String? gender,
    DateTime? birthDate,
    String? address,
  }) async {
    final resolvedPatientId = await resolvePatientId(patientId);
    final data = <String, dynamic>{};
    if (nik != null) data['nik'] = nik;
    if (gender != null) data['gender'] = gender;
    if (birthDate != null) data['birth_date'] = context.toDateOnly(birthDate);
    if (address != null) data['address'] = address;

    final response = await context.client
        .from('patients')
        .update(data)
        .eq('patient_id', resolvedPatientId)
        .select()
        .single();

    return PatientModel.fromJson(response);
  }
}
