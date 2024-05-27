import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MessageScreen(),
    );
  }
}

class MessageScreen extends StatefulWidget {
  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  late List<Map<String, dynamic>> messages;
  late Timer _timer;
  bool _isLoading = true;

  late int uid;
  late String name;
  late String email;
  late String photoUrl;
  late String phone;
  late String token;

  @override
  void initState() {
    super.initState();
    loadUserProfile();
    fetchMessages(); // Fetch messages initially
    _timer = Timer.periodic(Duration(seconds: 15), (timer) {
      fetchMessages(); // Fetch messages every 15 seconds
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel(); // Cancel the timer when the widget is disposed
  }

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

  Future<void> fetchMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final url = Uri.parse('$baseUrl/cfastapi/getmessages.php?token=$token');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final resultData = jsonData['result']['data'];
      print(jsonData);
      setState(() {
        messages = List<Map<String, dynamic>>.from(resultData);
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load messages');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildShimmerEffect()
          : ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                bool isUnread = message["p_is_unread"] ?? false;
                return Card(
                  color: isUnread ? Colors.blue : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          NetworkImage(message["p_creator"]["photo_url"]),
                    ),
                    title: Text(
                      message["subject"],
                      style: TextStyle(
                        fontWeight:
                            isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 2, // Limit to 2 lines
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      message["latest_message"]["body"],
                      style: TextStyle(
                        fontWeight:
                            isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 2, // Limit to 2 lines
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            messageId: message['id'],
                            productTitle: '',
                            price: '',
                            storeName: '',
                            phoneNumber: '',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 8, // Number of shimmering list items
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 30.0,
            ),
            title: Container(
              height: 15.0,
              color: Colors.white,
            ),
            subtitle: Container(
              height: 10.0,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final int messageId;
  final String productTitle;
  final String price;
  final String storeName;
  final String phoneNumber;

  ChatScreen({
    required this.messageId,
    required this.productTitle,
    required this.price,
    required this.storeName,
    required this.phoneNumber,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late List<Map<String, dynamic>> _messages;
  late Timer _timers;
  bool _isLoading = true;

  late int uid;
  late String name;
  late String email;
  late String photoUrl;
  late String phone;
  late String token;

  TextEditingController _messageController = TextEditingController();

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
    _timers = Timer.periodic(Duration(seconds: 15), (timer) {
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
        '$baseUrl/cfastapi/getfullmessages.php?token=$token&id=${widget.messageId}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final resultData = jsonData['result']['data'];
      print(jsonData);
      setState(() {
        _messages = List<Map<String, dynamic>>.from(resultData);
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load messages');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          width: 100, // Adjust this width to fit your layout needs
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white, // Set the icon color to white
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              SizedBox(
                  width: 8), // Add some spacing between the icon and the avatar
              CircleAvatar(
                backgroundImage: NetworkImage(
                    'https://cfast.ng/storage/app/default/user.png'),
              ),
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.storeName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
            Text(
              widget.productTitle.length > 20
                  ? widget.productTitle.substring(0, 20) + '...'
                  : widget.productTitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              widget.price ?? 'Price not available',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              String nuphoneNumber = widget.phoneNumber;
              final Uri telUri = Uri(
                scheme: 'tel',
                path: nuphoneNumber,
              );

              if (await canLaunchUrl(telUri)) {
                await launchUrl(telUri);
              } else {
                throw 'Could not launch $telUri';
              }
            },
            icon: Icon(
              Icons.call,
              color: Colors.white, // Set the icon color to white
            ),
          ),
        ],
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildShimmerEffect()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message, uid);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                          ),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: () {
                          _sendMessage(_messageController.text);
                        },
                        child: Text('Send'),
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
        message['user_id'] == uid; // Adjust with your user ID
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: isSentByCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSentByCurrentUser ? Colors.blue : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message['body'],
                  style: TextStyle(
                      color: isSentByCurrentUser ? Colors.white : Colors.black),
                ),
                SizedBox(height: 4),
                Text(
                  // Format date and time here (message['created_at'] as String)
                  message['created_at_formatted'],
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5, // Number of shimmering list items
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 30,
                  color: Colors.white,
                ),
                SizedBox(height: 4),
                Container(
                  height: 15,
                  color: Colors.white,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _sendMessage(String message) async {
    DateTime now = DateTime.now();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final uid = prefs.getInt("uid") ?? 0;

    final response = await http.put(
      Uri.parse('$baseUrl/api/threads/${widget.messageId}'),
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
            title: Text('Failed to send message'),
            content: Text('Please try again later.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}
