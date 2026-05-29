import 'package:medtrace/data/models/therapy_model.dart';
import 'package:medtrace/services/supabase/doctor_service.dart';
import 'package:medtrace/services/supabase/patient_service.dart';
import 'package:medtrace/services/supabase/supabase_service_context.dart';

class TherapyService {
  final SupabaseServiceContext context;
  final DoctorService doctors;
  final PatientService patients;

  const TherapyService(this.context, this.doctors, this.patients);

  Future<TreatmentModel> createTreatment({
    required String patientId,
    required String doctorId,
    required DateTime diagnosisDate,
    required DateTime startDate,
    String phase = 'intensive',
  }) async {
    final resolvedDoctorId = await doctors.resolveDoctorId(doctorId);
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final tbCase = await context.client
        .from('tb_cases')
        .insert({
          'patient_id': resolvedPatientId,
          'diagnosis_date': context.toDateOnly(diagnosisDate),
        })
        .select()
        .single();

    final response = await context.client
        .from('therapies')
        .insert({
          'tb_case_id': tbCase['tb_case_id'],
          'patient_id': resolvedPatientId,
          'doctor_id': resolvedDoctorId,
          'start_date': context.toDateOnly(startDate),
          'status': 'ongoing',
          'adherence_percentage': 0.0,
        })
        .select()
        .single();

    return TreatmentModel.fromJson({
      ...response,
      'diagnosis_date': diagnosisDate.toIso8601String(),
      'phase': phase
    });
  }

  Future<TreatmentModel?> getPatientTreatment(String patientId) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final response = await context.client
        .from('therapies')
        .select('*, tb_cases(diagnosis_date), therapy_phases(phase_name)')
        .eq('patient_id', resolvedPatientId)
        .inFilter('status', ['ongoing', 'on_treatment'])
        .order('created_at', ascending: false)
        .maybeSingle();

    if (response == null) return null;
    return _treatmentFromTherapyRow(response);
  }

  Future<List<TreatmentModel>> getDoctorPatientsTreatments(
      String doctorId) async {
    final resolvedDoctorId = await doctors.resolveDoctorId(doctorId);
    final response = await context.client
        .from('therapies')
        .select('*, tb_cases(diagnosis_date), therapy_phases(phase_name)')
        .eq('doctor_id', resolvedDoctorId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => _treatmentFromTherapyRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<TreatmentModel> updateTreatment({
    required String treatmentId,
    String? phase,
    String? status,
    double? adherencePercentage,
    String? notes,
  }) async {
    final data = <String, dynamic>{};
    if (status != null) data['status'] = status;
    if (adherencePercentage != null) {
      data['adherence_percentage'] = adherencePercentage;
    }
    if (notes != null) data['description'] = notes;

    final response = await context.client
        .from('therapies')
        .update(data)
        .eq('therapy_id', treatmentId)
        .select('*, tb_cases(diagnosis_date), therapy_phases(phase_name)')
        .single();

    return _treatmentFromTherapyRow(
        {...response, if (phase != null) 'phase': phase});
  }

  TreatmentModel _treatmentFromTherapyRow(Map<String, dynamic> row) {
    final tbCase = row['tb_cases'];
    final phases = row['therapy_phases'];
    String? phaseName = row['phase'];
    if (phaseName == null && phases is List && phases.isNotEmpty) {
      final phase = phases.first as Map<String, dynamic>;
      phaseName = phase['phase_name'];
    }

    return TreatmentModel.fromJson({
      ...row,
      'id': row['therapy_id'],
      'diagnosis_date': tbCase is Map<String, dynamic>
          ? tbCase['diagnosis_date']
          : DateTime.now().toIso8601String(),
      'phase': phaseName ?? 'intensive',
      'notes': row['description'],
    });
  }
}
