import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class PhaseMedicationModel extends Equatable {
  final String phaseMedicationId;
  final String phaseId;
  final String medicationId;
  final double? dosage;
  final String? unit;
  final DateTime createdAt;

  const PhaseMedicationModel({
    required this.phaseMedicationId,
    required this.phaseId,
    required this.medicationId,
    this.dosage,
    this.unit,
    required this.createdAt,
  });

  factory PhaseMedicationModel.fromJson(Map<String, dynamic> json) {
    return PhaseMedicationModel(
      phaseMedicationId: json['phase_medication_id'] ?? json['id'] ?? '',
      phaseId: json['phase_id'] ?? '',
      medicationId: json['medication_id'] ?? '',
      dosage: json['dosage'] == null ? null : parseDouble(json['dosage']),
      unit: json['unit'],
      createdAt: parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'phase_medication_id': phaseMedicationId,
        'phase_id': phaseId,
        'medication_id': medicationId,
        'dosage': dosage,
        'unit': unit,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [phaseMedicationId, phaseId, medicationId, dosage, unit, createdAt];
}
