import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class ReminderModel extends Equatable {
  final String reminderId;
  final String patientId;
  final String? therapyId;
  final String? therapyPhaseId;
  final String title;
  final String? description;
  final String reminderType;
  final DateTime reminderTime;
  final String status;
  final DateTime? sentAt;
  final DateTime createdAt;
  final DateTime scheduledDate;

  const ReminderModel({
    required String id,
    required this.patientId,
    this.therapyId,
    this.therapyPhaseId,
    required this.title,
    this.description,
    required this.reminderType,
    required DateTime scheduledTime,
    this.status = 'pending',
    this.sentAt,
    DateTime? createdAt,
    required this.scheduledDate,
    bool isSent = false,
    DateTime? updatedAt,
  })  : reminderId = id,
        reminderTime = scheduledTime,
        createdAt = createdAt ?? scheduledTime;

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['reminder_id'] ?? json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      therapyId: json['therapy_id'] ?? json['treatment_id'],
      therapyPhaseId: json['therapy_phase_id'],
      title: json['title'] ?? '',
      description: json['description'],
      reminderType: json['reminder_type'] ?? 'custom',
      scheduledTime: json['reminder_time'] != null
          ? parseTime(json['reminder_time'])
          : parseTime(json['scheduled_time']),
      status:
          json['status'] ?? ((json['is_sent'] ?? false) ? 'sent' : 'pending'),
      sentAt: parseNullableDateTime(json['sent_at']),
      createdAt: parseDateTime(json['created_at']),
      scheduledDate: parseNullableDateTime(json['scheduled_date']) ??
          parseDateTime(json['created_at']),
    );
  }

  String get id => reminderId;
  DateTime get scheduledTime => reminderTime;
  bool get isSent => status == 'sent' || sentAt != null;
  DateTime get updatedAt => createdAt;
  bool get isOverdue {
    return DateTime.now().isAfter(scheduledDate);
  }

  Map<String, dynamic> toJson() => {
        'reminder_id': reminderId,
        'patient_id': patientId,
        'therapy_id': therapyId,
        'therapy_phase_id': therapyPhaseId,
        'title': title,
        'description': description,
        'reminder_type': reminderType,
        'reminder_time': timeToString(reminderTime),
        'status': status,
        'sent_at': sentAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'scheduled_date': scheduledDate.toIso8601String(),
        'scheduled_time': timeToString(scheduledTime),
        'is_sent': isSent,
      };

  @override
  List<Object?> get props => [
        reminderId,
        patientId,
        therapyId,
        therapyPhaseId,
        title,
        description,
        reminderType,
        reminderTime,
        status,
        sentAt,
        createdAt,
        scheduledDate,
      ];
}
