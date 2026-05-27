import 'package:medtrace/data/models/chatbot_conversation_model.dart';
import 'package:medtrace/data/models/chatbot_log_model.dart';
import 'package:medtrace/data/models/chatbot_message_model.dart';
import 'package:medtrace/services/supabase/patient_service.dart';
import 'package:medtrace/services/supabase/supabase_service_context.dart';

class ChatbotService {
  final SupabaseServiceContext context;
  final PatientService patients;

  const ChatbotService(this.context, this.patients);

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
}
