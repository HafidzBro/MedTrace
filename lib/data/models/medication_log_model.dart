import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class MedicationLogModel extends Equatable {
  final String medicationLogId;
  final String patientId;
  final String? medicationId;
  final String? therapyId;
  final String? therapyPhaseId;
  final DateTime scheduledAt;
  final DateTime? takenAt;
  final String status;
  final DateTime createdAt;
  final String? notes;

  const MedicationLogModel({
    required String id,
    this.medicationId,
    required this.patientId,
    this.therapyId,
    this.therapyPhaseId,
    required this.scheduledAt,
    this.takenAt,
    required this.status,
    required this.createdAt,
    DateTime? updatedAt,
    this.notes,
  }) : medicationLogId = id;

  factory MedicationLogModel.fromJson(Map<String, dynamic> json) {
    final scheduledAt = json['scheduled_at'] ??
        json['scheduled_date'] ??
        DateTime.now().toIso8601String();
    return MedicationLogModel(
      id: json['medication_log_id'] ?? json['id'] ?? '',
      medicationId: json['medication_id'],
      patientId: json['patient_id'] ?? '',
      therapyId: json['therapy_id'] ?? json['treatment_id'],
      therapyPhaseId: json['therapy_phase_id'],
      scheduledAt: parseDateTime(scheduledAt),
      takenAt: parseNullableDateTime(json['taken_at']),
      status: json['status'] ?? 'pending',
      createdAt: parseDateTime(json['created_at']),
      notes: json['notes'],
    );
  }

  String get id => medicationLogId;
  DateTime get scheduledDate => scheduledAt;
  DateTime get scheduledTime => scheduledAt;
  DateTime get updatedAt => createdAt;
  bool get isTaken => status == 'taken';
  bool get isMissed => status == 'missed';
  bool get isSkipped => status == 'skipped';
  bool get isPending => status == 'pending';

  Map<String, dynamic> toJson() => {
        'medication_log_id': medicationLogId,
        'medication_id': medicationId,
        'patient_id': patientId,
        'therapy_id': therapyId,
        'therapy_phase_id': therapyPhaseId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'taken_at': takenAt?.toIso8601String(),
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'notes': notes,
      };

  @override
  List<Object?> get props => [
        medicationLogId,
        medicationId,
        patientId,
        therapyId,
        therapyPhaseId,
        scheduledAt,
        takenAt,
        status,
        createdAt,
        notes,
      ];
}
