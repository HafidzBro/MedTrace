import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class PatientLocationModel extends Equatable {
  final String patientLocationId;
  final String patientId;
  final double latitude;
  final double longitude;
  final String? address;
  final bool isCurrent;
  final DateTime createdAt;
  final DateTime recordedAt;
  final double? accuracy;
  final double? altitude;

  const PatientLocationModel({
    required String id,
    required this.patientId,
    required this.latitude,
    required this.longitude,
    this.address,
    this.isCurrent = false,
    required this.createdAt,
    required this.recordedAt,
    this.accuracy,
    this.altitude,
  }) : patientLocationId = id;

  factory PatientLocationModel.fromJson(Map<String, dynamic> json) {
    return PatientLocationModel(
      id: json['patient_location_id'] ?? json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      address: json['address'],
      isCurrent: json['is_current'] ?? false,
      createdAt: parseDateTime(json['created_at']),
      recordedAt: parseDateTime(json['recorded_at']),
      accuracy: json['accuracy'] == null ? null : parseDouble(json['accuracy']),
      altitude: json['altitude'] == null ? null : parseDouble(json['altitude']),
    );
  }

  String get id => patientLocationId;

  Map<String, dynamic> toJson() => {
        'patient_location_id': patientLocationId,
        'patient_id': patientId,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'is_current': isCurrent,
        'created_at': createdAt.toIso8601String(),
        'recorded_at': recordedAt.toIso8601String(),
        'accuracy': accuracy,
        'altitude': altitude,
      };

  @override
  List<Object?> get props => [
        patientLocationId,
        patientId,
        latitude,
        longitude,
        address,
        isCurrent,
        createdAt,
        recordedAt,
        accuracy,
        altitude,
      ];
}
