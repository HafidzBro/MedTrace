import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class AlertModel extends Equatable {
  final String alertId;
  final String patientId;
  final String? therapyId;
  final String? doctorId;
  final String type;
  final String severity;
  final String? description;
  final String? title;
  final bool isRead;
  final DateTime? readAt;
  final bool actionTaken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AlertModel({
    required String id,
    this.doctorId,
    required this.patientId,
    this.therapyId,
    String? alertType,
    required this.severity,
    this.title,
    this.description,
    this.isRead = false,
    this.readAt,
    this.actionTaken = false,
    required this.createdAt,
    required this.updatedAt,
  })  : alertId = id,
        type = alertType ?? '';

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['alert_id'] ?? json['id'] ?? '',
      doctorId: json['doctor_id'],
      patientId: json['patient_id'] ?? '',
      therapyId: json['therapy_id'] ?? json['treatment_id'],
      alertType: json['type'] ?? json['alert_type'] ?? '',
      severity: json['severity'] ?? 'low',
      title: json['title'],
      description: json['description'],
      isRead: json['is_read'] ?? false,
      readAt: parseNullableDateTime(json['read_at']),
      actionTaken: json['action_taken'] ?? false,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  String get id => alertId;
  String get alertType => type;
  bool get isCritical => severity == 'critical';
  bool get isHighSeverity => severity == 'high';

  Map<String, dynamic> toJson() => {
        'alert_id': alertId,
        'patient_id': patientId,
        'therapy_id': therapyId,
        'doctor_id': doctorId,
        'type': type,
        'alert_type': type,
        'severity': severity,
        'title': title,
        'description': description,
        'is_read': isRead,
        'read_at': readAt?.toIso8601String(),
        'action_taken': actionTaken,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        alertId,
        patientId,
        therapyId,
        doctorId,
        type,
        severity,
        title,
        description,
        isRead,
        readAt,
        actionTaken,
        createdAt,
        updatedAt,
      ];
}
