import 'package:equatable/equatable.dart';

import 'model_utils.dart';

class ChatbotConversationModel extends Equatable {
  final String conversationId;
  final String patientId;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatbotConversationModel({
    required String id,
    required this.patientId,
    this.title,
    required this.createdAt,
    required this.updatedAt,
  }) : conversationId = id;

  factory ChatbotConversationModel.fromJson(Map<String, dynamic> json) {
    return ChatbotConversationModel(
      id: json['conversation_id'] ?? json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      title: json['title'],
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  String get id => conversationId;

  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        'patient_id': patientId,
        'title': title,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [conversationId, patientId, title, createdAt, updatedAt];
}

typedef ChatbotConversation = ChatbotConversationModel;
