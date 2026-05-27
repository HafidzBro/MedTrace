import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class NotificationModel extends Equatable {
  final String notificationId;
  final String profileId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.notificationId,
    required this.profileId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        notificationId: json['notification_id'] ?? json['id'] ?? '',
        profileId: json['profile_id'] ?? json['user_id'] ?? '',
        title: json['title'] ?? '',
        message: json['message'] ?? json['body'] ?? '',
        type: json['type'] ?? json['notification_type'] ?? '',
        isRead: json['is_read'] ?? false,
        readAt: parseNullableDateTime(json['read_at']),
        createdAt: parseDateTime(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'notification_id': notificationId,
        'profile_id': profileId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': isRead,
        'read_at': readAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        notificationId,
        profileId,
        title,
        message,
        type,
        isRead,
        readAt,
        createdAt
      ];
}
