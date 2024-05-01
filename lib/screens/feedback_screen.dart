import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'get_feedback.dart';
import 'login_page.dart';

class FeedbackScreen extends StatefulWidget {
  final String storeName;
  final String productTitle;

  FeedbackScreen({required this.storeName, required this.productTitle});

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  bool _isLoadingFeedback = false;
  String _selectedRating = 'positive'; // Selected positive by default
  String _selectedOption = '';
  TextEditingController _feedbackController = TextEditingController();

  late int uid;
  late String name;
  late String email;
  late String photoUrl;
  late String phone;
  late String token;

  late SharedPreferences sharedPreferences;

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

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    loadAuthToken();
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

  Future<void> _provideFeedback(
      String rating, String option, String feedback) async {
    setState(() {
      _isLoadingFeedback = true;
    });
    try {
      int ratingValue;
      switch (rating) {
        case 'positive':
          ratingValue = 1;
          break;
        case 'neutral':
          ratingValue = 2;
          break;
        case 'negative':
          ratingValue = 3;
          break;
        default:
          ratingValue = 1; // Default to positive if rating is not recognized
      }

      var response = await http.post(
        Uri.parse('https://cfast.ng/cfastapi/send_feedback.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Content-Language': 'en',
          'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
          'X-AppType': 'docs',
        },
        body: jsonEncode({
          'rating': ratingValue,
          'feedback': feedback,
          'option': option,
          'product_title': widget.productTitle,
          'store_name': widget.storeName,
          'user_id': uid,
          'user_name': name,
          'user_img': photoUrl,
        }),
      );

      if (response.statusCode == 200) {
        var responseBody = response.body;
        print('Response Body: $responseBody');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Feedback for ${widget.storeName} submitted successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print(
          'Failed to provide feedback. Status Code: ${response.statusCode}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to provide feedback for ${widget.storeName}. Status Code: ${response.statusCode}. Try again later!',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error occurred while providing feedback for ${widget.storeName}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingFeedback = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Leave Feedback',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              'How was your experience?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = 'positive';
                    });
                  },
                  child: Column(
                    children: [
                      Icon(
                        Icons.thumb_up_alt,
                        color: _selectedRating == 'positive'
                            ? Colors.green
                            : Colors.grey,
                        size: 50,
                      ),
                      Text(
                        'Positive',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = 'neutral';
                    });
                  },
                  child: Column(
                    children: [
                      Icon(
                        Icons.thumbs_up_down,
                        color: _selectedRating == 'neutral'
                            ? Colors.orange
                            : Colors.grey,
                        size: 50,
                      ),
                      Text(
                        'Neutral',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = 'negative';
                    });
                  },
                  child: Column(
                    children: [
                      Icon(
                        Icons.thumb_down_alt,
                        color: _selectedRating == 'negative'
                            ? Colors.red
                            : Colors.grey,
                        size: 50,
                      ),
                      Text(
                        'Negative',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            DropdownButtonFormField(
              decoration: InputDecoration(
                labelText: 'Select an option',
                border: OutlineInputBorder(),
              ),
              value: _selectedOption.isNotEmpty ? _selectedOption : null,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedOption = newValue!;
                });
              },
              items: [
                DropdownMenuItem(
                  child: Text('Successful purchase'),
                  value: 'Successful purchase',
                ),
                DropdownMenuItem(
                  child: Text('Failed purchase'),
                  value: 'Failed purchase',
                ),
                DropdownMenuItem(
                  child: Text("Can't reach the seller"),
                  value: "Can't reach the seller",
                ),
              ],
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _feedbackController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Detailed Comment',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_selectedRating.isNotEmpty &&
                    _selectedOption.isNotEmpty &&
                    _feedbackController.text.isNotEmpty) {
                  _provideFeedback(_selectedRating, _selectedOption,
                      _feedbackController.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: _isLoadingFeedback
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : Text('Send Feedback'),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.blue),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GetFeedbackScreen(
                      //uid: uid,
                      storeName: widget.storeName,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10), // Border radius set to 10
                ),
              ),
              child: Text('View Feedback'),
            ),
          ],
        ),
      ),
    );
  }
}
