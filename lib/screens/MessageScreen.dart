import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shop_cfast/screens/product_screen_brief.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../constants.dart';
import '../models/product.dart';

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
                            postId: message['postId'],
                            productTitle: '',
                            price: '',
                            description: '',
                            storeName: '',
                            phoneNumber: '',
                            product: null,
                            firstImageUrl: 'firstImageUrl',
                            //product: widget.product,
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
  final int postId;
  final String productTitle;
  final String price;
  final String description;
  final String storeName;
  final String phoneNumber;
  final Product? product;
  final String firstImageUrl;

  ChatScreen({
    required this.messageId,
    required this.postId,
    required this.productTitle,
    required this.price,
    required this.description,
    required this.storeName,
    required this.phoneNumber,
    required this.product,
    required this.firstImageUrl,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late List<Map<String, dynamic>> _messages;
  late Timer _timers;
  bool _isLoading = true;
  Map<String, dynamic> productData = {};

  late int uid;
  late String name;
  late String email;
  late String photoUrl;
  late String phone;
  late String token;
  late String firstimg;

  late Product defaultProduct;

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
      firstimg = sharedPreferences.getString("firstImageUrl") ?? "Image";
    });
  }

  @override
  void initState() {
    super.initState();
    loadUserProfile();
    fetchData();
    fetchMessagesChats();
    _timers = Timer.periodic(Duration(seconds: 15), (timer) {
      fetchMessagesChats(); // Fetch messages every 15 seconds
    });

    defaultProduct = Product(
      title: '${widget.productTitle}',
      description: 'This is in good condition, tested and works like new.',
      image: '${widget.firstImageUrl}',
      price: '${productData['Price']}',
      date: '31st May, 2024',
      time: '8:40AM',
      itemUrl:
          'https://cfast.ng/uk-used-microsoft-surface-pro-4-6th-gen-core-i7-16gb-256gb/80',
      classID: '${widget.postId}',
      location: 'Wuse',
      catURL: '',
    );
  }

  @override
  void dispose() {
    super.dispose();
    _timers.cancel(); // Cancel the timer when the widget is disposed
  }

  // Fetch product data from the API
  Future<void> fetchData() async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/cfastapi/post_details.php?pid=${widget.postId}'));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        setState(() {
          productData = decodedResponse;
        });
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
        '$baseUrl/cfastapi/getfullmessages.php?token=$token&id=${widget.messageId}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final resultData = jsonData['result']['data'];

      final List<dynamic> listings = jsonData['result']['data'];

      List<Product> products = listings.map((item) {
        return Product(
          title: item['subject'] ?? '',
          description: item['subject'] ?? '',
          image: item['image'] ?? '',
          price: widget.price ?? '',
          date: item['date'] ?? '',
          time: item['time'] ?? '',
          itemUrl: item['url'] ?? '',
          classID: item['classID'] ?? '',
          location: item['location'] ?? '',
          catURL:
              item['url'] ?? '', // Assuming 'url' is the URL to the category
        );
      }).toList();

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
//              SizedBox(width: 8),
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 6),
            Text(
              widget.storeName,
              style: TextStyle(
                fontSize: 14,
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
                GestureDetector(
                  onTap: () {
                    // Handle tap action here
                    // _showToast(
                    //   "${productData['Title']}",
                    //   "${productData['StoreName']}",
                    //   "₦${productData['Price']}",
                    // );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductScreenBrief(
                          product:
                              defaultProduct, // Pass the actual Product instance
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
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(
                                      productData['StorePhoto'] ?? ""),
                                  fit: BoxFit.cover,
                                ),
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ), // Adding space between image and text
                            Text(
                              (productData['Title'] ?? "Loading...").length > 30
                                  ? (productData['Title']?.substring(0, 30) ??
                                          "Loading...") +
                                      '...'
                                  : productData['Title'] ?? "Loading...",
                              style: TextStyle(
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            SizedBox(width: 45),
                            Text(
                              //productData['UserStatus'] ?? "Loading...",
                              //'₦' + (productData['Price'] ?? "Loading...")
                              "₦" + (productData['Price'] ?? "Loading..."),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
                          controller: _messageController
                            ..text = widget.price ?? '',
                          decoration: InputDecoration(
                            hintText: widget.price == null
                                ? 'Enter price...'
                                : null, // Display hint text if initial value not set
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

  void _showToast(String title, String storeName, String price) {
    Fluttertoast.showToast(
      msg: "Title: $title\nStore Name: $storeName\nPrice: $price",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.grey,
      textColor: Colors.white,
      fontSize: 16.0,
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
