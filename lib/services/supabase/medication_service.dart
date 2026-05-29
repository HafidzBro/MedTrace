import 'package:medtrace/data/models/medication_model.dart';
import 'package:medtrace/data/models/medication_log_model.dart';
import 'package:medtrace/data/models/model_utils.dart';
import 'package:medtrace/data/models/phase_medication_model.dart';
import 'package:medtrace/data/models/therapy_model.dart';
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

  Future<MedicationIntakePlan?> currentIntakePlan(
      TreatmentModel therapy) async {
    final response = await context.client
        .from('therapy_phases')
        .select('*, phase_medication(*, medication(*))')
        .eq('therapy_id', therapy.id)
        .order('phase_order', ascending: true);

    final phases =
        (response as List).map((row) => row as Map<String, dynamic>).toList();
    if (phases.isEmpty) return null;

    final currentPhase = _currentPhaseForTherapy(therapy, phases);
    final phaseMedicationRows =
        (currentPhase['phase_medication'] as List? ?? const [])
            .map((row) => row as Map<String, dynamic>)
            .toList();

    return MedicationIntakePlan(
      phaseId: currentPhase['therapy_phase_id'] as String,
      phaseName: currentPhase['phase_name'] ?? 'Treatment Phase',
      startMonth: currentPhase['start_month'] as int?,
      endMonth: currentPhase['end_month'] as int?,
      intakeTime: currentPhase['intake_time'] == null
          ? null
          : parseTime(currentPhase['intake_time']),
      instructions: currentPhase['instructions'],
      items: phaseMedicationRows.map(_intakeItemFromRow).toList(),
    );
  }

  Map<String, dynamic> _currentPhaseForTherapy(
    TreatmentModel therapy,
    List<Map<String, dynamic>> phases,
  ) {
    final now = DateTime.now();
    final monthOnTherapy = (now.difference(therapy.startDate).inDays ~/ 30) + 1;

    for (final phase in phases) {
      final startDate = parseNullableDateTime(phase['start_date']);
      final endDate = parseNullableDateTime(phase['end_date']);
      if (startDate != null &&
          endDate != null &&
          !now.isBefore(startDate) &&
          now.isBefore(endDate.add(const Duration(days: 1)))) {
        return phase;
      }
    }

    for (final phase in phases) {
      final startMonth = phase['start_month'] as int?;
      final endMonth = phase['end_month'] as int?;
      if (startMonth != null &&
          endMonth != null &&
          monthOnTherapy >= startMonth &&
          monthOnTherapy <= endMonth) {
        return phase;
      }
    }

    return phases.firstWhere(
      (phase) => phase['status'] == 'active',
      orElse: () => phases.first,
    );
  }

  MedicationIntakeItem _intakeItemFromRow(Map<String, dynamic> row) {
    final medication = row['medication'] as Map<String, dynamic>?;
    return MedicationIntakeItem(
      medicationName: medication?['name'] ?? 'Medication',
      abbreviation: medication?['abbreviation'],
      description: medication?['description'],
      dosage: row['dosage'] == null ? null : parseDouble(row['dosage']),
      unit: row['unit'],
    );
  }
}

class MedicationIntakePlan {
  final String phaseId;
  final String phaseName;
  final int? startMonth;
  final int? endMonth;
  final DateTime? intakeTime;
  final String? instructions;
  final List<MedicationIntakeItem> items;
  final MedicationLogModel? todayLog;

  const MedicationIntakePlan({
    required this.phaseId,
    required this.phaseName,
    this.startMonth,
    this.endMonth,
    this.intakeTime,
    this.instructions,
    required this.items,
    this.todayLog,
  });

  String get medicationLabel {
    if (items.isEmpty) return 'Medication';
    return items
        .map((item) => item.abbreviation ?? item.medicationName)
        .join(' & ');
  }

  String get dosageLabel {
    final parts = items
        .map((item) => item.dosageLabel)
        .where((label) => label.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Dose configured by your doctor';
    return parts.join(' + ');
  }

  String get instructionLabel => instructions?.trim().isNotEmpty == true
      ? instructions!.trim()
      : 'Take with food, ideally with a glass of water.';

  String get monthRangeLabel {
    if (startMonth != null && endMonth != null) {
      return '$startMonth - $endMonth Months';
    }
    return 'Treatment Phase';
  }

  bool get isTakenToday => todayLog?.isTaken ?? false;
  bool get canConfirmToday => todayLog == null || todayLog!.isPending;
}

class MedicationIntakeItem {
  final String medicationName;
  final String? abbreviation;
  final String? description;
  final double? dosage;
  final String? unit;

  const MedicationIntakeItem({
    required this.medicationName,
    this.abbreviation,
    this.description,
    this.dosage,
    this.unit,
  });

  String get dosageLabel {
    if (dosage == null && (unit == null || unit!.isEmpty)) return '';
    final normalizedDose = dosage == null
        ? ''
        : dosage! % 1 == 0
            ? dosage!.toStringAsFixed(0)
            : dosage!.toString();
    return '$normalizedDose${unit ?? ''}';
  }
}
