import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrace/core/config/app_config.dart';
import 'package:medtrace/data/models/models.dart';
import 'package:medtrace/domain/entities/entities.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/providers/feature_providers.dart';
import 'package:medtrace/shared/theme/app_theme.dart';

/// Chatbot page for patient-AI health conversation
/// Provides TB health guidance and medication information
class ChatbotPage extends ConsumerStatefulWidget {
  const ChatbotPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends ConsumerState<ChatbotPage> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Health Assistant')),
        body: const Center(child: Text('Not authenticated')),
      );
    }

    final conversationsState = ref.watch(chatbotConversationsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('TB Health Assistant'),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
      body: conversationsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : conversationsState.conversations.isEmpty
              ? _buildEmptyState(context, userId)
              : _buildChatView(
                  context,
                  conversationsState.conversations.first,
                  userId,
                  ref,
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String userId) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.patient.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.psychology,
                  size: 40,
                  color: AppColors.patient,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome to TB Health Assistant',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'I\'m here to help you understand TB treatment, medications, and answer your health questions based on WHO guidelines.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _startNewChat(userId, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.patient,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Start Conversation',
                  style: AppTypography.labelLarge.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.patient.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What I can help with:',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildHelpTopic('📋 Understanding TB treatment phases'),
                    _buildHelpTopic('💊 Medication information and dosage'),
                    _buildHelpTopic('✅ Treatment adherence tips'),
                    _buildHelpTopic(
                      '❓ General TB health and prevention questions',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpTopic(String topic) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(child: Text(topic, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildChatView(
    BuildContext context,
    ChatbotConversation conversation,
    String userId,
    WidgetRef ref,
  ) {
    final messagesState = ref.watch(chatbotMessagesProvider(conversation.id));

    return Column(
      children: [
        // Chat messages
        Expanded(
          child: messagesState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : messagesState.messages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messagesState.messages.length,
                      itemBuilder: (context, index) {
                        final message = messagesState.messages[index];
                        return _buildMessageBubble(message);
                      },
                    ),
        ),

        // Message input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.borderColor)),
          ),
          child: _buildMessageInput(context, conversation.id, userId, ref),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatbotMessage message) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.patient.withOpacity(0.2),
              ),
              child: Icon(Icons.psychology, size: 16, color: AppColors.patient),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.patient.withOpacity(0.9)
                    : AppColors.borderColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: AppTypography.bodySmall.copyWith(
                      color: isUser ? Colors.white : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.createdAt.formatTime,
                    style: AppTypography.caption.copyWith(
                      color: isUser ? Colors.white70 : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageInput(
    BuildContext context,
    String conversationId,
    String userId,
    WidgetRef ref,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            enabled: !_isSending,
            controller: _messageController,
            maxLines: null,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: 'Ask health question...',
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: IconButton(
                icon: const Icon(Icons.emoji_emotions_outlined),
                onPressed: () {
                  // Could add emoji picker here
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.patient,
          ),
          child: IconButton(
            icon: const Icon(Icons.send_rounded, color: Colors.white),
            onPressed: _isSending
                ? null
                : () => _sendMessage(conversationId, userId, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _sendMessage(
    String conversationId,
    String userId,
    WidgetRef ref,
  ) async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final chatbotRepository = ref.read(chatbotRepositoryProvider);
    final messagesNotifier = ref.read(
      chatbotMessagesProvider(conversationId).notifier,
    );

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await messagesNotifier.addMessage(message: message, role: 'user');

      final conversationMessages =
          ref.read(chatbotMessagesProvider(conversationId)).messages;

      final assistantResponse = await _generateAssistantResponse(
        conversationMessages: conversationMessages,
      );

      await chatbotRepository.addMessage(
        conversationId: conversationId,
        message: assistantResponse,
        role: 'assistant',
      );

      await ref
          .read(chatbotMessagesProvider(conversationId).notifier)
          .loadMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _startNewChat(String userId, WidgetRef ref) async {
    await ref
        .read(chatbotConversationsProvider(userId).notifier)
        .createConversation();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Conversation started')));
  }

  Future<String> _generateAssistantResponse({
    required List<ChatbotMessageModel> conversationMessages,
  }) async {
    if (AppConfig.openaiApiKey.trim().isEmpty) {
      return 'Saya belum terhubung ke OpenAI. Namun secara umum, ikuti jadwal obat sesuai resep dokter dan segera hubungi tenaga kesehatan bila ada efek samping berat.';
    }

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConfig.openaiApiKey}',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a compassionate TB health educator. Use simple Indonesian. Explain TB treatment, adherence, side effects, and when to seek medical help. Never replace a doctor.',
          },
          ...conversationMessages.take(20).map(
                (message) => {'role': message.role, 'content': message.message},
              ),
        ],
        'temperature': 0.3,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('OpenAI error ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>;
    final firstChoice = choices.first as Map<String, dynamic>;
    final message = firstChoice['message'] as Map<String, dynamic>;
    return (message['content'] as String?)?.trim().isNotEmpty == true
        ? message['content'] as String
        : 'Maaf, saya belum bisa memberi jawaban saat ini.';
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About TB Health Assistant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This is an AI-powered health information assistant designed specifically for TB patients.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Important Notes:',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Information is based on WHO TB treatment guidelines\n'
              '• Not a replacement for professional medical advice\n'
              '• Always consult your doctor for medical decisions\n'
              '• For emergencies, contact your healthcare provider',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}

extension _DateTimeFormatX on DateTime {
  String get formatTime {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
