import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PendingPatientRegistration {
  final String email;
  final String fullName;
  final String doctorCode;
  final DateTime? dateOfBirth;
  final String? nik;
  final DateTime? diagnosisDate;
  final String? tbCaseCategory;
  final String? tbCaseDescription;
  final String? phoneNumber;
  final String? gender;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracy;

  const PendingPatientRegistration({
    required this.email,
    required this.fullName,
    required this.doctorCode,
    this.dateOfBirth,
    this.nik,
    this.diagnosisDate,
    this.tbCaseCategory,
    this.tbCaseDescription,
    this.phoneNumber,
    this.gender,
    this.address,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'full_name': fullName,
        'doctor_code': doctorCode,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'nik': nik,
        'diagnosis_date': diagnosisDate?.toIso8601String(),
        'tb_case_category': tbCaseCategory,
        'tb_case_description': tbCaseDescription,
        'phone_number': phoneNumber,
        'gender': gender,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'location_accuracy': locationAccuracy,
      };

  factory PendingPatientRegistration.fromJson(Map<String, dynamic> json) {
    return PendingPatientRegistration(
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      doctorCode: json['doctor_code'] as String,
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
      nik: json['nik'] as String?,
      diagnosisDate: json['diagnosis_date'] == null
          ? null
          : DateTime.parse(json['diagnosis_date'] as String),
      tbCaseCategory: json['tb_case_category'] as String?,
      tbCaseDescription: json['tb_case_description'] as String?,
      phoneNumber: json['phone_number'] as String?,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationAccuracy: (json['location_accuracy'] as num?)?.toDouble(),
    );
  }
}

class PendingPatientRegistrationService {
  static const _keyPrefix = 'pending_patient_registration_';

  final FlutterSecureStorage storage;

  const PendingPatientRegistrationService({
    this.storage = const FlutterSecureStorage(),
  });

  Future<void> save(PendingPatientRegistration registration) async {
    await storage.write(
      key: _keyFor(registration.email),
      value: jsonEncode(registration.toJson()),
    );
  }

  Future<PendingPatientRegistration?> readForEmail(String email) async {
    final raw = await storage.read(key: _keyFor(email));
    if (raw == null || raw.isEmpty) return null;

    final data = jsonDecode(raw) as Map<String, dynamic>;
    return PendingPatientRegistration.fromJson(data);
  }

  Future<void> deleteForEmail(String email) async {
    await storage.delete(key: _keyFor(email));
  }

  String _keyFor(String email) => '$_keyPrefix${email.trim().toLowerCase()}';
}
