import 'package:medtrace/data/models/tb_case_model.dart';
import 'package:medtrace/services/supabase/patient_service.dart';
import 'package:medtrace/services/supabase/supabase_service_context.dart';

class TbCaseService {
  final SupabaseServiceContext context;
  final PatientService patients;

  const TbCaseService(this.context, this.patients);

  Future<TbCaseModel> create({
    required String patientId,
    required DateTime diagnosisDate,
    String? tbCategory,
    String? tbType,
    String? description,
  }) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final response = await context.client
        .from('tb_cases')
        .insert({
          'patient_id': resolvedPatientId,
          'diagnosis_date': context.toDateOnly(diagnosisDate),
          'tb_category': tbCategory,
          'tb_type': tbType,
          'description': description,
        })
        .select()
        .single();

    return TbCaseModel.fromJson(response);
  }

  Future<List<TbCaseModel>> listForPatient(String patientId) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final response = await context.client
        .from('tb_cases')
        .select()
        .eq('patient_id', resolvedPatientId)
        .order('diagnosis_date', ascending: false);

    return (response as List)
        .map((row) => TbCaseModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
