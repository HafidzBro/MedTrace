import 'package:medtrace/data/models/alert_model.dart';
import 'package:medtrace/services/supabase/patient_service.dart';
import 'package:medtrace/services/supabase/supabase_service_context.dart';

class AlertService {
  final SupabaseServiceContext context;
  final PatientService patients;

  const AlertService(this.context, this.patients);

  Future<AlertModel> create({
    required String patientId,
    String? therapyId,
    required String type,
    required String severity,
    String? description,
  }) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final response = await context.client
        .from('alerts')
        .insert({
          'patient_id': resolvedPatientId,
          'therapy_id': therapyId,
          'type': type,
          'severity': severity,
          'description': description,
        })
        .select()
        .single();

    return AlertModel.fromJson(response);
  }

  Future<List<AlertModel>> listForDoctor(String doctorId) async {
    final patientProfiles = await patients.listForDoctor(doctorId);
    if (patientProfiles.isEmpty) return [];

    final patientIds = <String>[];
    for (final profile in patientProfiles) {
      final patientId = await patients.resolvePatientId(profile.profileId);
      patientIds.add(patientId);
    }

    final response = await context.client
        .from('alerts')
        .select()
        .filter('patient_id', 'in', '(${patientIds.join(',')})')
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => AlertModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<AlertModel>> listForPatient(String patientId) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final response = await context.client
        .from('alerts')
        .select()
        .eq('patient_id', resolvedPatientId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => AlertModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
