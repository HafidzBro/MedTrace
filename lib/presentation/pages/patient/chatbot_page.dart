import 'package:flutter/material.dart';
import 'package:medtrace/presentation/pages/patient/patient_mockup_widgets.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final _controller = TextEditingController();
  final _messages = <_ChatMessage>[
    const _ChatMessage(
      text:
          'Good morning! I am your TB Health Assistant. How are you feeling today? Remember, it is important to take your medication exactly as prescribed.',
      isUser: false,
    ),
    const _ChatMessage(
      text:
          'I am feeling okay, but I accidentally missed my dose last night. What should I do?',
      isUser: true,
    ),
    const _ChatMessage(
      text:
          'Thank you for letting me know. Missing a dose happens, but it is crucial to stay on track.\n\nHere is what you should do:\n\nTake the missed dose as soon as you remember.\nIf it is almost time for your next dose, skip the missed dose.\nNever take a double dose to make up for a missed one.',
      isUser: false,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PatientMockScaffold(
      currentIndex: 3,
      appBar: PatientTopBar(
        title: 'MedTrace Assistant',
        leadingIcon: Icons.medical_services_outlined,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 10, 28, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F5F5),
              border: Border(bottom: BorderSide(color: patientBorder)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.health_and_safety_outlined,
                    size: 18, color: Color(0xFF6B7275)),
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
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 18),
              children: [
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: patientNeutral,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Today, 9:41 AM',
                      style: TextStyle(color: patientMuted, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                for (final message in _messages) _Bubble(message: message),
              ],
            ),
          ),
          Container(
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
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: const Color(0xFF6B7275),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Type your message...',
                          hintStyle:
                              TextStyle(color: Color(0xFF8B9598), fontSize: 15),
                        ),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: patientTeal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _controller.clear();
    });
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}

class _Bubble extends StatelessWidget {
  final _ChatMessage message;

  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
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
                message.text,
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
