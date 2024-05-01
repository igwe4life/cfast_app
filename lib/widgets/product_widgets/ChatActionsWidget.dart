import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

//import '../../screens/ChatScreen.dart';
import '../../screens/MessageScreen.dart';
import '../../screens/login_page.dart';

class ChatActionsWidget extends StatefulWidget {
  final String title;
  final VoidCallback onMakeOfferPressed;
  final VoidCallback onIsAvailablePressed;
  final VoidCallback onLastPricePressed;
  final TextEditingController textEditingController;
  final VoidCallback onStartChatPressed;
  final int postId; // Add postId parameter

  ChatActionsWidget({
    required this.title,
    required this.onMakeOfferPressed,
    required this.onIsAvailablePressed,
    required this.onLastPricePressed,
    required this.textEditingController,
    required this.onStartChatPressed,
    required this.postId, // Add postId parameter
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
      //sendRequestToAPI();
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
      isStartingChat = true; // Set flag to indicate API call is in progress
    });

    final url = 'https://cfast.ng/cfastapi/start_chat.php';

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      String currentValue = widget.textEditingController.text;

      // Create a multipart request
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';

      // Set form fields
      request.fields['token'] = token!;
      request.fields['name'] = name;
      request.fields['auth_field'] = 'email';
      request.fields['email'] = email;
      request.fields['phone'] = phone;
      request.fields['phone_country'] = 'NG';
      request.fields['body'] =
          'New chat started - ${widget.title}\n\n$currentValue';
      request.fields['post_id'] = widget.postId.toString();

      // Send the request and get the response
      var response = await request.send();

      // Decode the response body
      var responseBody = await response.stream.bytesToString();
      final decodedResponse = json.decode(responseBody);

      // Extract the thread ID from the response
      final threadId = decodedResponse['thread_id'];
      final resMsg = decodedResponse['message'];

      // Display toast message with response
      ///Fluttertoast.showToast(msg: 'Chat Thread response: $resMsg');

      // Store thread ID in SharedPreferences with a unique key based on post_id
      prefs.setInt('post_${widget.postId}_thread_id', threadId);

      // Navigate to chat screen with thread ID
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            messageId: threadId,
          ),
        ),
      );
    } catch (error) {
      print('Error starting chat thread: $error');

      ///Fluttertoast.showToast(msg: 'Error starting chat thread: $error');
      // Handle error appropriately
    } finally {
      setState(() {
        isStartingChat = false; // Reset flag after API call completes
      });
    }
  }

  Future<void> checkChatStatus() async {
    //Fluttertoast.showToast(msg: 'Checking previous chat session!');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? threadId = prefs.getInt('post_${widget.postId}_thread_id');

    if (threadId != null) {
      // If thread ID is found, navigate to chat screen with thread ID
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => ChatScreen(
                  //threadId: threadId,
                  messageId: threadId,
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

    String url = 'https://cfast.ng/api/threads';
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

    String url = 'https://cfast.ng/api/threads/$threadId';

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

  Future<void> sendRequestToAPI() async {
    final url = 'https://cfast.ng/api/threads';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'multipart/form-data',
          'Accept': 'application/json',
          'Content-Language': 'en',
          'X-AppApiToken': 'Uk1DSFlVUVhIRXpHbWt6d2pIZjlPTG15akRPN2tJTUs=',
          'X-AppType': 'docs',
          'Authorization': 'Bearer $token',
        },
        body: {
          'name': name,
          'auth_field': 'email',
          'email': email,
          'phone': phone,
          'phone_country': 'NG',
          'body': widget.textEditingController.text,
          'post_id': widget.postId, // Use postId from widget parameter
        },
      );

      final responseBody = response.body;
      print('API Response: $responseBody');

      ///Fluttertoast.showToast(msg: 'Chat sent successfully: $responseBody');
    } catch (error) {
      print('Error sending request: $error');

      ///Fluttertoast.showToast(msg: 'Chat failed to start!: $error');
    }
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
                      builder: (BuildContext context) {
                        return StatefulBuilder(
                          builder:
                              (BuildContext context, StateSetter setState) {
                            return Container(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                        print('Entered offer: $enteredOffer');
                                      });
                                    },
                                  ),
                                  SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (enteredOffer.isNotEmpty) {
                                        setState(() {
                                          // Show loading indicator
                                          _isOfferLoading = true;
                                        });

                                        try {
                                          // Make API call to send offer
                                          var response = await http.post(
                                            Uri.parse(
                                                'https://cfast.ng/cfastapi/send_offer.php'),
                                            body: jsonEncode({
                                              'offer': enteredOffer,
                                              'post_id': widget.postId,
                                              'user_id': uid
                                            }),
                                          );

                                          if (response.statusCode == 200) {
                                            // Offer sent successfully
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Offer submitted successfully!'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } else {
                                            // Offer sending failed
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Offer sending failed! Status Code: ${response.statusCode}'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          // Error occurred during API call
                                          Fluttertoast.showToast(
                                              msg:
                                                  'Error occurred while sending offer: $e');
                                        } finally {
                                          setState(() {
                                            // Hide loading indicator
                                            _isOfferLoading = false;
                                          });

                                          // Close the bottom sheet
                                          Navigator.pop(context);
                                        }
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
                                    child: _isOfferLoading
                                        ? CircularProgressIndicator() // Show loading indicator if offer is being sent
                                        : Text('Send Offer'),
                                  ),
                                ],
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
                      widget.textEditingController.text = 'Last Price';
                    });
                    widget.onLastPricePressed();
                  },
                  child: Text(
                    'Last Price',
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
