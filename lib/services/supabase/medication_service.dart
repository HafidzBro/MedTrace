import 'package:medtrace/data/models/medication_model.dart';
import 'package:medtrace/data/models/phase_medication_model.dart';
import 'package:medtrace/services/supabase/supabase_service_context.dart';

class MedicationService {
  final SupabaseServiceContext context;

  const MedicationService(this.context);

  Future<List<MedicationModel>> listCatalog() async {
    final response = await context.client
        .from('medication')
        .select()
        .order('name', ascending: true);

    return (response as List)
        .map((row) => MedicationModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<MedicationModel> upsertCatalogItem({
    String? medicationId,
    String? code,
    required String name,
    String? abbreviation,
    String? description,
  }) async {
    final payload = {
      if (medicationId != null) 'medication_id': medicationId,
      'code': code,
      'name': name,
      'abbreviation': abbreviation,
      'description': description,
    };

    final response = await context.client
        .from('medication')
        .upsert(payload)
        .select()
        .single();

    return MedicationModel.fromJson(response);
  }

  Future<List<PhaseMedicationModel>> listForPhase(String phaseId) async {
    final response = await context.client
        .from('phase_medication')
        .select()
        .eq('phase_id', phaseId)
        .order('created_at', ascending: true);

    return (response as List)
        .map(
            (row) => PhaseMedicationModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<PhaseMedicationModel> addToPhase({
    required String phaseId,
    required String medicationId,
    double? dosage,
    String? unit,
  }) async {
    final response = await context.client
        .from('phase_medication')
        .insert({
          'phase_id': phaseId,
          'medication_id': medicationId,
          'dosage': dosage,
          'unit': unit,
        })
        .select()
        .single();

    return PhaseMedicationModel.fromJson(response);
  }
}
