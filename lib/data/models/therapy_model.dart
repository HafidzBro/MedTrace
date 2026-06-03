import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class TherapyModel extends Equatable {
  final String therapyId;
  final String? tbCaseId;
  final String patientId;
  final String doctorId;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final double adherencePercentage;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TherapyModel({
    required this.therapyId,
    this.tbCaseId,
    required this.patientId,
    required this.doctorId,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.adherencePercentage,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TherapyModel.fromJson(Map<String, dynamic> json) => TherapyModel(
        therapyId: json['therapy_id'] ?? json['id'] ?? '',
        tbCaseId: json['tb_case_id'],
        patientId: json['patient_id'] ?? '',
        doctorId: json['doctor_id'] ?? '',
        startDate: parseDateTime(json['start_date']),
        endDate: parseNullableDateTime(json['end_date']),
        status: json['status'] ?? 'ongoing',
        adherencePercentage: parseDouble(json['adherence_percentage']),
        description: json['description'] ?? json['notes'],
        createdAt: parseDateTime(json['created_at']),
        updatedAt: parseDateTime(json['updated_at']),
      );

  String get id => therapyId;
  bool get isOngoing =>
      status == 'ongoing' || status == 'on_treatment' || status == 'at_risk';
  bool get isCompleted => status == 'completed';
  bool get isDefaulted => status == 'defaulted' || status == 'failed';
  bool get isFailed => status == 'defaulted' || status == 'failed';
  bool get isAtRisk => status == 'at_risk';
  int get treatmentDaysElapsed => DateTime.now().difference(startDate).inDays;

  Map<String, dynamic> toJson() => {
        'therapy_id': therapyId,
        'tb_case_id': tbCaseId,
        'patient_id': patientId,
        'doctor_id': doctorId,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'status': status,
        'adherence_percentage': adherencePercentage,
        'description': description,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        therapyId,
        tbCaseId,
        patientId,
        doctorId,
        startDate,
        endDate,
        status,
        adherencePercentage,
        description,
        createdAt,
        updatedAt,
      ];
}

class TreatmentModel extends TherapyModel {
  final DateTime diagnosisDate;
  final String phase;
  final String? notes;

  const TreatmentModel({
    required String id,
    required super.patientId,
    required super.doctorId,
    required this.diagnosisDate,
    required super.startDate,
    super.endDate,
    required this.phase,
    required super.status,
    required super.adherencePercentage,
    this.notes,
    required super.createdAt,
    required super.updatedAt,
  }) : super(therapyId: id, description: notes);

  factory TreatmentModel.fromJson(Map<String, dynamic> json) {
    return TreatmentModel(
      id: json['therapy_id'] ?? json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      doctorId: json['doctor_id'] ?? '',
      diagnosisDate: parseDateTime(json['diagnosis_date']),
      startDate: parseDateTime(json['start_date']),
      endDate: parseNullableDateTime(json['end_date']),
      phase: json['phase'] ?? json['phase_name'] ?? 'intensive',
      status: json['status'] ?? 'ongoing',
      adherencePercentage: parseDouble(json['adherence_percentage']),
      notes: json['notes'] ?? json['description'],
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  bool get isIntensive => phase == 'intensive';
  bool get isContinuation => phase == 'continuation';

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'id': id,
        'diagnosis_date': diagnosisDate.toIso8601String(),
        'phase': phase,
        'notes': notes,
      };

  @override
  List<Object?> get props => [...super.props, diagnosisDate, phase, notes];
}
