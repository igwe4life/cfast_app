import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shop_cfast/screens/product_screen_brief.dart';
import 'package:shop_cfast/screens/chat_screen_new.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../models/product.dart';
import '../services/product_storage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MessageScreen2(),
    );
  }
}

class MessageScreen2 extends StatefulWidget {
  @override
  _MessageScreen2State createState() => _MessageScreen2State();
}

class _MessageScreen2State extends State<MessageScreen2> {
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
                        // MaterialPageRoute(
                        //   builder: (context) => ChatScreen2(
                        //     message: message,
                        //   ),
                        // ),
                        MaterialPageRoute(
                          builder: (context) => ChatScreen2(
                            messageId: message['id'],
                            postId: message['post_id'],
                            productTitle: message['subject'],
                            price: '',
                            description: '',
                            storeName: message["p_creator"]["name"],
                            phoneNumber: message["p_creator"]["phone"],
                            product: null,
                            firstImageUrl: 'firstImageUrl',
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
  final Map<String, dynamic> message;

  ChatScreen({required this.message});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late List<Map<String, dynamic>> _messages;
  late Timer _timers;
  Timer? _debounceTimer;
  bool _isLoading = true;
  bool _isSending = false;

  // bool loading = false;
  // bool _isSending = false; // Add this line

  Map<String, dynamic> productData = {};

  late int uid;
  late String name;
  late String email;
  late String photoUrl;
  late String phone;
  late String token;
  late String firstimg;

  late Product defaultProduct;
  late Product defaultProduct1;

  Product? product;

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
    fetchData();
    fetchMessagesChats();
    getProduct();
    _timers = Timer.periodic(Duration(seconds: 15), (timer) {
      fetchMessagesChats(); // Fetch messages every 15 seconds
    });

    defaultProduct = Product(
      title: '${widget.message['subject']}',
      description: '',
      image: '${widget.message["p_creator"]["photo_url"]}',
      price: '${productData['Price']}',
      date: '',
      time: '',
      itemUrl:
          'https://cfast.ng/uk-used-microsoft-surface-pro-4-6th-gen-core-i7-16gb-256gb/80',
      classID: '${widget.message['post_id']}',
      location: '',
      catURL: '',
    );
  }

  @override
  void dispose() {
    super.dispose();
    _timers.cancel(); // Cancel the timer when the widget is disposed
  }

  Future<void> getProduct() async {
    product = await ProductStorage.getProductByClassID(
        '${widget.message['post_id']}');
    setState(() {}); // Update the UI to display the retrieved product
  }

  // Fetch product data from the API
  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/cfastapi/post_details.php?pid=${widget.message['post_id']}'));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        setState(() {
          productData = decodedResponse;
        });

        defaultProduct1 = Product(
          title: '${widget.message['subject']}',
          description: '',
          image: '${product!.image}',
          price: '${product!.price}',
          date: '',
          time: '',
          itemUrl:
              'https://cfast.ng/uk-used-microsoft-surface-pro-4-6th-gen-core-i7-16gb-256gb/80',
          classID: '${widget.message['post_id']}',
          location: '',
          catURL: '',
        );
      } else {
        print('HTTP Error: ${response.statusCode}');
        throw Exception(
            'Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during HTTP request: $e');
    }
  }

  Future<void> fetchMessagesChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final url = Uri.parse(
        '$baseUrl/cfastapi/getfullmessages.php?token=$token&id=${widget.message['id']}');
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
          width: 50, // Adjust this width to fit your layout needs
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
                backgroundImage:
                    NetworkImage(widget.message["p_creator"]["photo_url"]),
              ),
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message["latest_message"]["p_recipient"]["name"],
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
            Text(
              productData['UserStatus'] ?? "Loading...",
              style: TextStyle(
                fontSize: 10,
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            )
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              String nuphoneNumber =
                  widget.message["latest_message"]["p_recipient"]["phone"];
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
                GestureDetector(
                  onTap: () {
                    //Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductScreenBrief(
                          product:
                              defaultProduct1, // Pass the actual Product instance
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[200], // Light grey color
                      borderRadius: BorderRadius.circular(10), // Rounded edges
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // CircleAvatar(
                            //   radius: 25, // Radius half of 40 to make it 40x40
                            //   backgroundImage:
                            //       NetworkImage(productData['StorePhoto'] ?? ""),
                            // ),
                            // SizedBox(
                            //     width:
                            //         5), // Adding space between image and text
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(product!.image ?? ""),
                                  fit: BoxFit.cover,
                                ),
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ), // Adding
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product?.title ?? "Loading...",
                                    style: TextStyle(
                                      fontSize: 14,
                                    ),
                                    maxLines: 1, // Limit to 1 line
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    product?.price ?? "0.00",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
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
                      /*ElevatedButton(
                        onPressed: () {
                          _sendMessage(_messageController.text);
                        },
                        child: Text('Send'),
                      ),*/
                      // Stack(
                      //   children: [
                      //     ElevatedButton(
                      //       onPressed: () {
                      //         // Toggle loading state
                      //         setState(() {
                      //           loading = true;
                      //         });
                      //         _sendMessage(_messageController.text);
                      //       },
                      //       child: Text('Send'),
                      //     ),
                      //     if (loading)
                      //       Positioned.fill(
                      //         child: Center(
                      //           child: CircularProgressIndicator(),
                      //         ),
                      //       ),
                      //   ],
                      // ),
                      ElevatedButton(
                        onPressed: _isSending ? null : () {
                          setState(() {
                            _isSending = true;
                          });
                          _sendMessage(_messageController.text);
                        },
                        child: _isSending
                            ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            : Text('Send'),
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
    if (_isSending) return; // Prevent sending if a message is already being sent

    setState(() {
      _isSending = true; // Set sending flag to true
    });

    DateTime now = DateTime.now();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final uid = prefs.getInt("uid") ?? 0;

    final response = await http.put(
      Uri.parse('$baseUrl/api/threads/${widget.message["id"]}'),
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
      // Clear the message text field after sending
      _messageController.clear();

      setState(() {
        _messages.insert(
          0,
          {
            'body': message,
            'created_at_formatted': now.toString(),
            'user_id': uid,
          },
        );

        // Toggle loading state back to false
        // loading = false;
        _isSending = false;
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

    setState(() {
      _isSending = false; // Reset sending flag after response
      //loading = false; // Also toggle loading state back to false on error
    });
  }

}
