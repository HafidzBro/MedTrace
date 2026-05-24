import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PendingPatientRegistration {
  final String email;
  final String fullName;
  final String doctorCode;
  final DateTime? dateOfBirth;
  final String? phoneNumber;
  final String? gender;
  final String? address;

  const PendingPatientRegistration({
    required this.email,
    required this.fullName,
    required this.doctorCode,
    this.dateOfBirth,
    this.phoneNumber,
    this.gender,
    this.address,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'full_name': fullName,
        'doctor_code': doctorCode,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'phone_number': phoneNumber,
        'gender': gender,
        'address': address,
      };

  factory PendingPatientRegistration.fromJson(Map<String, dynamic> json) {
    return PendingPatientRegistration(
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      doctorCode: json['doctor_code'] as String,
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
      phoneNumber: json['phone_number'] as String?,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
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
