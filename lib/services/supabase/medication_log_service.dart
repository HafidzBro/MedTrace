import 'package:medtrace/data/models/medication_log_model.dart';
import 'package:medtrace/services/supabase/patient_service.dart';
import 'package:medtrace/services/supabase/supabase_service_context.dart';

class MedicationLogService {
  final SupabaseServiceContext context;
  final PatientService patients;

  const MedicationLogService(this.context, this.patients);

  Future<MedicationLogModel> create({
    required String patientId,
    required String therapyId,
    String? therapyPhaseId,
    required DateTime scheduledAt,
    String status = 'pending',
  }) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final response = await context.client
        .from('medication_logs')
        .insert({
          'patient_id': resolvedPatientId,
          'therapy_id': therapyId,
          'therapy_phase_id': therapyPhaseId,
          'scheduled_at': scheduledAt.toIso8601String(),
          'taken_at':
              status == 'taken' ? DateTime.now().toIso8601String() : null,
          'status': status,
        })
        .select()
        .single();

    return MedicationLogModel.fromJson(response);
  }

  Future<List<MedicationLogModel>> listForPatient(String patientId) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final response = await context.client
        .from('medication_logs')
        .select()
        .eq('patient_id', resolvedPatientId)
        .order('scheduled_at', ascending: false);

    return (response as List)
        .map((row) => MedicationLogModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<MedicationLogModel>> listForTherapy(String therapyId) async {
    final response = await context.client
        .from('medication_logs')
        .select()
        .eq('therapy_id', therapyId)
        .order('scheduled_at', ascending: false);

    return (response as List)
        .map((row) => MedicationLogModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<MedicationLogModel> updateStatus({
    required String medicationLogId,
    required String status,
  }) async {
    final response = await context.client
        .from('medication_logs')
        .update({
          'status': status,
          'taken_at':
              status == 'taken' ? DateTime.now().toIso8601String() : null,
        })
        .eq('medication_log_id', medicationLogId)
        .select()
        .single();

    return MedicationLogModel.fromJson(response);
  }
}
