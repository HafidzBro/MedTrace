import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class ChatbotLogModel extends Equatable {
  final String chatbotLogId;
  final String patientId;
  final String conversationId;
  final String role;
  final String message;
  final DateTime createdAt;

  const ChatbotLogModel({
    required this.chatbotLogId,
    required this.patientId,
    required this.conversationId,
    required this.role,
    required this.message,
    required this.createdAt,
  });

  factory ChatbotLogModel.fromJson(Map<String, dynamic> json) =>
      ChatbotLogModel(
        chatbotLogId: json['chatbot_log_id'] ?? json['id'] ?? '',
        patientId: json['patient_id'] ?? '',
        conversationId: json['conversation_id'] ?? '',
        role: json['role'] ?? 'user',
        message: json['message'] ?? '',
        createdAt: parseDateTime(json['created_at']),
      );

  bool get isUserMessage => role == 'user';
  bool get isAssistantMessage => role == 'assistant';

  Map<String, dynamic> toJson() => {
        'chatbot_log_id': chatbotLogId,
        'patient_id': patientId,
        'conversation_id': conversationId,
        'role': role,
        'message': message,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [chatbotLogId, patientId, conversationId, role, message, createdAt];
}
