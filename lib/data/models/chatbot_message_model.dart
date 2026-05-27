import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class ChatbotMessageModel extends Equatable {
  final String messagesId;
  final String conversationId;
  final String? response;
  final String role;
  final String message;
  final DateTime createdAt;

  const ChatbotMessageModel({
    required String id,
    required this.conversationId,
    this.response,
    this.role = 'assistant',
    String? message,
    required this.createdAt,
  })  : messagesId = id,
        message = message ?? response ?? '';

  factory ChatbotMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatbotMessageModel(
      id: json['messages_id'] ?? json['chatbot_log_id'] ?? json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      response: json['response'],
      role: json['role'] ?? 'assistant',
      message: json['message'] ?? json['response'],
      createdAt: parseDateTime(json['created_at']),
    );
  }

  String get id => messagesId;
  bool get isUserMessage => role == 'user';
  bool get isAssistantMessage => role == 'assistant';

  Map<String, dynamic> toJson() => {
        'messages_id': messagesId,
        'conversation_id': conversationId,
        'response': response,
        'role': role,
        'message': message,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [messagesId, conversationId, response, role, message, createdAt];
}
