import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class MedicationModel extends Equatable {
  final String medicationId;
  final String? code;
  final String name;
  final String? abbreviation;
  final String? description;
  final DateTime createdAt;
  final String? treatmentId;
  final String? dosage;
  final String? unit;
  final String? frequency;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? instructions;

  const MedicationModel({
    required String id,
    this.code,
    required this.name,
    this.abbreviation,
    this.description,
    required this.createdAt,
    this.treatmentId,
    this.dosage,
    this.unit,
    this.frequency,
    this.startDate,
    this.endDate,
    this.instructions,
    DateTime? updatedAt,
  }) : medicationId = id;

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['medication_id'] ?? json['id'] ?? '',
      code: json['code'],
      name: json['name'] ?? '',
      abbreviation: json['abbreviation'],
      description: json['description'],
      createdAt: parseDateTime(json['created_at']),
      treatmentId: json['treatment_id'],
      dosage: json['dosage']?.toString(),
      unit: json['unit'],
      frequency: json['frequency'],
      startDate: parseNullableDateTime(json['start_date']),
      endDate: parseNullableDateTime(json['end_date']),
      instructions: json['instructions'],
    );
  }

  String get id => medicationId;
  DateTime get updatedAt => createdAt;
  bool get isActive =>
      startDate == null ||
      (DateTime.now().isAfter(startDate!) &&
          (endDate == null || DateTime.now().isBefore(endDate!)));

  Map<String, dynamic> toJson() => {
        'medication_id': medicationId,
        'code': code,
        'name': name,
        'abbreviation': abbreviation,
        'description': description,
        'created_at': createdAt.toIso8601String(),
        'treatment_id': treatmentId,
        'dosage': dosage,
        'unit': unit,
        'frequency': frequency,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'instructions': instructions,
      };

  @override
  List<Object?> get props => [
        medicationId,
        code,
        name,
        abbreviation,
        description,
        createdAt,
        treatmentId,
        dosage,
        unit,
        frequency,
        startDate,
        endDate,
        instructions,
      ];
}
