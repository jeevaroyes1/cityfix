import 'package:flutter/material.dart';
import '../../utils/chatbot_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ChatbotService _chatbotService = ChatbotService();
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  static const Color kPrimaryColor = Color(0xFF5A6F4A);


  // --- Guided FAQ State ---
  bool _showFaqChips = true;
  String? _selectedTopic;

  // --- FAQ Data ---
  static const Map<String, Map<String, List<String>>> _faqData = {
    '📋 Report Issues': {
      'icon': ['report'],
      'questions': [
        'How do I report an issue?',
        'How can I track my reported issues?',
        'What categories of issues can I report?',
        'How long does it take to resolve an issue?',
      ],
    },
    '🔍 Lost & Found': {
      'icon': ['lost'],
      'questions': [
        'How do I report a lost item?',
        'How do I report a found item?',
        'How can I search for my lost item?',
      ],
    },
    '👥 Community Hub': {
      'icon': ['community'],
      'questions': [
        'How do I create a community post?',
        'How can I like or comment on posts?',
        'What are community guidelines?',
      ],
    },
    '🤝 Volunteering': {
      'icon': ['volunteer'],
      'questions': [
        'How do I sign up for volunteering?',
        'What volunteer events are available?',
        'How do I create a volunteer event?',
      ],
    },
    '💰 Donations': {
      'icon': ['donate'],
      'questions': [
        'How do I donate to welfare?',
        'What payment methods are supported?',
        'Is my donation tax deductible?',
      ],
    },
    '📞 Helpline': {
      'icon': ['helpline'],
      'questions': [
        'What emergency numbers are available?',
        'How do I contact municipal authorities?',
        'How do I reach customer support?',
      ],
    },
    '📰 News & Updates': {
      'icon': ['news'],
      'questions': [
        'Where can I find local news updates?',
        'How are news articles sourced?',
      ],
    },
    '⚙️ Account & General': {
      'icon': ['account'],
      'questions': [
        'How do I update my profile?',
        'How do I change my panchayat or ward?',
        'What is CityFix?',
      ],
    },
  };

  void _sendMessage([String? prefilled]) async {
    final text = (prefilled ?? _controller.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
      _controller.clear();
      _showFaqChips = false;
      _selectedTopic = null;
    });
    _scrollToBottom();

    final response = await _chatbotService.sendMessage(text);

    setState(() {
      _messages.add({'role': 'bot', 'content': response});
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _onTopicTapped(String topic) {
    setState(() {
      _selectedTopic = topic;
    });
  }

  void _onBackToTopics() {
    setState(() {
      _selectedTopic = null;
    });
  }

  void _onQuestionTapped(String question) {
    _sendMessage(question);
  }

  void _toggleFaq() {
    setState(() {
      _showFaqChips = !_showFaqChips;
      _selectedTopic = null;
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text("CityFix AI Assistant",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && _showFaqChips
                ? _buildWelcomeView()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      return _buildChatBubble(msg['content']!, isUser);
                    },
                  ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: kPrimaryColor),
              ),
            ),
          // Show FAQ chips panel (when toggled on and messages exist)
          if (_showFaqChips && _messages.isNotEmpty) _buildFaqPanel(),
          _buildInputArea(),
        ],
      ),
    );
  }

  // --- Welcome View (shown when no messages yet) ---
  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.smart_toy_outlined,
                size: 48, color: kPrimaryColor),
          ),
          const SizedBox(height: 16),
          const Text(
            "Hi! I'm your CityFix Assistant",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333)),
          ),
          const SizedBox(height: 8),
          Text(
            "Choose a topic below or type your own question",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          if (_selectedTopic == null) _buildTopicChips(),
          if (_selectedTopic != null) _buildSubQuestions(_selectedTopic!),
        ],
      ),
    );
  }

  // --- FAQ Panel (shown below messages when toggled) ---
  Widget _buildFaqPanel() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedTopic == null) ...[
              Text("Quick Questions",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
              const SizedBox(height: 8),
              _buildTopicChips(),
            ],
            if (_selectedTopic != null) _buildSubQuestions(_selectedTopic!),
          ],
        ),
      ),
    );
  }

  // --- Topic Chips Grid ---
  Widget _buildTopicChips() {
    final topics = _faqData.keys.toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: topics.map((topic) {
        return InkWell(
          onTap: () => _onTopicTapped(topic),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kPrimaryColor.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              topic,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kPrimaryColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- Sub-Question Chips ---
  Widget _buildSubQuestions(String topic) {
    final questions = _faqData[topic]?['questions'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button row
        InkWell(
          onTap: _onBackToTopics,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_ios, size: 14, color: kPrimaryColor),
                const SizedBox(width: 4),
                Text(
                  "All Topics",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          topic,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        const SizedBox(height: 12),
        ...questions.map((q) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _onQuestionTapped(q),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 16, color: kPrimaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          q,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF444444)),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 12, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildChatBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? kPrimaryColor : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
        ),
        child: Text(
          content,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          // FAQ toggle button
          GestureDetector(
            onTap: _toggleFaq,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _showFaqChips
                    ? kPrimaryColor.withValues(alpha: 0.15)
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.help_outline,
                size: 22,
                color: _showFaqChips ? kPrimaryColor : Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Ask me anything...",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: kPrimaryColor,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
