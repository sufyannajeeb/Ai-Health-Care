import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const ChatApp());
}

// --- ChatApp Class (Unchanged Logic, Theme Added) ---
class ChatApp extends StatelessWidget {
  const ChatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Apply a modern, clean font and a refined color scheme
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Modern Chatbot',
      theme: ThemeData(
        primaryColor: const Color(0xFF4CAF50),
        hintColor: const Color(0xFF8BC34A),
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        appBarTheme: AppBarTheme(
          color: const Color(0xFF388E3C),
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textTheme: GoogleFonts.openSansTextTheme(
          Theme.of(context).textTheme,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ChatScreen(),
    );
  }
}

// --- ChatScreen State Class (Logic Unchanged) ---
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Added scroll controller for auto-scrolling
  List<Map<String, String>> _messages = [];

  // Function to send a message to the backend (LOGIC REMAINS IDENTICAL)
  Future<void> sendMessage(String message) async {
    // Add user's message to the UI immediately
    setState(() {
      _messages.add({"role": "user", "message": message});
    });
    _controller.clear();  // Clear the input field

    // Scroll to the latest message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? url = prefs.getString('url');  // Ensure 'url' is set in SharedPreferences

      if (url == null) {
        Fluttertoast.showToast(msg: "API URL not configured.");
        return;
      }

      // Make the network request to the backend (LOGIC REMAINS IDENTICAL)
      final response = await http.post(
        Uri.parse('$url/chatbot_response'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'message': message}),
      );

      // Check if the backend responds successfully (LOGIC REMAINS IDENTICAL)
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data.containsKey('response')) {
          setState(() {
            _messages.add({"role": "bot", "message": data['response']});
          });
        } else {
          setState(() {
            _messages.add({
              "role": "bot",
              "message": "Unexpected response format."
            });
          });
        }
      } else {
        // Handle non-200 response status (LOGIC REMAINS IDENTICAL)
        setState(() {
          _messages.add({
            "role": "bot",
            "message": "Error: ${response.body}"
          });
        });
      }
    } catch (e) {
      // Handle network errors (LOGIC REMAINS IDENTICAL)
      setState(() {
        _messages.add({
          "role": "bot",
          "message": "Failed to connect to server. Check your internet."
        });
      });
    }

    // Scroll to the new bot message
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

  // --- Widget Build (UI UPDATED) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat Assistant 🤖'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // Use the controller
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == "user";
                return ChatBubble(
                  message: message['message'] ?? '',
                  isUser: isUser,
                );
              },
            ),
          ),
          // Modernized Input Composer
          SafeArea(
            child: ChatInputComposer(
              controller: _controller,
              onSend: () {
                if (_controller.text.trim().isNotEmpty) {
                  sendMessage(_controller.text.trim());
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- New Custom Widgets for Elegance ---

// 1. ChatBubble Widget
class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatBubble({required this.message, required this.isUser, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color bubbleColor = isUser ? primaryColor : Colors.white;
    final Color textColor = isUser ? Colors.white : Colors.black87;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: isUser ? 80 : 12,
          right: isUser ? 12 : 80,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message,
          style: GoogleFonts.openSans(
            fontSize: 15,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// 2. ChatInputComposer Widget
class ChatInputComposer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInputComposer({required this.controller, required this.onSend, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Ask the AI...',
                  hintStyle: GoogleFonts.openSans(color: Colors.grey[500]),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button with modern look
          FloatingActionButton(
            mini: true,
            backgroundColor: Theme.of(context).primaryColor,
            elevation: 2,
            onPressed: onSend,
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}