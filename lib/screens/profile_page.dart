import 'dart:ffi';
import 'dart:io'; // For Platform checks
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

///import 'package:share/share.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shop_cfast/screens/post_list.dart';
import 'package:shop_cfast/screens/save_later.dart';
import 'package:shop_cfast/screens/saved_listing.dart';

///import 'package:shop_example/screens/saved_later.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/GridSimilar.dart';
import 'faq_screen.dart';
import 'premium_screen.dart';
import 'get_feedback.dart';
import 'login_page.dart';
import 'main_screen.dart';
import 'makemoney_screen.dart';
import 'myads_screen.dart';
import '../constants.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
    loadUserProfile();
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

  // Method to request a call
  Future<void> requestCall() async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/cfastapi/request_manager_call.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Content-Language': 'en',
          'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
          'X-AppType': 'docs',
        },
        body: jsonEncode({
          // Add any additional parameters required by the API
          'name': name,
          'phone': phone,
          'user_id': uid,
          // You can add more parameters as needed
        }),
      );

      showToast('Starting Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Request successful
        var responseBody = response.body;
        print('Successful Response Body: $responseBody');
        //showToast('Response Body: $responseBody');
        //Fluttertoast.showToast(msg: 'Request for call sent successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request for manager\'s callback sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Request failed
        print(
            'Failed to request manager\'s call. Status Code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to request manager\'s callback. Status Code: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Error occurred during the request
      print('Error: $e');
      //Fluttertoast.showToast(msg: 'Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to request manager\'s callback. Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // Wrap the Column with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(photoUrl),
                ),
              ),
              const SizedBox(height: 16),
              Text('Name: $name'),
              Text('Email: $email'),
              Text('Phone: $phone'),
              // Text('Auth Token: $token'),
              const SizedBox(height: 32),
              Card(
                elevation: 4.0,
                child: Column(
                  children: [
                    _buildListItem('Manager\'s Call', Icons.adjust, () {
                      requestCall();
                    }),
                    _buildDivider(), // Divider
                    _buildListItem('My Live Ads', Icons.adjust, () {
                      // Navigate to My Ads screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AdScreen()),
                      );
                    }),
                    _buildDivider(), // Divider
                    _buildListItem('My Saved Ads', Icons.adjust, () {
                      // Navigate to My Ads screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ApiListViewScreen()),
                      );
                    }),
                    _buildDivider(), // Divider
                    _buildListItem('My Feedback', Icons.assignment, () {
                      // Navigate to Feedback screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GetFeedbackScreen(
                            //uid: uid,
                            storeName: name,
                          ),
                        ),
                      );
                    }),
                    _buildDivider(), // Divider
                    _buildListItem('Make money', Icons.money, () {
                      // Navigate to FAQ screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MakemoneyScreen()),
                      );
                    }),
                    _buildDivider(), // Divider
                    _buildListItem('FAQ', Icons.help_center_outlined, () {
                      // Navigate to FAQ screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FaqScreen()),
                      );
                    }),
                    _buildDivider(), // Divider
                    _buildListItem('Premium Services', Icons.workspace_premium,
                        () {
                      // Navigate to FAQ screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PremiumScreen(
                                  uuid: uid,
                                  uemail: email,
                                  uphone: phone,
                                )),
                      );
                    }),
                    _buildDivider(), // Divider
                    // _buildListItem('SHARE TOKEN', Icons.share, () {
                    //   // Share the token
                    //   Share.share('Check out this token: $token');
                    // }),
                    // _buildDivider(), // Divider
                    // _buildListItem('SHARE APP', Icons.share, () async {
                    //   // Share the app link
                    //   String appLink =
                    //       'https://play.google.com/store/apps/details?id=com.cfast.ng'; // Replace with your app link
                    //   String message = 'Check out this awesome app:\n$appLink';
                    //
                    //   // Open the appropriate app store link based on the platform
                    //   String platform =
                    //       Theme.of(context).platform.toString().toLowerCase();
                    //   String storeLink = platform == 'targetplatform.android'
                    //       ? 'https://play.google.com/store/apps/details?id=com.cfast.ng'
                    //       : 'https://apps.apple.com/us/app/cfast/id1234567890';
                    //
                    //   await launch(storeLink);
                    //
                    //   // Share the app link and message
                    //   Share.share(message);
                    // }),
                    _buildListItem('SHARE APP', Icons.share, () async {
                      // Share the app link
                      String androidAppLink =
                          'https://play.google.com/store/apps/details?id=com.cfast.ng';
                      String iosAppLink =
                          'https://apps.apple.com/app/id6496972740';
                      String message = 'Check out this awesome app:\n';

                      // Determine the appropriate app store link based on the platform
                      String storeLink;
                      if (Platform.isAndroid) {
                        storeLink = androidAppLink;
                        message += androidAppLink;
                      } else if (Platform.isIOS) {
                        storeLink = iosAppLink;
                        message += iosAppLink;
                      } else {
                        throw 'Unsupported platform';
                      }

                      if (await canLaunch(storeLink)) {
                        await launch(storeLink);
                      } else {
                        throw 'Could not launch $storeLink';
                      }

                      // Share the app link and message
                      Share.share(message);
                    }),
                    _buildDivider(), // Divider
                    _buildListItem('Logout', Icons.logout, () async {
                      // Show an alert to confirm logout
                      bool confirmLogout = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Confirm Logout'),
                            content: Text('Are you sure you want to logout?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  // Dismiss the alert and return false
                                  Navigator.of(context).pop(false);
                                },
                                child: Text('No'),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Dismiss the alert and return true
                                  Navigator.of(context).pop(true);
                                },
                                child: Text('Yes'),
                              ),
                            ],
                          );
                        },
                      );

                      // If the user confirms logout, call the signOut method
                      if (confirmLogout == true) {
                        signOut(uid, token);
                      }
                    }),
                    _buildDivider(),
                    Padding(
                      padding: const EdgeInsets.only(top: 15, bottom: 15.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.all(15.0),
                        ),
                        onPressed: () async {
                          bool confirmDelete = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Confirm Delete'),
                                content: Text('Are you sure you want to delete your account and all associated data?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                    child: Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                    child: Text('Yes'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmDelete == true) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return Dialog(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 16),
                                        Text('Deleting account...'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );

                            // await signOut(uid, token);
                            await deleteAccount(uid, token);
                            Navigator.pop(context); // Close the progress dialog
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => GoodbyeScreen()),
                            );
                          }
                        },
                        // child: Text('Delete Account'),
                        child: Text(
                          "Delete Account",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> signOut(int uid, String token) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    var jsonResponse;
    try {
      // Set a flag to track whether the API call is ongoing
      bool loading = true;

      // Show a circular loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Logging out...'),
            ],
          ),
          duration: Duration(days: 1), // Set a long duration for the loader
        ),
      );

      var response = await http.get(
        Uri.parse('$baseUrl/api/auth/logout/$uid'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Content-Language': 'en',
          'X-AppType': 'docs',
          'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw='
        },
      );

      // Hide the loader
      ScaffoldMessenger.of(context).removeCurrentSnackBar();

      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse != null) {
          // Clear values
          sharedPreferences.remove("token");
          sharedPreferences.remove("status");
          sharedPreferences.remove("uid");
          sharedPreferences.remove("name");
          sharedPreferences.remove("email");
          sharedPreferences.remove("photo_url");
          sharedPreferences.remove("phone");

          // Navigate to the MainScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(),
            ),
          );

          // Show a SnackBar indicating successful logout
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout successful'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print(response.body);
        // Show a SnackBar with an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      print('Error: $error');
      // Show a SnackBar with an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> deleteAccount(int userId, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Content-Language': 'en',
        'X-AppType': 'docs',
        'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw='
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete account.');
    }

    // Remove the specified shared preferences
    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.remove("token");
    await sharedPreferences.remove("status");
    await sharedPreferences.remove("uid");
    await sharedPreferences.remove("name");
    await sharedPreferences.remove("email");
    await sharedPreferences.remove("photo_url");
    await sharedPreferences.remove("phone");
  }
}

class GoodbyeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Goodbye')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png'), // Replace with your app logo
              SizedBox(height: 20),
              Text(
                'We hate to see you go!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                'Your account and all associated data have been successfully deleted. We hope to see you again!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  exit(0); // Close the app
                },
                child: Text('Close App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}