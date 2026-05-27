import 'package:medtrace/data/models/patient_location_model.dart';
import 'package:medtrace/services/supabase/patient_service.dart';
import 'package:medtrace/services/supabase/supabase_service_context.dart';

class LocationService {
  final SupabaseServiceContext context;
  final PatientService patients;

  const LocationService(this.context, this.patients);

  Future<PatientLocationModel> record({
    required String patientId,
    required double latitude,
    required double longitude,
    String? address,
    bool isCurrent = true,
  }) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    if (isCurrent) {
      await context.client
          .from('patient_locations')
          .update({'is_current': false}).eq('patient_id', resolvedPatientId);
    }

    final response = await context.client
        .from('patient_locations')
        .insert({
          'patient_id': resolvedPatientId,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'is_current': isCurrent,
          'recorded_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return PatientLocationModel.fromJson(response);
  }

  Future<List<PatientLocationModel>> listForPatient(String patientId) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final response = await context.client
        .from('patient_locations')
        .select()
        .eq('patient_id', resolvedPatientId)
        .order('recorded_at', ascending: false);

    return (response as List)
        .map(
            (row) => PatientLocationModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<PatientLocationModel>> listForDoctor(String doctorId) async {
    final patientProfiles = await patients.listForDoctor(doctorId);
    if (patientProfiles.isEmpty) return [];

    final patientIds = <String>[];
    for (final profile in patientProfiles) {
      patientIds.add(await patients.resolvePatientId(profile.profileId));
    }

    final response = await context.client
        .from('patient_locations')
        .select()
        .filter('patient_id', 'in', '(${patientIds.join(',')})')
        .eq('is_current', true)
        .order('recorded_at', ascending: false);

    return (response as List)
        .map(
            (row) => PatientLocationModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
