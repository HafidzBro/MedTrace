import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class PatientModel extends Equatable {
  final String patientId;
  final String profileId;
  final String doctorId;
  final String? patientCode;
  final String? nik;
  final String? gender;
  final DateTime? birthDate;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PatientModel({
    required this.patientId,
    required this.profileId,
    required this.doctorId,
    this.patientCode,
    this.nik,
    this.gender,
    this.birthDate,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) => PatientModel(
        patientId: json['patient_id'] ?? json['id'] ?? '',
        profileId: json['profile_id'] ?? '',
        doctorId: json['doctor_id'] ?? '',
        patientCode: json['patient_code'],
        nik: json['nik'],
        gender: json['gender'],
        birthDate: parseNullableDateTime(json['birth_date']),
        address: json['address'],
        createdAt: parseDateTime(json['created_at']),
        updatedAt: parseDateTime(json['updated_at']),
      );

  String get id => patientId;

  Map<String, dynamic> toJson() => {
        'patient_id': patientId,
        'profile_id': profileId,
        'doctor_id': doctorId,
        'patient_code': patientCode,
        'nik': nik,
        'gender': gender,
        'birth_date': birthDate?.toIso8601String(),
        'address': address,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        patientId,
        profileId,
        doctorId,
        patientCode,
        nik,
        gender,
        birthDate,
        address,
        createdAt,
        updatedAt,
      ];
}
