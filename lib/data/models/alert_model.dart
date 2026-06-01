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
  final String? patientName;
  final String? patientEmail;

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
    this.patientName,
    this.patientEmail,
  })  : alertId = id,
        type = alertType ?? '';

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final patient = json['patients'];
    final patientProfile = patient is Map<String, dynamic>
        ? patient['profiles'] as Map<String, dynamic>?
        : null;

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
      patientName: patientProfile?['full_name'],
      patientEmail: patientProfile?['email'],
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
        'patient_name': patientName,
        'patient_email': patientEmail,
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
        patientName,
        patientEmail,
      ];
}
