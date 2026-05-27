import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class TherapyPhaseModel extends Equatable {
  final String therapyPhaseId;
  final String therapyId;
  final String phaseName;
  final int phaseOrder;
  final int? startMonth;
  final int? endMonth;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? frequency;
  final DateTime? intakeTime;
  final String? instructions;
  final String status;
  final DateTime createdAt;

  const TherapyPhaseModel({
    required this.therapyPhaseId,
    required this.therapyId,
    required this.phaseName,
    required this.phaseOrder,
    this.startMonth,
    this.endMonth,
    this.startDate,
    this.endDate,
    this.frequency,
    this.intakeTime,
    this.instructions,
    required this.status,
    required this.createdAt,
  });

  factory TherapyPhaseModel.fromJson(Map<String, dynamic> json) =>
      TherapyPhaseModel(
        therapyPhaseId:
            json['therapy_phase_id'] ?? json['phase_id'] ?? json['id'] ?? '',
        therapyId: json['therapy_id'] ?? '',
        phaseName: json['phase_name'] ?? '',
        phaseOrder: parseInt(json['phase_order']),
        startMonth:
            json['start_month'] == null ? null : parseInt(json['start_month']),
        endMonth:
            json['end_month'] == null ? null : parseInt(json['end_month']),
        startDate: parseNullableDateTime(json['start_date']),
        endDate: parseNullableDateTime(json['end_date']),
        frequency: json['frequency'],
        intakeTime:
            json['intake_time'] == null ? null : parseTime(json['intake_time']),
        instructions: json['instructions'],
        status: json['status'] ?? 'pending',
        createdAt: parseDateTime(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'therapy_phase_id': therapyPhaseId,
        'therapy_id': therapyId,
        'phase_name': phaseName,
        'phase_order': phaseOrder,
        'start_month': startMonth,
        'end_month': endMonth,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'frequency': frequency,
        'intake_time': timeToString(intakeTime),
        'instructions': instructions,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        therapyPhaseId,
        therapyId,
        phaseName,
        phaseOrder,
        startMonth,
        endMonth,
        startDate,
        endDate,
        frequency,
        intakeTime,
        instructions,
        status,
        createdAt,
      ];
}
