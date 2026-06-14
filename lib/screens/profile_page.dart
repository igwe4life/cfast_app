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
import 'package:shop_cfast/screens/save_later.dart';
import 'package:url_launcher/url_launcher.dart';
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
  int uid = 0;
  String name = "Name";
  String email = "Email";
  String photoUrl = "";
  String phone = "Phone";
  String token = "token";

  late SharedPreferences sharedPreferences;

  Future<void> checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getString("token") == null) {
      if (mounted) {
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
  }

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        uid = sharedPreferences.getInt("uid") ?? 0;
        name = sharedPreferences.getString("name") ?? "Name";
        email = sharedPreferences.getString("email") ?? "Email";
        photoUrl = sharedPreferences.getString("photo_url") ?? "";
        phone = sharedPreferences.getString("phone") ?? "Phone";
        token = sharedPreferences.getString("token") ?? "token";
      });
    }
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

      ///showToast('Starting Response Body: ${response.body}');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1D4ED8),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildMenuSection(),
                  const SizedBox(height: 24),
                  _buildLogoutSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1D4ED8),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? const Icon(Icons.person, size: 46, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email_outlined,
                      size: 14, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    email,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_outlined,
                      size: 14, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    phone,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.phone_in_talk,
            title: "Manager's Call",
            subtitle: 'Request a callback from our team',
            color: const Color(0xFF4F46E5),
            onTap: requestCall,
          ),
          _divider(),
          _buildMenuItem(
            icon: Icons.wallet_rounded,
            title: 'My Live Ads',
            subtitle: 'View your active listings',
            color: const Color(0xFF059669),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdScreen()),
              );
            },
          ),
          _divider(),
          _buildMenuItem(
            icon: Icons.bookmark_rounded,
            title: 'My Saved Ads',
            subtitle: 'Ads you have bookmarked',
            color: const Color(0xFF2563EB),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ApiListViewScreen()),
              );
            },
          ),
          _divider(),
          _buildMenuItem(
            icon: Icons.feedback_outlined,
            title: 'My Feedback',
            subtitle: 'Ratings & reviews you have given',
            color: const Color(0xFFD97706),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GetFeedbackScreen(
                    storeName: name,
                  ),
                ),
              );
            },
          ),
          _divider(),
          _buildMenuItem(
            icon: Icons.trending_up_rounded,
            title: 'Make Money',
            subtitle: 'Learn how to earn with us',
            color: const Color(0xFFDC2626),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MakemoneyScreen()),
              );
            },
          ),
          _divider(),
          _buildMenuItem(
            icon: Icons.help_center_outlined,
            title: 'FAQ',
            subtitle: 'Frequently asked questions',
            color: const Color(0xFF7C3AED),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FaqScreen()),
              );
            },
          ),
          if (!Platform.isIOS) ...[
            _divider(),
            _buildMenuItem(
              icon: Icons.workspace_premium,
              title: 'Premium Services',
              subtitle: 'Unlock exclusive features',
              color: const Color(0xFFF59E0B),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PremiumScreen(
                        uuid: uid,
                        uemail: email,
                        uphone: phone,
                      )),
                );
              },
            ),
          ],
          _divider(),
          _buildMenuItem(
            icon: Icons.share_rounded,
            title: 'Share App',
            subtitle: 'Tell your friends about us',
            color: const Color(0xFF0891B2),
            onTap: () async {
              String androidAppLink =
                  'https://play.google.com/store/apps/details?id=com.cfast.ng';
              String iosAppLink =
                  'https://apps.apple.com/app/id6496972740';
              String message = 'Check out this awesome app:\n';
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
              Share.share(message);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.logout_rounded,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            color: const Color(0xFFDC2626),
            onTap: () async {
              bool confirmLogout = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text('Confirm Logout'),
                    content:
                        const Text('Are you sure you want to logout?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('Yes'),
                      ),
                    ],
                  );
                },
              );
              if (confirmLogout == true) {
                signOut(uid, token);
              }
            },
          ),
          _divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  bool confirmDelete = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Text('Confirm Delete'),
                        content: const Text(
                          'Are you sure you want to delete your account and all associated data?',
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                            child: const Text('Yes'),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Deleting account...'),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                    await deleteAccount(uid, token);
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => GoodbyeScreen()),
                    );
                  }
                },
                icon: const Icon(Icons.delete_forever_rounded,
                    color: Colors.redAccent),
                label: const Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.redAccent),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: Color(0xFF111827),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Colors.grey[100]),
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