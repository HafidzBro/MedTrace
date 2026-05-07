import 'package:medtrace/domain/entities/entities.dart';

// User Model
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.role,
    super.fullName,
    super.phoneNumber,
    super.avatarUrl,
    super.bio,
    super.country,
    super.city,
    super.dateOfBirth,
    super.gender,
    required super.createdAt,
    required super.updatedAt,
    super.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'patient',
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      country: json['country'],
      city: json['city'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      gender: json['gender'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toString(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toString(),
      ),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'avatar_url': avatarUrl,
        'bio': bio,
        'country': country,
        'city': city,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'gender': gender,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'is_active': isActive,
      };
}

// Doctor Code Model
class DoctorCodeModel extends DoctorCode {
  const DoctorCodeModel({
    required super.id,
    required super.doctorId,
    required super.code,
    required super.createdAt,
    required super.expiresAt,
    required super.maxUses,
    required super.currentUses,
    required super.isActive,
  });

  factory DoctorCodeModel.fromJson(Map<String, dynamic> json) {
    return DoctorCodeModel(
      id: json['id'] ?? '',
      doctorId: json['doctor_id'] ?? '',
      code: json['code'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toString(),
      ),
      expiresAt: DateTime.parse(
        json['expires_at'] ?? DateTime.now().toString(),
      ),
      maxUses: json['max_uses'] ?? 1,
      currentUses: json['current_uses'] ?? 0,
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'doctor_id': doctorId,
        'code': code,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'max_uses': maxUses,
        'current_uses': currentUses,
        'is_active': isActive,
      };
}

// Treatment Model
class TreatmentModel extends Treatment {
  const TreatmentModel({
    required super.id,
    required super.patientId,
    required super.doctorId,
    required super.diagnosisDate,
    required super.startDate,
    super.endDate,
    required super.phase,
    required super.status,
    required super.adherencePercentage,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TreatmentModel.fromJson(Map<String, dynamic> json) {
    return TreatmentModel(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      doctorId: json['doctor_id'] ?? '',
      diagnosisDate: DateTime.parse(
        json['diagnosis_date'] ?? DateTime.now().toString(),
      ),
      startDate: DateTime.parse(
        json['start_date'] ?? DateTime.now().toString(),
      ),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      phase: json['phase'] ?? 'intensive',
      status: json['status'] ?? 'ongoing',
      adherencePercentage: (json['adherence_percentage'] ?? 0.0).toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toString(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'doctor_id': doctorId,
        'diagnosis_date': diagnosisDate.toIso8601String(),
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'phase': phase,
        'status': status,
        'adherence_percentage': adherencePercentage,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

// Medication Model
class MedicationModel extends Medication {
  const MedicationModel({
    required super.id,
    required super.treatmentId,
    required super.name,
    required super.dosage,
    required super.unit,
    required super.frequency,
    required super.startDate,
    super.endDate,
    super.instructions,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'] ?? '',
      treatmentId: json['treatment_id'] ?? '',
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      unit: json['unit'] ?? '',
      frequency: json['frequency'] ?? '',
      startDate: DateTime.parse(
        json['start_date'] ?? DateTime.now().toString(),
      ),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      instructions: json['instructions'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toString(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'treatment_id': treatmentId,
        'name': name,
        'dosage': dosage,
        'unit': unit,
        'frequency': frequency,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'instructions': instructions,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

// Medication Log Model
class MedicationLogModel extends MedicationLog {
  const MedicationLogModel({
    required super.id,
    required super.medicationId,
    required super.patientId,
    required super.scheduledDate,
    required super.scheduledTime,
    required super.status,
    super.takenAt,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MedicationLogModel.fromJson(Map<String, dynamic> json) {
    return MedicationLogModel(
      id: json['id'] ?? '',
      medicationId: json['medication_id'] ?? '',
      patientId: json['patient_id'] ?? '',
      scheduledDate: DateTime.parse(
        json['scheduled_date'] ?? DateTime.now().toString(),
      ),
      scheduledTime: _parseTime(json['scheduled_time']),
      status: json['status'] ?? 'pending',
      takenAt:
          json['taken_at'] != null ? DateTime.parse(json['taken_at']) : null,
      notes: json['notes'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toString(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'medication_id': medicationId,
        'patient_id': patientId,
        'scheduled_date': scheduledDate.toIso8601String(),
        'scheduled_time': _timeToString(scheduledTime),
        'status': status,
        'taken_at': takenAt?.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static DateTime _parseTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        final today = DateTime.now();
        final time = value.split(':');
        return DateTime(
          today.year,
          today.month,
          today.day,
          int.parse(time[0]),
          int.parse(time[1]),
        );
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static String _timeToString(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// Reminder Model
class ReminderModel extends Reminder {
  const ReminderModel({
    required super.id,
    required super.patientId,
    required super.title,
    super.description,
    required super.reminderType,
    required super.scheduledDate,
    required super.scheduledTime,
    super.isSent,
    super.sentAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      reminderType: json['reminder_type'] ?? 'custom',
      scheduledDate: DateTime.parse(
        json['scheduled_date'] ?? DateTime.now().toString(),
      ),
      scheduledTime: _parseTime(json['scheduled_time']),
      isSent: json['is_sent'] ?? false,
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toString(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'title': title,
        'description': description,
        'reminder_type': reminderType,
        'scheduled_date': scheduledDate.toIso8601String(),
        'scheduled_time': _timeToString(scheduledTime),
        'is_sent': isSent,
        'sent_at': sentAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static DateTime _parseTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        final today = DateTime.now();
        final time = value.split(':');
        return DateTime(
          today.year,
          today.month,
          today.day,
          int.parse(time[0]),
          int.parse(time[1]),
        );
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static String _timeToString(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// Patient Location Model
class PatientLocationModel extends PatientLocation {
  const PatientLocationModel({
    required super.id,
    required super.patientId,
    required super.latitude,
    required super.longitude,
    super.accuracy,
    super.altitude,
    super.address,
    required super.recordedAt,
    required super.createdAt,
  });

  factory PatientLocationModel.fromJson(Map<String, dynamic> json) {
    return PatientLocationModel(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      accuracy: json['accuracy'] != null ? (json['accuracy']).toDouble() : null,
      altitude: json['altitude'] != null ? (json['altitude']).toDouble() : null,
      address: json['address'],
      recordedAt: DateTime.parse(
        json['recorded_at'] ?? DateTime.now().toString(),
      ),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'address': address,
        'recorded_at': recordedAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}

// Chatbot Message Model
class ChatbotMessageModel extends ChatbotMessage {
  const ChatbotMessageModel({
    required super.id,
    required super.conversationId,
    required super.role,
    required super.message,
    required super.createdAt,
  });

  factory ChatbotMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatbotMessageModel(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      role: json['role'] ?? 'user',
      message: json['message'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'role': role,
        'message': message,
        'created_at': createdAt.toIso8601String(),
      };
}

// Alert Model
class AlertModel extends Alert {
  const AlertModel({
    required super.id,
    required super.doctorId,
    required super.patientId,
    required super.alertType,
    required super.severity,
    required super.title,
    super.description,
    super.isRead,
    super.readAt,
    super.actionTaken,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? '',
      doctorId: json['doctor_id'] ?? '',
      patientId: json['patient_id'] ?? '',
      alertType: json['alert_type'] ?? '',
      severity: json['severity'] ?? 'low',
      title: json['title'] ?? '',
      description: json['description'],
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      actionTaken: json['action_taken'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toString(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'doctor_id': doctorId,
        'patient_id': patientId,
        'alert_type': alertType,
        'severity': severity,
        'title': title,
        'description': description,
        'is_read': isRead,
        'read_at': readAt?.toIso8601String(),
        'action_taken': actionTaken,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
