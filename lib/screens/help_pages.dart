import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          _FAQTile(q: 'How do I pay my fees?', a: 'You can pay through the integrated eSewa or Khalti payment gateways available in the Fees section.'),
          _FAQTile(q: 'How to request a transcript?', a: 'Visit the Registrar office or use the "Official Record Request" module in your profile settings.'),
          _FAQTile(q: 'Where is the library located?', a: 'The central library is situated in Block B, Floor 2, and is open from 8 AM to 8 PM.'),
          _FAQTile(q: 'How to reset my password?', a: 'Go to Profile > Privacy & Security > Change Password. You can change it once every 30 days.'),
        ],
      ),
    );
  }
}

class _FAQTile extends StatelessWidget {
  final String q;
  final String a;
  const _FAQTile({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        title: Text(q, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(a, style: TextStyle(fontSize: 13, color: theme.hintColor)),
          )
        ],
      ),
    );
  }
}

class LiveChatPage extends StatefulWidget {
  const LiveChatPage({super.key});

  @override
  State<LiveChatPage> createState() => _LiveChatPageState();
}

class _LiveChatPageState extends State<LiveChatPage> {
  final List<Map<String, String>> _messages = [
    {'sender': 'ai', 'text': 'Hello! I am your Academic AI Assistant powered by BWIC. How can I facilitate your learning today?'}
  ];
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  Future<void> _fetchAIResponse(String userMessage) async {
    setState(() => _isTyping = true);
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(AppConfig.mistralApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.mistralApiKey}',
        },
        body: jsonEncode({
          'model': 'open-mistral-7b',
          'messages': [
            {'role': 'system', 'content': 'You are the official AI Assistant for Bridgewater International College (BWIC). You know everything about the college, the academic programs, and the faculty. The official website is bridgewater.edu.np. You can answer questions about schedules, fees, attendance, and general orientation. Keep answers professional and helpful.'},
            {'role': 'user', 'content': userMessage},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['choices'][0]['message']['content'];
        setState(() {
          _messages.add({'sender': 'ai', 'text': aiText});
          _isTyping = false;
        });
      } else {
        setState(() {
          _messages.add({'sender': 'ai', 'text': 'Oops! I encountered an error. Status: ${response.statusCode}'});
          _isTyping = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'ai', 
          'text': 'Unable to connect to the AI assistant right now. Please check your internet connection and try again in a moment.'
        });
        _isTyping = false;
      });
    }
    _scrollToBottom();
  }

  void _sendMessage() {
    if (_msgController.text.isEmpty || _isTyping) return;
    String userMsg = _msgController.text;
    setState(() {
      _messages.add({'sender': 'user', 'text': userMsg});
      _msgController.clear();
    });
    _scrollToBottom();
    _fetchAIResponse(userMsg);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _raiseTicket() {
    String selectedTopic = 'Technical Issue';
    final List<String> topics = ['Technical Issue', 'Academic Records', 'Fee Payment', 'Library Access', 'Other'];
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 15))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.confirmation_num_rounded, color: Colors.blueAccent, size: 28),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 20)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Issue IT Ticket', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Describe your technical problem in detail and we will assign a specialized support agent.', 
                    style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13, height: 1.5)),
                const SizedBox(height: 24),
                const Text('SELECT CATEGORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: topics.map((t) {
                      final isSelected = t == selectedTopic;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(t, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          selected: isSelected,
                          onSelected: (val) => setDialogState(() => selectedTopic = t),
                          selectedColor: Colors.blueAccent,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  maxLines: 4,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g., Unable to access my results for Sem 2...',
                    hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Support Ticket issued successfully! Reference: #BC-8291'), backgroundColor: Colors.blueAccent)
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('SUBMIT TICKET', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  ),
                ),
              ],
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Academic AI Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _raiseTicket,
              icon: const Icon(Icons.confirmation_num_rounded, size: 16),
              label: const Text('TICKET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator(theme);
                }
                final m = _messages[index];
                final isAi = m['sender'] == 'ai';
                return _buildMessageBubble(m['text']!, isAi, theme);
              },
            ),
          ),
          _buildInputArea(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(Icons.smart_toy_outlined, size: 16, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('AI is thinking...', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isAi, ThemeData theme) {
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isAi) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(Icons.smart_toy_outlined, size: 16, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isAi 
                    ? (theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.08) : Colors.white)
                    : theme.colorScheme.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isAi ? Radius.zero : const Radius.circular(20),
                    bottomRight: isAi ? const Radius.circular(20) : Radius.zero,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isAi ? (theme.brightness == Brightness.dark ? Colors.white : Colors.black87) : Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInputArea(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Theme(
                data: theme.copyWith(
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: TextField(
                  controller: _msgController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Share your academic query...',
                    hintStyle: TextStyle(color: theme.hintColor.withValues(alpha: 0.5), fontSize: 13),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Icon(_isTyping ? Icons.hourglass_empty_rounded : Icons.arrow_upward_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class SimplePage extends StatelessWidget {
  final String title;
  const SimplePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), centerTitle: true, elevation: 0, backgroundColor: Colors.transparent),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.construction_rounded, size: 80, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
             const SizedBox(height: 24),
             Text('Content for $title Coming Soon', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
             const Text('This section is under active development.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
