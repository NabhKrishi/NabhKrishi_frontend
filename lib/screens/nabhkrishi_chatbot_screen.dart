import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/chatbot_service.dart';

class NabhKrishiChatbotScreen extends ConsumerStatefulWidget {
  final bool isHindi;
  final String? initialPrompt;

  const NabhKrishiChatbotScreen({
    super.key,
    this.isHindi = false,
    this.initialPrompt,
  });

  @override
  ConsumerState<NabhKrishiChatbotScreen> createState() =>
      _NabhKrishiChatbotScreenState();
}

class _NabhKrishiChatbotScreenState
    extends ConsumerState<NabhKrishiChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [];
  String? _conversationId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _addInitialWelcomeMessage();
    if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
      _textController.text = widget.initialPrompt!;
    }
  }

  void _addInitialWelcomeMessage() {
    final welcomeText = widget.isHindi
        ? 'नमस्ते! मुझसे गेहूं के रोगों, लक्षणों, रोकथाम और फसल सुरक्षा के बारे में कुछ भी पूछें।'
        : 'Namaste! Ask me anything about wheat diseases, symptoms, management, and crop protection.';

    _messages.add(
      ChatMessage(
        id: 'welcome_msg',
        text: welcomeText,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage([String? prefilledText]) async {
    final text = (prefilledText ?? _textController.text).trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _errorMessage = null;
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final chatbotService = ref.read(chatbotServiceProvider);
      final response = await chatbotService.sendMessage(
        message: text,
        conversationId: _conversationId,
      );

      if (mounted) {
        setState(() {
          _conversationId = response.conversationId;
          _messages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: response.answer,
              isUser: false,
              timestamp: DateTime.now(),
              language: response.language,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Chatbot screen caught error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = widget.isHindi
              ? 'क्षमा करें, मैं नभकृषि AI से नहीं जुड़ सका। कृपया पुनः प्रयास करें।'
              : "Sorry, I couldn't connect to NabhKrishi AI. Please try again.";

          _messages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: _errorMessage!,
              isUser: false,
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  void _resetConversation() {
    HapticFeedback.mediumImpact();
    setState(() {
      _conversationId = null;
      _messages.clear();
      _errorMessage = null;
      _addInitialWelcomeMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = widget.isHindi;

    final quickSuggestions = isHindi
        ? [
            'गेहूं में पीला रतुआ क्या है?',
            'इसके लक्षण क्या हैं?',
            'इसकी रोकथाम कैसे करें?',
            'ब्लैक रस्ट के लक्षण'
          ]
        : [
            'What is yellow rust in wheat?',
            'What are its symptoms?',
            'How can it be managed?',
            'Symptoms of Black Rust'
          ];

    return Scaffold(
      backgroundColor: const Color(0xFF031A22),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07242E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFA8F6D5), Color(0xFF39C793)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF56E2AF).withValues(alpha: 0.25),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(Icons.eco_rounded,
                  color: Color(0xFF07372B), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NabhKrishi AI',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isHindi
                        ? 'गेहूं कृषि सहायक • ऑनलाइन'
                        : 'Wheat Agricultural Advisor • Online',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6CE6B6),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isHindi ? 'नई बातचीत' : 'New Chat',
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white70, size: 22),
            onPressed: _resetConversation,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick suggestion chips
            if (_messages.length <= 2)
              Container(
                height: 44,
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: quickSuggestions.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final suggestion = quickSuggestions[index];
                    return ActionChip(
                      backgroundColor: const Color(0xFF0C2A34),
                      side: BorderSide(
                        color: const Color(0xFF6CE6B6).withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      label: Text(
                        suggestion,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFB5EAD7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _handleSendMessage(suggestion);
                      },
                    );
                  },
                ),
              ),

            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return const _TypingIndicatorBubble();
                  }
                  final msg = _messages[index];
                  return _ChatMessageBubble(
                    message: msg,
                    isHindi: isHindi,
                  );
                },
              ),
            ),

            // Input Bar
            _buildInputBar(isHindi),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isHindi) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF07242E),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0C2A34),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.send,
                      maxLines: 4,
                      minLines: 1,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: isHindi
                            ? 'गेहूं के रोगों व रोकथाम के बारे में पूछें...'
                            : 'Ask about wheat diseases, symptoms, sprays...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.white30,
                          fontSize: 12,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  if (_textController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: Colors.white38, size: 18),
                      onPressed: () {
                        _textController.clear();
                        setState(() {});
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isLoading ? null : () => _handleSendMessage(),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isLoading
                      ? [Colors.grey.shade700, Colors.grey.shade800]
                      : [const Color(0xFF6CE6B6), const Color(0xFF39C793)],
                ),
                boxShadow: [
                  if (!_isLoading)
                    BoxShadow(
                      color: const Color(0xFF6CE6B6).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Icon(
                Icons.send_rounded,
                color: _isLoading
                    ? Colors.white38
                    : const Color(0xFF031A22),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isHindi;

  const _ChatMessageBubble({
    required this.message,
    required this.isHindi,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isError = message.isError;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isError
                    ? const Color(0xFFFF8B8B).withValues(alpha: 0.15)
                    : const Color(0xFF6CE6B6).withValues(alpha: 0.15),
                border: Border.all(
                  color: isError
                      ? const Color(0xFFFF8B8B).withValues(alpha: 0.3)
                      : const Color(0xFF6CE6B6).withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                isError ? Icons.error_outline_rounded : Icons.eco_rounded,
                color: isError
                    ? const Color(0xFFFF8B8B)
                    : const Color(0xFF6CE6B6),
                size: 16,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF1B4D3E)
                    : (isError
                        ? const Color(0xFF38161D)
                        : const Color(0xFF0C2A34)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: Border.all(
                  color: isUser
                      ? const Color(0xFF6CE6B6).withValues(alpha: 0.25)
                      : (isError
                          ? const Color(0xFFFF8B8B).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.08)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.text,
                    style: GoogleFonts.poppins(
                      color: isError
                          ? const Color(0xFFFFB4B4)
                          : Colors.white.withValues(alpha: 0.95),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      _formatTime(message.timestamp),
                      style: GoogleFonts.poppins(
                        color: Colors.white30,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6CE6B6).withValues(alpha: 0.2),
              ),
              child: const Icon(Icons.person_rounded,
                  color: Color(0xFF6CE6B6), size: 18),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _TypingIndicatorBubble extends StatefulWidget {
  const _TypingIndicatorBubble();

  @override
  State<_TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<_TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6CE6B6).withValues(alpha: 0.15),
              border: Border.all(
                color: const Color(0xFF6CE6B6).withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(Icons.eco_rounded,
                color: Color(0xFF6CE6B6), size: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0C2A34),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final progress = (_controller.value + delay) % 1.0;
                    final bounce = math.sin(progress * math.pi);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 7,
                      height: 7 + (bounce * 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6CE6B6)
                            .withValues(alpha: 0.4 + (bounce * 0.6)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
