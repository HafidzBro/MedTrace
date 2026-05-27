import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class DoctorCodeModel extends Equatable {
  final String codeId;
  final String doctorId;
  final String code;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int maxUses;
  final int currentUses;
  final bool isActive;

  const DoctorCodeModel({
    required String id,
    required this.doctorId,
    required this.code,
    required this.createdAt,
    required this.expiresAt,
    required this.maxUses,
    required this.currentUses,
    required this.isActive,
  }) : codeId = id;

  factory DoctorCodeModel.fromJson(Map<String, dynamic> json) {
    return DoctorCodeModel(
      id: json['code_id'] ?? json['id'] ?? '',
      doctorId: json['doctor_id'] ?? '',
      code: json['code'] ?? '',
      createdAt: parseDateTime(json['created_at']),
      expiresAt: parseDateTime(json['expires_at']),
      maxUses: parseInt(json['max_uses'], 1),
      currentUses: parseInt(json['current_uses']),
      isActive: json['is_active'] ?? false,
    );
  }

  String get id => codeId;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isUsageExceeded => currentUses >= maxUses;
  bool get canBeUsed => isActive && !isExpired && !isUsageExceeded;

  Map<String, dynamic> toJson() => {
        'code_id': codeId,
        'doctor_id': doctorId,
        'code': code,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'max_uses': maxUses,
        'current_uses': currentUses,
        'is_active': isActive,
      };

  @override
  List<Object?> get props => [
        codeId,
        doctorId,
        code,
        createdAt,
        expiresAt,
        maxUses,
        currentUses,
        isActive,
      ];
}
