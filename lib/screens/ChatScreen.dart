import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ChatScreen(
        threadId: 0,
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final int threadId;

  const ChatScreen({super.key, required this.threadId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late List<Map<String, dynamic>> _messages;
  late Timer _timers;

  late int uid;
  late String name;
  late String email;
  late String photoUrl;
  late String phone;
  late String token;

  final TextEditingController _messageController = TextEditingController();

  Future<void> loadUserProfile() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      uid = sharedPreferences.getInt("uid") ?? 0;
      name = sharedPreferences.getString("name") ?? "Name";
      email = sharedPreferences.getString("email") ?? "Email";
      photoUrl = sharedPreferences.getString("photo_url") ?? "";
      phone = sharedPreferences.getString("phone") ?? "Phone";
      token = sharedPreferences.getString("token") ?? "token";
    });
  }

  @override
  void initState() {
    super.initState();
    loadUserProfile();
    fetchMessagesChats();
    _timers = Timer.periodic(const Duration(seconds: 15), (timer) {
      fetchMessagesChats(); // Fetch messages every 15 seconds
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timers.cancel(); // Cancel the timer when the widget is disposed
  }

  Future<void> fetchMessagesChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final url = Uri.parse(
        '$baseUrl/cfastapi/getfullmessages.php?token=$token&id=${widget.threadId}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final resultData = jsonData['result']['data'];
      setState(() {
        _messages = List<Map<String, dynamic>>.from(resultData);
      });
    } else {
      throw Exception('Failed to load messages');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Chat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1D4ED8),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message, uid);
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      filled: true,
                      fillColor: const Color(0xFFF3F6FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D4ED8),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () =>
                        _sendMessage(_messageController.text),
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, uid) {
    final isSentByCurrentUser =
        message['user_id'] == uid;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: isSentByCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSentByCurrentUser
                  ? const Color(0xFF1D4ED8)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isSentByCurrentUser
                    ? const Radius.circular(16)
                    : Radius.zero,
                bottomRight: isSentByCurrentUser
                    ? Radius.zero
                    : const Radius.circular(16),
              ),
            ),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message['body'] ?? '',
                  style: TextStyle(
                    color: isSentByCurrentUser ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message['created_at_formatted'] ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    color: isSentByCurrentUser
                        ? Colors.white60
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String message) async {
    DateTime now = DateTime.now();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final uid = prefs.getInt("uid") ?? 0;

    final response = await http.put(
      Uri.parse('$baseUrl/api/threads/${widget.threadId}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Content-Language': 'en',
        'X-AppType': 'docs',
        'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw='
      },
      body: json.encode({'body': message}),
    );

    if (response.statusCode == 200) {
      _messageController.clear(); // Clear the message text field after sending
      setState(() {
        _messages.insert(
          0,
          {
            'body': message,
            'created_at_formatted': now.toString(),
            'user_id': uid,
          },
        );
      });
    } else {
      // Handle failed message sending
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Failed to send message'),
            content: const Text('Please try again later.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}
