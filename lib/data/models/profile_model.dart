import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class ProfileModel extends Equatable {
  final String profileId;
  final String userId;
  final String fullName;
  final String email;
  final String role;
  final String? avatarUrl;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const ProfileModel({
    required this.profileId,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final id = json['profile_id'] ?? json['id'] ?? '';
    return ProfileModel(
      profileId: id,
      userId: json['user_id'] ?? id,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'patient',
      avatarUrl: json['avatar_url'],
      phone: json['phone'] ?? json['phone_number'],
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
      isActive: json['is_active'] ?? true,
    );
  }

  String get id => profileId;
  String? get phoneNumber => phone;
  bool get isDoctor => role == 'doctor';
  bool get isPatient => role == 'patient';

  Map<String, dynamic> toJson() => {
        'profile_id': profileId,
        'user_id': userId,
        'full_name': fullName,
        'email': email,
        'role': role,
        'avatar_url': avatarUrl,
        'phone': phone,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'is_active': isActive,
      };

  ProfileModel copyWith({
    String? profileId,
    String? userId,
    String? fullName,
    String? email,
    String? role,
    String? avatarUrl,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ProfileModel(
      profileId: profileId ?? this.profileId,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        profileId,
        userId,
        fullName,
        email,
        role,
        avatarUrl,
        phone,
        createdAt,
        updatedAt,
        isActive,
      ];
}

class UserModel extends ProfileModel {
  const UserModel({
    required String id,
    required super.email,
    required super.role,
    String? fullName,
    String? phoneNumber,
    super.avatarUrl,
    this.bio,
    this.country,
    this.city,
    this.dateOfBirth,
    this.gender,
    required super.createdAt,
    required super.updatedAt,
    super.isActive,
  }) : super(
          profileId: id,
          userId: id,
          fullName: fullName ?? '',
          phone: phoneNumber,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final id = json['profile_id'] ?? json['id'] ?? json['user_id'] ?? '';
    return UserModel(
      id: id,
      email: json['email'] ?? '',
      role: json['role'] ?? 'patient',
      fullName: json['full_name'],
      phoneNumber: json['phone'] ?? json['phone_number'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      country: json['country'],
      city: json['city'],
      dateOfBirth: parseNullableDateTime(json['date_of_birth']),
      gender: json['gender'],
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
      isActive: json['is_active'] ?? true,
    );
  }

  final String? bio;
  final String? country;
  final String? city;
  final DateTime? dateOfBirth;
  final String? gender;

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'id': id,
        'phone_number': phoneNumber,
        'bio': bio,
        'country': country,
        'city': city,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'gender': gender,
      };

  @override
  List<Object?> get props => [
        ...super.props,
        bio,
        country,
        city,
        dateOfBirth,
        gender,
      ];
}
