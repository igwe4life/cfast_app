import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> message;

  const ChatScreen({super.key, required this.message});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add initial message to the chat screen
    _messages.add(widget.message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.message['subject'] ?? 'Chat',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1D4ED8),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['p_creator']?['name'] == 'You';
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF1D4ED8)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe
                            ? const Radius.circular(16)
                            : Radius.zero,
                        bottomRight: isMe
                            ? Radius.zero
                            : const Radius.circular(16),
                      ),
                    ),
                    constraints:
                        BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['latest_message']?['body'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message['p_creator']?['name'] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: isMe
                                ? Colors.white60
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
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

  void _sendMessage(String message) {
    // You can send the message via API here
    // For now, just add the message to the chat screen
    setState(() {
      _messages.add({
        'id': _messages.length + 1,
        'latest_message': {'body': message},
        'p_creator': {'name': 'You'}
      });
      _messageController.clear();
    });
  }
}
