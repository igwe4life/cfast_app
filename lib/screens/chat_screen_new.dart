import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../constants.dart';
import '../models/product.dart';
import 'product_screen.dart';

///import 'product_screen_brief.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen2 extends StatefulWidget {
  final int messageId;
  final int postId;
  final String productTitle;
  final String price;
  final String description;
  final String storeName;
  final String phoneNumber;
  final Product? product;
  final String firstImageUrl;

  const ChatScreen2(
      {super.key, required this.messageId,
      required this.postId,
      required this.productTitle,
      required this.price,
      required this.description,
      required this.storeName,
      required this.phoneNumber,
      this.product,
      required this.firstImageUrl});

  @override
  _ChatScreen2State createState() => _ChatScreen2State();
}

class _ChatScreen2State extends State<ChatScreen2> {
  late List<Map<String, dynamic>> _messages;
  late Timer _timers;
  bool _isLoading = true;
  bool loading = false;

  Map<String, dynamic> productData = {};

  late int uid;
  late String name;
  late String email;
  late String photoUrl;
  late String phone;
  late String token;

  late Product defaultProduct;
  late Product defaultProduct1;

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
    _messageController = TextEditingController(text: widget.description);
    fetchData();
    loadUserProfile();
    fetchMessagesChats();
    _timers = Timer.periodic(const Duration(seconds: 15), (timer) {
      fetchMessagesChats();
    });

    defaultProduct = Product(
      title: widget.productTitle,
      description: 'This is in good condition, tested and works like new.',
      image: widget.firstImageUrl,
      //image: 'https://cfast.ng/uk-used-microsoft-16gb-256gb/80',
      price: widget.price,
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
        Uri.parse('$baseUrl/api/posts/${widget.postId}?detailed=1'),
        headers: {
          'Accept': 'application/json',
          'Content-Language': 'en',
          'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
          'X-AppType': 'docs',
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        final result = decodedResponse['result'] as Map<String, dynamic>? ?? {};

        final pictures = result['pictures'] as List? ?? [];
        final imageUrl = pictures.isNotEmpty
            ? (pictures[0] as Map<String, dynamic>)['filename_url_big'] ??
                (pictures[0] as Map<String, dynamic>)['filename_url']
            : result['listing_image'] ?? '';

        setState(() {
          productData = {
            'Title': result['title'] ?? '',
            'Price': (result['price'] ?? 0).toString(),
            'StorePhoto': result['user_photo_url'] ?? '',
            'UserStatus': 'Online',
          };
        });

        defaultProduct1 = Product(
          title: widget.productTitle,
          description: result['description'] ?? '',
          image: imageUrl.toString(),
          price: (result['price'] ?? 0).toString(),
          date: result['created_at'] ?? '',
          time: '',
          itemUrl: '',
          classID: '${widget.postId}',
          location: result['city_name'] ?? '',
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
        'https://cfast.ng/cfastapi/getfullmessages.php?token=$token&id=${widget.messageId}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final resultData = jsonData['result']['data'];
      setState(() {
        _messages = List<Map<String, dynamic>>.from(resultData);
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load messages');
    }
  }

  String formatCurrency(String price) {
    final formatCurrency = NumberFormat.currency(symbol: '₦');
    try {
      double value = double.parse(price);
      return formatCurrency.format(value);
    } catch (e) {
      return price; // Return the original price if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D4ED8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.storeName,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              productData['UserStatus'] ?? "Loading...",
              style: const TextStyle(
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
            icon: const Icon(Icons.call, color: Colors.white),
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerEffect()
          : Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductScreen(
                          product: defaultProduct1,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[100],
                          ),
                          child: (productData['StorePhoto'] != null &&
                                  (productData['StorePhoto'] as String).isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    productData['StorePhoto'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.image_outlined,
                                        size: 24,
                                        color: Colors.grey),
                                  ),
                                )
                              : const Icon(Icons.image_outlined,
                                  size: 24, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productData['Title'] ?? "",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatCurrency(
                                    productData['Price'] ?? "0.00"),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: Colors.grey[400], size: 20),
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
                        child: loading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : IconButton(
                                onPressed: () {
                                  setState(() => loading = true);
                                  _sendMessage(_messageController.text);
                                },
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
        message['user_id'] == uid; // Adjust with your user ID
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: isSentByCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
                const SizedBox(height: 4),
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
                const SizedBox(height: 4),
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
      Uri.parse('https://cfast.ng/api/threads/${widget.messageId}'),
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

      // Update state with the new message
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
        loading = false;
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

      // Also toggle loading state back to false on error
      setState(() {
        loading = false;
      });
    }
  }
}
