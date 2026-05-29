import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class TbCaseModel extends Equatable {
  final String tbCaseId;
  final String patientId;
  final DateTime diagnosisDate;
  final String? tbCategory;
  final String? tbType;
  final String? description;
  final DateTime createdAt;

  const TbCaseModel({
    required this.tbCaseId,
    required this.patientId,
    required this.diagnosisDate,
    this.tbCategory,
    this.tbType,
    this.description,
    required this.createdAt,
  });

  factory TbCaseModel.fromJson(Map<String, dynamic> json) => TbCaseModel(
        tbCaseId: json['tb_case_id'] ?? json['id'] ?? '',
        patientId: json['patient_id'] ?? '',
        diagnosisDate: parseDateTime(json['diagnosis_date']),
        tbCategory: json['tb_category'],
        tbType: json['tb_type'],
        description: json['description'],
        createdAt: parseDateTime(json['created_at']),
      );

  String get id => tbCaseId;

  Map<String, dynamic> toJson() => {
        'tb_case_id': tbCaseId,
        'patient_id': patientId,
        'diagnosis_date': diagnosisDate.toIso8601String(),
        'tb_category': tbCategory,
        'tb_type': tbType,
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        tbCaseId,
        patientId,
        diagnosisDate,
        tbCategory,
        tbType,
        description,
        createdAt,
      ];
}
