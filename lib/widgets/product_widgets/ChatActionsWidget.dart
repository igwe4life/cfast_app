import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_cfast/models/product.dart';

//import '../../screens/ChatScreen.dart';
import '../../screens/MessageScreen.dart';
import '../../screens/login_page.dart';
import '../../constants.dart';

class ChatActionsWidget extends StatefulWidget {
  final String title;
  final VoidCallback onMakeOfferPressed;
  final VoidCallback onIsAvailablePressed;
  final VoidCallback onLastPricePressed;
  final TextEditingController textEditingController;
  final VoidCallback onStartChatPressed;
  final int postId; // Add postId parameter
  final String price;
  final String storeName;
  final String phoneNumber;
  final String firstImageUrl;
  final Product product;

  ChatActionsWidget({
    required this.title,
    required this.onMakeOfferPressed,
    required this.onIsAvailablePressed,
    required this.onLastPricePressed,
    required this.textEditingController,
    required this.onStartChatPressed,
    required this.postId, // Add postId parameter
    required this.price,
    required this.storeName,
    required this.phoneNumber,
    required this.product,
    required this.firstImageUrl,
  });

  @override
  _ChatActionsWidgetState createState() => _ChatActionsWidgetState();
}

class _ChatActionsWidgetState extends State<ChatActionsWidget> {
  late int uid;
  late String name;
  late String email;
  late String photoUrl;
  late String phone;
  late String token;

  bool _isLoading = false; // Loading indicator flag
  bool _isOfferLoading = false;
  String enteredOffer = ''; // Move outside the builder function

  bool isStartingChat = false;

  late SharedPreferences sharedPreferences;

  bool conversationStarted = false;
  late String postTitle;
  int threadId = 0;

  late String textValue; // State variable for maintaining TextField value

  Future<void> checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getString("token") == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login first!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (BuildContext context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> checkLoginStatusChat() async {
    sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getString("token") == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login first!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (BuildContext context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
    } else {
      _startOrGetConversation();
    }
  }

  @override
  void initState() {
    super.initState();
    postTitle = '${widget.postId}';
    //checkLoginStatus();
    //_loadConversationStatus();
    loadAuthToken();
    textValue = ''; // Initialize textValue
  }

  Future<void> loadAuthToken() async {
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

  _loadConversationStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    conversationStarted = prefs.getBool('conversationStarted') ?? false;
    postTitle = prefs.getString('postTitle') ?? '';
    threadId = prefs.getInt('threadId')!;
  }

  _saveConversationStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('conversationStarted', conversationStarted);
    prefs.setString('postTitle', postTitle);
    prefs.setInt('threadId', threadId);
  }

  Future<void> _startOrGetConversation() async {
    // if (conversationStarted) {
    //   _getThread();
    // } else {
    //Fluttertoast.showToast(msg: 'Start Conversation!');
    _startConversation();
    // }
  }

  Future<void> startChatThread() async {
    setState(() {
      isStartingChat = true; // Set loading state
    });

    final url = '$baseUrl/cfastapi/sendofferapp.php'; // API endpoint URL

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      String currentValue = widget.textEditingController.text;

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';

      // Populate request fields
      request.fields['token'] = token!;
      request.fields['name'] = name; // Make sure name, email, phone, etc. are defined
      request.fields['auth_field'] = 'email';
      request.fields['email'] = email;
      request.fields['phone'] = phone;
      request.fields['phone_country'] = 'NG';
      request.fields['body'] = currentValue; // Use the current value
      request.fields['post_id'] = widget.postId.toString(); // Convert postId to string

      var response = await request.send(); // Send the request
      var responseBody = await response.stream.bytesToString(); // Read response
      final decodedResponse = json.decode(responseBody); // Decode JSON response

      print(responseBody); // Print response for debugging

      // Check if the response indicates success
      if (response.statusCode == 200 && decodedResponse['success'] != null) {
        // Extract threadId if available
        final threadId = decodedResponse['thread_id'];
        if (threadId != null) {
          prefs.setInt('post_${widget.postId}_thread_id', threadId);

          // Clear the message controller after starting the chat
          widget.textEditingController.clear();

          // Navigate to the chat screen with necessary details
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                messageId: threadId,
                productTitle: widget.title,
                price: widget.price,
                description: '',
                postId: widget.postId,
                storeName: widget.storeName,
                phoneNumber: widget.phoneNumber,
                firstImageUrl: widget.firstImageUrl,
                product: widget.product,
              ),
            ),
          );
        } else {
          // Handle case where threadId is null
          throw Exception('Thread ID is null in response');
        }
      } else {
        // Handle API errors or unexpected response
        String errorMessage = decodedResponse['error'] ?? 'An error occurred';
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (error) {
      // Catch any errors during the API call
      print('Error starting chat thread: $error');
      Fluttertoast.showToast(
        msg: 'Error starting chat with merchant: $error',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      setState(() {
        isStartingChat = false; // Reset loading state
      });
    }
  }

  Future<void> checkChatStatus() async {
    //Fluttertoast.showToast(msg: 'Checking previous chat session!');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? threadId = prefs.getInt('post_${widget.postId}_thread_id');

    String currentValue = widget.textEditingController.text;

    if (threadId != null) {
      // If thread ID is found, navigate to chat screen with thread ID
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => ChatScreen(
                  //threadId: threadId,
                  messageId: threadId,
                  productTitle: widget.title,
                  price: widget.price,
                  description: currentValue,
                  storeName: widget.storeName,
                  phoneNumber: widget.phoneNumber,
                  firstImageUrl: widget.firstImageUrl,
                  postId: widget.postId,
                  product: widget.product,
                )),
      );
    } else {
      // If no thread ID is found, show AlertDialog and start chat thread
      setState(() {
        _isLoading = true;
      });

      // Start chat thread
      await startChatThread();

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startConversation() async {
    //Fluttertoast.showToast(msg: 'Start Conversation Clicked!!!');
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    String url = '$baseUrl/api/threads';
    String body = widget.textEditingController.text;

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'X-AppApiToken': 'Uk1DSFlVUVhIRXpHbWt6d2pIZjlPTG15akRPN2tJTUs=',
        'X-AppType': 'docs',
      });
      request.fields.addAll({
        'name': name,
        'auth_field': 'email',
        'email': email,
        'body': body,
        'post_id': widget.postId.toString(), // Convert postId to String
      });

      var response = await request.send();
      if (response.statusCode == 200) {
        // Handle success
        var responseData = json.decode(response.toString());
        //Fluttertoast.showToast(msg: responseData);
        setState(() {
          threadId = responseData['thread_id'];
          postTitle = responseData['post_title'];
          conversationStarted = true;
        });
        _saveConversationStatus();
        _getThread();
        print('Conversation started successfully');
      } else {
        // Handle failure
        print('Error starting conversation');
      }
    } catch (e) {
      print('Exception occurred: $e');
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  Future<void> _getThread() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    String url = '$baseUrl/api/threads/$threadId';

    try {
      var response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Content-Language': 'en',
          'X-AppApiToken': 'Uk1DSFlVUVhIRXpHbWt6d2pIZjlPTG15akRPN2tJTUs=',
          'X-AppType': 'docs',
        },
        // 'query' parameter is not used in GET requests
      );

      if (response.statusCode == 200) {
        // Process the retrieved thread details as required
        print('Retrieved chat details');

        ///showToast('Retrieved chat details: ${response.body}');
      } else {
        print('Error getting chat details');
      }
    } catch (e) {
      print('Exception occurred: $e');
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[200], // Light grey color
        borderRadius: BorderRadius.circular(10), // Rounded edges
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Text widget for 'Start cfast chat with seller'
          Text(
            'Start cfast chat with seller',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange, // Text color set to orange
            ),
          ),
          SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    checkLoginStatus(); // Call checkLoginStatus() on button click
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled:
                          true, // Allows the bottom sheet to be scrollable
                      builder: (BuildContext context) {
                        return StatefulBuilder(
                          builder:
                              (BuildContext context, StateSetter setState) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: SingleChildScrollView(
                                child: Container(
                                  padding: EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Make an Offer',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: '₦ Enter your bid',
                                          border: OutlineInputBorder(
                                            borderSide:
                                                BorderSide(color: Colors.blue),
                                          ),
                                          prefixText:
                                              '\u20A6', // Prefix text to display at all times
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          setState(() {
                                            // Update the entered offer value
                                            enteredOffer = value;
                                            print(
                                                'Entered offer: $enteredOffer');
                                          });
                                        },
                                      ),
                                      SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: () {
                                          if (enteredOffer.isNotEmpty) {
                                            setState(() {
                                              // Append the entered offer to the text controller
                                              widget.textEditingController
                                                      .text =
                                                  'I want to buy it for: ₦$enteredOffer';
                                            });

                                            // Close the bottom sheet
                                            Navigator.pop(context);
                                          } else {
                                            // Show error message if offer amount is empty
                                            Fluttertoast.showToast(
                                                msg:
                                                    'Please enter an offer amount');
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.blue,
                                        ),
                                        child: Text('Submit Offer'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue, // Text color
                    side: BorderSide(color: Colors.blue), // Border color
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10.0), // Adding border radius
                    ),
                  ),
                  child: Text(
                    'Make an Offer',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10),
                  ),
                ),
                SizedBox(width: 5), // Add some spacing between icon and text
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    side: BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: () {
                    // Fluttertoast.showToast(
                    //     msg: 'Is this available button clicked!');
                    checkLoginStatus(); // Call checkLoginStatus() on button click
                    setState(() {
                      // Set the text content within the setState method
                      widget.textEditingController.text = 'Is This Available?';
                    });
                    widget.onIsAvailablePressed();
                  },
                  child: Text(
                    'Is This Available?',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10),
                  ),
                ),
                SizedBox(width: 5), // Add some spacing between icon and text
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    side: BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: () {
                    checkLoginStatus(); // Call checkLoginStatus() on button click
                    setState(() {
                      // Set the text content within the setState method
                      widget.textEditingController.text = 'Last Price?';
                    });
                    widget.onLastPricePressed();
                  },
                  child: Text(
                    'Last Price?',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: widget.textEditingController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Colors.blue), // TextField border color
              ),
              hintText: 'Type your message...',
            ),
          ),
          SizedBox(height: 10),
          // ElevatedButton(
          ElevatedButton(
            onPressed: isStartingChat
                ? null
                : () async {
                    sharedPreferences = await SharedPreferences.getInstance();
                    if (sharedPreferences.getString("token") == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please login first!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (BuildContext context) => LoginPage(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    } else {
                      checkChatStatus();
                    }
                  },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.orange),
              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10.0), // Border radius set to 10
                ),
              ),
            ),
            child: isStartingChat
                ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : Text('Start Chat'),
          ),
        ],
      ),
    );
  }
}
