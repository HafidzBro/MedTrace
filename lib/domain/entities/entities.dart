import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String role; // 'doctor' or 'patient'
  final String? fullName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? bio;
  final String? country;
  final String? city;
  final DateTime? dateOfBirth;
  final String? gender;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const User({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.phoneNumber,
    this.avatarUrl,
    this.bio,
    this.country,
    this.city,
    this.dateOfBirth,
    this.gender,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  bool get isDoctor => role == 'doctor';
  bool get isPatient => role == 'patient';

  User copyWith({
    String? id,
    String? email,
    String? role,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
    String? country,
    String? city,
    DateTime? dateOfBirth,
    String? gender,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      country: country ?? this.country,
      city: city ?? this.city,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        role,
        fullName,
        phoneNumber,
        avatarUrl,
        bio,
        country,
        city,
        dateOfBirth,
        gender,
        createdAt,
        updatedAt,
        isActive,
      ];
}

class DoctorCode extends Equatable {
  final String id;
  final String doctorId;
  final String code;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int maxUses;
  final int currentUses;
  final bool isActive;

  const DoctorCode({
    required this.id,
    required this.doctorId,
    required this.code,
    required this.createdAt,
    required this.expiresAt,
    required this.maxUses,
    required this.currentUses,
    required this.isActive,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isUsageExceeded => currentUses >= maxUses;
  bool get canBeUsed => isActive && !isExpired && !isUsageExceeded;

  @override
  List<Object?> get props => [
        id,
        doctorId,
        code,
        createdAt,
        expiresAt,
        maxUses,
        currentUses,
        isActive,
      ];
}

class DoctorPatient extends Equatable {
  final String id;
  final String doctorId;
  final String patientId;
  final DateTime linkedAt;
  final String? registrationCodeId;

  const DoctorPatient({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.linkedAt,
    this.registrationCodeId,
  });

  @override
  List<Object?> get props => [
        id,
        doctorId,
        patientId,
        linkedAt,
        registrationCodeId,
      ];
}

class Treatment extends Equatable {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime diagnosisDate;
  final DateTime startDate;
  final DateTime? endDate;
  final String phase; // 'intensive' or 'continuation'
  final String status; // 'ongoing', 'completed', 'defaulted'
  final double adherencePercentage;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Treatment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.diagnosisDate,
    required this.startDate,
    this.endDate,
    required this.phase,
    required this.status,
    required this.adherencePercentage,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isIntensive => phase == 'intensive';
  bool get isContinuation => phase == 'continuation';
  bool get isOngoing => status == 'ongoing';
  bool get isCompleted => status == 'completed';
  bool get isDefaulted => status == 'defaulted';

  int get treatmentDaysElapsed => DateTime.now().difference(startDate).inDays;

  Treatment copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    DateTime? diagnosisDate,
    DateTime? startDate,
    DateTime? endDate,
    String? phase,
    String? status,
    double? adherencePercentage,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Treatment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      diagnosisDate: diagnosisDate ?? this.diagnosisDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      phase: phase ?? this.phase,
      status: status ?? this.status,
      adherencePercentage: adherencePercentage ?? this.adherencePercentage,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        patientId,
        doctorId,
        diagnosisDate,
        startDate,
        endDate,
        phase,
        status,
        adherencePercentage,
        notes,
        createdAt,
        updatedAt,
      ];
}

class Medication extends Equatable {
  final String id;
  final String treatmentId;
  final String name;
  final String dosage;
  final String unit;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final String? instructions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Medication({
    required this.id,
    required this.treatmentId,
    required this.name,
    required this.dosage,
    required this.unit,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.instructions,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive =>
      DateTime.now().isAfter(startDate) &&
      (endDate == null || DateTime.now().isBefore(endDate!));

  @override
  List<Object?> get props => [
        id,
        treatmentId,
        name,
        dosage,
        unit,
        frequency,
        startDate,
        endDate,
        instructions,
        createdAt,
        updatedAt,
      ];
}

class MedicationLog extends Equatable {
  final String id;
  final String medicationId;
  final String patientId;
  final DateTime scheduledDate;
  final DateTime scheduledTime;
  final String status; // 'taken', 'missed', 'skipped', 'pending'
  final DateTime? takenAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicationLog({
    required this.id,
    required this.medicationId,
    required this.patientId,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.status,
    this.takenAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isTaken => status == 'taken';
  bool get isMissed => status == 'missed';
  bool get isSkipped => status == 'skipped';
  bool get isPending => status == 'pending';

  @override
  List<Object?> get props => [
        id,
        medicationId,
        patientId,
        scheduledDate,
        scheduledTime,
        status,
        takenAt,
        notes,
        createdAt,
        updatedAt,
      ];
}

class Reminder extends Equatable {
  final String id;
  final String patientId;
  final String title;
  final String? description;
  final String reminderType; // 'medication', 'appointment', 'checkup', 'custom'
  final DateTime scheduledDate;
  final DateTime scheduledTime;
  final bool isSent;
  final DateTime? sentAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    required this.id,
    required this.patientId,
    required this.title,
    this.description,
    required this.reminderType,
    required this.scheduledDate,
    required this.scheduledTime,
    this.isSent = false,
    this.sentAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOverdue => DateTime.now().isAfter(scheduledDate);

  @override
  List<Object?> get props => [
        id,
        patientId,
        title,
        description,
        reminderType,
        scheduledDate,
        scheduledTime,
        isSent,
        sentAt,
        createdAt,
        updatedAt,
      ];
}

class PatientLocation extends Equatable {
  final String id;
  final String patientId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final String? address;
  final DateTime recordedAt;
  final DateTime createdAt;

  const PatientLocation({
    required this.id,
    required this.patientId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.address,
    required this.recordedAt,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        patientId,
        latitude,
        longitude,
        accuracy,
        altitude,
        address,
        recordedAt,
        createdAt,
      ];
}

class ChatbotConversation extends Equatable {
  final String id;
  final String patientId;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatbotConversation({
    required this.id,
    required this.patientId,
    this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, patientId, title, createdAt, updatedAt];
}

class ChatbotMessage extends Equatable {
  final String id;
  final String conversationId;
  final String role; // 'user' or 'assistant'
  final String message;
  final DateTime createdAt;

  const ChatbotMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.message,
    required this.createdAt,
  });

  bool get isUserMessage => role == 'user';
  bool get isAssistantMessage => role == 'assistant';

  @override
  List<Object?> get props => [id, conversationId, role, message, createdAt];
}

class Alert extends Equatable {
  final String id;
  final String doctorId;
  final String patientId;
  final String
      alertType; // 'missed_medication', 'high_risk', 'treatment_completion'
  final String severity; // 'low', 'medium', 'high', 'critical'
  final String title;
  final String? description;
  final bool isRead;
  final DateTime? readAt;
  final bool actionTaken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Alert({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.alertType,
    required this.severity,
    required this.title,
    this.description,
    this.isRead = false,
    this.readAt,
    this.actionTaken = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCritical => severity == 'critical';
  bool get isHighSeverity => severity == 'high';

  @override
  List<Object?> get props => [
        id,
        doctorId,
        patientId,
        alertType,
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

class Notification extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? body;
  final String notificationType;
  final String? relatedId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const Notification({
    required this.id,
    required this.userId,
    required this.title,
    this.body,
    required this.notificationType,
    this.relatedId,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        body,
        notificationType,
        relatedId,
        isRead,
        readAt,
        createdAt,
      ];
}
