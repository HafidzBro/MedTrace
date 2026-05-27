import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class DoctorModel extends Equatable {
  final String doctorId;
  final String profileId;
  final String? facilityName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DoctorModel({
    required this.doctorId,
    required this.profileId,
    this.facilityName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) => DoctorModel(
        doctorId: json['doctor_id'] ?? json['id'] ?? '',
        profileId: json['profile_id'] ?? '',
        facilityName: json['facility_name'],
        createdAt: parseDateTime(json['created_at']),
        updatedAt: parseDateTime(json['updated_at']),
      );

  String get id => doctorId;

  Map<String, dynamic> toJson() => {
        'doctor_id': doctorId,
        'profile_id': profileId,
        'facility_name': facilityName,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [doctorId, profileId, facilityName, createdAt, updatedAt];
}
