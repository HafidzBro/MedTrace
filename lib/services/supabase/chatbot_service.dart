import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:medtrace/core/config/app_config.dart';
import 'package:medtrace/core/constants/app_constants.dart';
import 'package:medtrace/data/models/chatbot_conversation_model.dart';
import 'package:medtrace/data/models/chatbot_log_model.dart';
import 'package:medtrace/data/models/chatbot_message_model.dart';
import 'package:medtrace/services/supabase/patient_service.dart';
import 'package:medtrace/services/supabase/supabase_service_context.dart';

class ChatbotService {
  final SupabaseServiceContext context;
  final PatientService patients;

  const ChatbotService(this.context, this.patients);

  Future<ChatbotConversation?> latestConversation(String patientId) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final existing = await context.client
        .from('chatbot_conversations')
        .select()
        .eq('patient_id', resolvedPatientId)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (existing != null) {
      return ChatbotConversationModel.fromJson(existing);
    }

    return null;
  }

  Future<ChatbotConversation> getOrCreateConversation(String patientId) async {
    final existing = await latestConversation(patientId);
    if (existing != null) return existing;
    return createConversation(patientId);
  }

  Future<ChatbotConversation> createConversation(String patientId) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final response = await context.client
        .from('chatbot_conversations')
        .insert({
          'patient_id': resolvedPatientId,
          'title': 'Conversation ${DateTime.now().toIso8601String()}',
        })
        .select()
        .single();

    return ChatbotConversationModel.fromJson(response);
  }

  Future<List<ChatbotConversation>> listConversations(String patientId) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final response = await context.client
        .from('chatbot_conversations')
        .select()
        .eq('patient_id', resolvedPatientId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) =>
            ChatbotConversationModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatbotLogModel>> listLogs(String conversationId) async {
    final response = await context.client
        .from('chatbot_logs')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((row) => ChatbotLogModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<ChatbotLogModel> addLog({
    required String patientId,
    required String conversationId,
    required String role,
    required String message,
  }) async {
    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final response = await context.client
        .from('chatbot_logs')
        .insert({
          'patient_id': resolvedPatientId,
          'conversation_id': conversationId,
          'role': role,
          'message': message,
        })
        .select()
        .single();

    return ChatbotLogModel.fromJson(response);
  }

  Future<ChatbotMessageModel> addAssistantMessage({
    required String conversationId,
    required String response,
  }) async {
    final row = await context.client
        .from('chatbot_messages')
        .insert({
          'conversation_id': conversationId,
          'response': response,
        })
        .select()
        .single();

    return ChatbotMessageModel.fromJson(row);
  }

  Future<List<ChatbotMessageModel>> listMessages(String conversationId) async {
    final response = await context.client
        .from('chatbot_messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((row) => ChatbotMessageModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<ChatbotSendResult> sendPatientMessage({
    required String patientId,
    required String message,
  }) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw ArgumentError('Message cannot be empty.');
    }

    final resolvedPatientId = await patients.resolvePatientId(patientId);
    final conversation = await getOrCreateConversation(resolvedPatientId);

    await addLog(
      patientId: resolvedPatientId,
      conversationId: conversation.id,
      role: 'user',
      message: trimmedMessage,
    );

    final history = await listLogs(conversation.id);
    final response = await _requestAssistantResponse(history);

    await addAssistantMessage(
      conversationId: conversation.id,
      response: response,
    );
    await addLog(
      patientId: resolvedPatientId,
      conversationId: conversation.id,
      role: 'assistant',
      message: response,
    );
    await _touchConversation(conversation.id, trimmedMessage);

    final logs = await listLogs(conversation.id);
    return ChatbotSendResult(
      conversation: conversation,
      logs: logs,
    );
  }

  Future<String> _requestAssistantResponse(List<ChatbotLogModel> logs) async {
    final customBaseUrl = AppConfig.chatbotApiBaseUrl.trim();
    final apiKey = AppConfig.chatbotApiKey.isNotEmpty
        ? AppConfig.chatbotApiKey
        : AppConfig.groqApiKey.isNotEmpty
            ? AppConfig.groqApiKey
            : AppConfig.openaiApiKey;
    if (apiKey.isEmpty) {
      throw StateError(
        'Chatbot API key is not configured. Set CHATBOT_API_KEY, GROQ_API_KEY, or OPENAI_API_KEY.',
      );
    }

    final useCustomEndpoint = customBaseUrl.isNotEmpty;
    final useGroq = !useCustomEndpoint &&
        AppConfig.chatbotApiKey.isEmpty &&
        AppConfig.groqApiKey.isNotEmpty;
    final endpoint = Uri.parse(
      useCustomEndpoint
          ? _chatCompletionUrl(customBaseUrl)
          : useGroq
              ? 'https://api.groq.com/openai/v1/chat/completions'
              : 'https://api.openai.com/v1/chat/completions',
    );
    final model = AppConfig.chatbotModel.isNotEmpty
        ? AppConfig.chatbotModel
        : useGroq
            ? AppConfig.groqModel
            : 'gpt-4o-mini';
    final recentLogs = logs.length > ChatbotConstants.maxContextMessages
        ? logs.sublist(logs.length - ChatbotConstants.maxContextMessages)
        : logs;

    final response = await http
        .post(
          endpoint,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'temperature': 0.3,
            'messages': [
              {
                'role': 'system',
                'content': ChatbotConstants.systemPromptEN,
              },
              for (final log in recentLogs)
                {
                  'role': log.role == 'assistant' ? 'assistant' : 'user',
                  'content': log.message,
                },
            ],
          }),
        )
        .timeout(AppConfig.receiveTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Chatbot API request failed (${response.statusCode}).');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = body['choices'] as List?;
    final firstChoice =
        choices?.isNotEmpty == true ? choices!.first as Map : null;
    final assistantMessage = firstChoice?['message'] as Map?;
    final content = assistantMessage?['content']?.toString().trim();
    if (content == null || content.isEmpty) {
      throw StateError('Chatbot API returned an empty response.');
    }

    return content;
  }

  String _chatCompletionUrl(String baseUrl) {
    final normalized = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    if (normalized.endsWith('/chat/completions')) return normalized;
    return '$normalized/chat/completions';
  }

  Future<void> _touchConversation(
    String conversationId,
    String firstUserMessage,
  ) async {
    final title = firstUserMessage.length > 48
        ? '${firstUserMessage.substring(0, 48)}...'
        : firstUserMessage;
    await context.client.from('chatbot_conversations').update({
      'title': title,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('conversation_id', conversationId);
  }
}

class ChatbotSendResult {
  final ChatbotConversation conversation;
  final List<ChatbotLogModel> logs;

  const ChatbotSendResult({
    required this.conversation,
    required this.logs,
  });
}
