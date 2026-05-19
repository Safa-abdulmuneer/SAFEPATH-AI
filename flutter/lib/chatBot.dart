import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatBotPage extends StatefulWidget {
  @override
  _ChatBotPageState createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  // Add initial welcome message
  @override
  void initState() {
    super.initState();
    // Add welcome message after a short delay
    Future.delayed(Duration(milliseconds: 300), () {
      _addBotMessage("Hello! I'm your SheCare assistant. How can I help you today? "
          "You can ask me about:\n"
          "• Safety tips\n"
          "• Emergency procedures\n"
          "• Self-defense techniques\n"
          "• Travel safety\n"
          "• Digital safety");
    });

    // Scroll to bottom when messages update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add({'sender': 'bot', 'text': text});
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': message});
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final pref = await SharedPreferences.getInstance();
      String ip = pref.getString("url") ?? "";

      if (ip.isEmpty) {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': 'Configuration error. Please check your server settings.'
          });
          _isLoading = false;
        });
        return;
      }

      String url = "$ip/myapp/user_chatbot/";
      print("🌐 Sending message to: $url");

      final response = await http.post(
        Uri.parse(url),
        body: {'message': message},
      ).timeout(Duration(seconds: 15));

      print("📡 Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String reply = data['result'] ?? 'I\'m not sure how to respond to that.';
        setState(() {
          _messages.add({'sender': 'bot', 'text': reply});
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': 'Sorry, I\'m having trouble connecting. Please try again later. (Error: ${response.statusCode})'
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Chatbot error: $e");
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': 'Connection error. Please check your internet connection and try again.'
        });
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  Widget _buildMessage(Map<String, String> message) {
    bool isUser = message['sender'] == 'user';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: EdgeInsets.only(right: 8, bottom: 4),
              child: CircleAvatar(
                backgroundColor: Colors.blueAccent,
                radius: 16,
                child: Icon(
                  Icons.assistant,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.blueAccent
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: isUser ? Radius.circular(16) : Radius.circular(4),
                  bottomRight: isUser ? Radius.circular(4) : Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(1, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    Text(
                      "SheCare Assistant",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueAccent,
                      ),
                    ),
                  if (!isUser) SizedBox(height: 2),
                  Text(
                    message['text'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      color: isUser ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isUser)
            Container(
              margin: EdgeInsets.only(left: 8, bottom: 4),
              child: CircleAvatar(
                backgroundColor: Colors.pink.shade200,
                radius: 16,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pinkAccent, Colors.pink.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.shade200.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: Icon(
                      Icons.assistant,
                      color: Colors.pinkAccent,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SheCare Assistant",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Online",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {
                      // Optional: Add menu for clearing chat, etc.
                      _showOptionsMenu(context);
                    },
                  ),
                ],
              ),
            ),
        
            // Messages area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  image: DecorationImage(
                    image: AssetImage('assets/chat_bg.png'), // Optional: add a subtle background
                    fit: BoxFit.cover,
                    opacity: 0.05,
                  ),
                ),
                child: _messages.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assistant,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Ask me anything about safety!",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "I'm here to help with all your safety questions",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[_messages.length - 1 - index];
                    return _buildMessage(msg);
                  },
                ),
              ),
            ),
        
            // Typing indicator
            if (_isLoading)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      radius: 12,
                      child: Icon(
                        Icons.assistant,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTypingDot(0),
                          SizedBox(width: 4),
                          _buildTypingDot(1),
                          SizedBox(width: 4),
                          _buildTypingDot(2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        
            // Input area
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              textInputAction: TextInputAction.send,
                              onSubmitted: sendMessage,
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: "Type your message...",
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ),
                          // IconButton(
                          //   icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
                          //   onPressed: () {
                          //     // Optional: Add file attachment
                          //   },
                          // ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Material(
                    elevation: 2,
                    shape: CircleBorder(),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.pinkAccent, Colors.pink.shade300],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(_isLoading ? Icons.hourglass_bottom : Icons.send),
                        color: Colors.white,
                        onPressed: _isLoading ? null : () => sendMessage(_controller.text),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      width: 8,
      height: 8,
      margin: EdgeInsets.only(bottom: index == 0 ? 0 : 0),
      decoration: BoxDecoration(
        color: Colors.grey.shade600,
        shape: BoxShape.circle,
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text("Clear Chat", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showClearChatConfirmation();
                },
              ),
              ListTile(
                leading: Icon(Icons.info, color: Colors.blue),
                title: Text("About SheCare Assistant"),
                onTap: () {
                  Navigator.pop(context);
                  _showAboutDialog();
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: Colors.green),
                title: Text("Share Safety Tips"),
                onTap: () {
                  Navigator.pop(context);
                  // Implement share functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearChatConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Clear Chat"),
          content: Text("Are you sure you want to clear all messages?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _messages.clear();
                });
                Navigator.pop(context);
                _addBotMessage("Chat cleared! How can I help you today?");
              },
              child: Text("Clear", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.assistant, color: Colors.pinkAccent),
              SizedBox(width: 8),
              Text("About SheCare Assistant"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SheCare Assistant is your AI-powered safety companion. "
                    "I'm here to provide you with:\n\n"
                    "• Emergency safety information\n"
                    "• Self-defense techniques\n"
                    "• Travel safety tips\n"
                    "• Digital safety advice\n"
                    "• Support and guidance\n\n"
                    "I use AI to provide accurate and helpful safety information. "
                    "For emergencies, please use the SOS button in the main app.",
                style: TextStyle(height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }
}