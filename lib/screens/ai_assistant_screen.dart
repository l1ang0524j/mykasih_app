import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/font_size_listener.dart';
import '../services/supabase_service.dart';
import '../l10n/app_translations.dart';
import '../providers/language_provider.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _userId;

  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();
    _initializeAI();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    print('👤 当前用户ID: $userId');
    setState(() {
      _userId = userId;
    });
    if (userId != null) {
      await _loadChatHistory(userId);
    }
  }

  Future<void> _loadChatHistory(String userId) async {
    try {
      final history = await SupabaseService().getChatHistory(userId);

      final messages = history.reversed.map((item) {
        return [
          ChatMessage(
            text: item['message'],
            isUser: true,
            timestamp: DateTime.parse(item['created_at']),
          ),
          ChatMessage(
            text: item['response'],
            isUser: false,
            timestamp: DateTime.parse(item['created_at']),
          ),
        ];
      }).expand((x) => x).toList();

      setState(() {
        _messages.addAll(messages);
      });

      _scrollToBottom();
    } catch (e) {
      print('加载聊天历史失败: $e');
    }
  }

  void _initializeAI() {
    try {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: 'AIzaSyDbLrrLV8jl4Sm1j1JOC7Td2cKU6KaWYFM',
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 500,
        ),
      );

      _chat = _model.startChat();
      _sendSystemPrompt();
      _addWelcomeMessage();
    } catch (e) {
      print('Error initializing AI: $e');
    }
  }

  Future<void> _sendSystemPrompt() async {
    const systemPrompt = '''
You are a helpful assistant for MyKasih, a Malaysian government aid program. 
You can ONLY answer questions related to:
- MyKasih application process
- SARA (Sumbangan Asas Rahmah) eligibility and benefits
- Food bank locations and information
- Government aid programs in Malaysia
- MyKasih balance checking
- Participating merchants
- Bantuan SARA
- Cara mohon MyKasih
- Semak baki MyKasih

If the question is NOT related to these topics, politely say you can only answer questions about MyKasih and Malaysian government aid programs.

Keep answers concise and helpful. Use simple language. If user asks in Malay, answer in Malay. If user asks in English, answer in English.
''';

    await _chat.sendMessage(Content.text(systemPrompt));
  }

  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add(ChatMessage(
        text: "Hello! I'm your MyKasih AI Assistant. How can I help you today? You can ask me about:\n\n• SARA eligibility\n• Balance checking\n• Merchant locations\n• Food bank information\n• Application procedures\n\nSila tanya dalam Bahasa Melayu atau English.",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    final userMessage = ChatMessage(
      text: _messageController.text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _scrollToBottom();

    final userQuery = _messageController.text;
    _messageController.clear();

    try {
      final response = await _chat.sendMessage(Content.text(userQuery));

      final aiMessage = ChatMessage(
        text: response.text ?? 'Sorry, I could not generate a response.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });

      _scrollToBottom();

      if (_userId != null) {
        await SupabaseService().saveChatMessage(
          userId: _userId!,
          message: userQuery,
          response: response.text ?? 'No response',
        );
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error: Unable to connect to AI service. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _clearHistory() async {
    if (_userId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.translate(context, 'clear_history')),
        content: Text(AppTranslations.translate(context, 'clear_history_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.translate(context, 'cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await SupabaseService().clearChatHistory(_userId!);
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppTranslations.translate(context, 'history_cleared'))),
              );
            },
            child: Text(
              AppTranslations.translate(context, 'clear'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return FontSizeListener(
          child: const SizedBox(),
          builder: (context, fontSize) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  AppTranslations.translate(context, 'ai_assistant'),
                  style: TextStyle(fontSize: fontSize + 4),
                ),
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _clearHistory,
                    tooltip: AppTranslations.translate(context, 'clear_history'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      _showCapabilitiesDialog(context, fontSize);
                    },
                  ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      reverse: false,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return ChatBubble(
                          message: message,
                          fontSize: fontSize,
                        );
                      },
                    ),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  _buildMessageInput(fontSize),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput(double fontSize) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: AppTranslations.translate(context, 'type_message'),
                        hintStyle: TextStyle(fontSize: fontSize),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(fontSize: fontSize),
                      maxLines: null,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2E7D32),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showCapabilitiesDialog(BuildContext context, double fontSize) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppTranslations.translate(context, 'ai_capabilities'),
          style: TextStyle(fontSize: fontSize + 2, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCapabilityItem(
                AppTranslations.translate(context, 'sara_info'),
                AppTranslations.translate(context, 'sara_info_desc'),
                fontSize,
              ),
              _buildCapabilityItem(
                AppTranslations.translate(context, 'balance_checking'),
                AppTranslations.translate(context, 'balance_checking_desc'),
                fontSize,
              ),
              _buildCapabilityItem(
                AppTranslations.translate(context, 'merchant_locator'),
                AppTranslations.translate(context, 'merchant_locator_desc'),
                fontSize,
              ),
              _buildCapabilityItem(
                AppTranslations.translate(context, 'food_bank_info'),
                AppTranslations.translate(context, 'food_bank_info_desc'),
                fontSize,
              ),
              _buildCapabilityItem(
                AppTranslations.translate(context, 'document_help'),
                AppTranslations.translate(context, 'document_help_desc'),
                fontSize,
              ),
              _buildCapabilityItem(
                AppTranslations.translate(context, 'faq_answers'),
                AppTranslations.translate(context, 'faq_answers_desc'),
                fontSize,
              ),
              const Divider(),
              Text(AppTranslations.translate(context, 'language_support')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.translate(context, 'close'),
              style: TextStyle(fontSize: fontSize),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityItem(String title, String description, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final double fontSize;

  const ChatBubble({super.key, required this.message, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: const Icon(Icons.smart_toy, color: Colors.blue),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? const Color(0xFF2E7D32)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: message.isUser ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: fontSize - 4,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser)
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}