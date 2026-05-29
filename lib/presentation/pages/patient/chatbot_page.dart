import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrace/data/models/chatbot_log_model.dart';
import 'package:medtrace/presentation/pages/patient/patient_mockup_widgets.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';

class ChatbotPage extends ConsumerStatefulWidget {
  const ChatbotPage({super.key});

  @override
  ConsumerState<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends ConsumerState<ChatbotPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(currentPatientChatbotProvider);

    ref.listen(currentPatientChatbotProvider, (previous, next) {
      final newError = next.error;
      if (newError != null && newError != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(newError)),
        );
      }
      if (next.messages.length != previous?.messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return PatientMockScaffold(
      currentIndex: 3,
      appBar: PatientTopBar(
        title: 'MedTrace Assistant',
        leadingIcon: Icons.medical_services_outlined,
        actions: [
          IconButton(
            onPressed: () => _showDisclaimer(context),
            icon: const Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      child: Column(
        children: [
          const _DisclaimerBanner(),
          Expanded(
            child: _ChatHistory(
              isLoading: chatState.isLoading,
              isSending: chatState.isSending,
              messages: chatState.messages,
              scrollController: _scrollController,
            ),
          ),
          _InputBar(
            controller: _controller,
            enabled: !chatState.isLoading && !chatState.isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    await ref.read(currentPatientChatbotProvider.notifier).send(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _showDisclaimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Medical disclaimer'),
        content: const Text(
          'MedTrace Assistant provides educational support only. It does not diagnose, prescribe medication, or replace your healthcare provider.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F5F5),
        border: Border(bottom: BorderSide(color: patientBorder)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 18,
            color: Color(0xFF6B7275),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This assistant provides educational support, not medical advice. For emergencies, please contact your healthcare provider immediately.',
              style: TextStyle(
                color: Color(0xFF434A4D),
                fontSize: 13,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatHistory extends StatelessWidget {
  final bool isLoading;
  final bool isSending;
  final List<ChatbotLogModel> messages;
  final ScrollController scrollController;

  const _ChatHistory({
    required this.isLoading,
    required this.isSending,
    required this.messages,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: patientTeal),
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 18),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: patientNeutral,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              messages.isEmpty
                  ? 'New conversation'
                  : _dateLabel(messages.first.createdAt),
              style: const TextStyle(color: patientMuted, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 22),
        if (messages.isEmpty)
          const _EmptyConversation()
        else
          for (final message in messages) _Bubble(message: message),
        if (isSending) const _TypingBubble(),
      ],
    );
  }

  static String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final sameDay =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    if (sameDay) return 'Today, $hour:$minute';
    return '${date.day}/${date.month}/${date.year}, $hour:$minute';
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Column(
        children: [
          PatientAvatar(icon: Icons.smart_toy_outlined, radius: 28),
          SizedBox(height: 18),
          Text(
            'Ask about TB treatment, adherence, or symptoms you should discuss with your care team.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: patientMuted,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: patientBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 50,
          padding: const EdgeInsets.only(left: 4, right: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFB8C3C3)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  textInputAction: TextInputAction.send,
                  onSubmitted: enabled ? (_) => onSend() : null,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Type your message...',
                    hintStyle:
                        TextStyle(color: Color(0xFF8B9598), fontSize: 15),
                  ),
                ),
              ),
              IconButton.filled(
                onPressed: enabled ? onSend : null,
                icon: const Icon(Icons.send_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: patientTeal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFBFCBCB),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatbotLogModel message;

  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUserMessage;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const PatientAvatar(icon: Icons.smart_toy_outlined, radius: 16),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isUser ? patientTeal : const Color(0xFFE1E4E4),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 14),
                ),
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  color: isUser ? Colors.white : patientText,
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 42),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          PatientAvatar(icon: Icons.smart_toy_outlined, radius: 16),
          SizedBox(width: 10),
          Flexible(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFE1E4E4),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Text(
                  'MedTrace Assistant is typing...',
                  style: TextStyle(
                    color: patientMuted,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
