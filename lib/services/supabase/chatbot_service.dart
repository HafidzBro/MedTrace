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

  Future<ChatbotConversation> getConversation(String conversationId) async {
    final response = await context.client
        .from('chatbot_conversations')
        .select()
        .eq('conversation_id', conversationId)
        .single();

    return ChatbotConversationModel.fromJson(response);
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
    final existingConversation = await latestConversation(resolvedPatientId);
    final session = context.client.auth.currentSession;
    if (session == null) {
      throw StateError('User belum login.');
    }

    final response = await context.client.functions.invoke(
      'medtrace-chatbot',
      body: {
        'patient_id': resolvedPatientId,
        'conversation_id': existingConversation?.id,
        'message': trimmedMessage,
      },
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    final data = response.data;
    if (data is! Map) {
      throw StateError('Response chatbot kosong atau tidak valid.');
    }
    if (data['error'] != null) {
      throw StateError(data['error'].toString());
    }

    final conversationId = data['conversation_id']?.toString();
    if (conversationId == null || conversationId.isEmpty) {
      throw StateError('Edge Function tidak mengembalikan conversation_id.');
    }

    final conversation = await getConversation(conversationId);
    final logs = await listLogs(conversationId);
    return ChatbotSendResult(
      conversation: conversation,
      logs: logs,
    );
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
