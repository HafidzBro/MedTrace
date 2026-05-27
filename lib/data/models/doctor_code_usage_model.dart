import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class DoctorCodeUsageModel extends Equatable {
  final String usageId;
  final String codeId;
  final String patientId;
  final DateTime usedAt;

  const DoctorCodeUsageModel({
    required this.usageId,
    required this.codeId,
    required this.patientId,
    required this.usedAt,
  });

  factory DoctorCodeUsageModel.fromJson(Map<String, dynamic> json) {
    return DoctorCodeUsageModel(
      usageId: json['usage_id'] ?? json['id'] ?? '',
      codeId: json['code_id'] ?? '',
      patientId: json['patient_id'] ?? '',
      usedAt: parseDateTime(json['used_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'usage_id': usageId,
        'code_id': codeId,
        'patient_id': patientId,
        'used_at': usedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [usageId, codeId, patientId, usedAt];
}
