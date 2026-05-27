import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class UserAuthModel extends Equatable {
  final String userId;
  final String email;
  final String? passwordEncrypt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserAuthModel({
    required this.userId,
    required this.email,
    this.passwordEncrypt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserAuthModel.fromJson(Map<String, dynamic> json) {
    return UserAuthModel(
      userId: json['user_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      passwordEncrypt: json['password_encrypt'],
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'email': email,
        'password_encrypt': passwordEncrypt,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [userId, email, passwordEncrypt, createdAt, updatedAt];
}
