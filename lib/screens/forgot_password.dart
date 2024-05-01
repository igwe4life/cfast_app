import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordWidget extends StatefulWidget {
  @override
  _ForgotPasswordWidgetState createState() => _ForgotPasswordWidgetState();
}

class _ForgotPasswordWidgetState extends State<ForgotPasswordWidget> {
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Future<void> _forgotPassword() async {
    setState(() {
      _isLoading = true;
    });

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _isLoading = false;
      });

      showToast("Passwords do not match");
      return; // Exit the method if passwords don't match
    }

    String generateRandomString(int length) {
      const characters = 'abcdefghijklmnopqrstuvwxyz0123456789';
      final randoms = Random();
      return String.fromCharCodes(Iterable.generate(length,
          (_) => characters.codeUnitAt(randoms.nextInt(characters.length))));
    }

    final String apiUrl = 'https://cfast.ng/api/auth/password/reset';

    final Map<String, String> requestBody = {
      'email': _emailController.text,
      'token': generateRandomString(10),
      'auth_field': 'email',
      'phone_country': 'NG',
      'password': _passwordController.text,
      'password_confirmation': _confirmPasswordController.text,
    };

    final http.Response response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Content-Language': 'en',
        'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
        'X-AppType': 'docs',
      },
      body: jsonEncode(requestBody),
    );

    setState(() {
      _isLoading = false;
    });

    showToast("${response.body} password reset response");

    if (response.statusCode == 200) {
      // Success, handle response accordingly
      print('Password reset request successful');
      print(json.decode(response.body));

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset successfully, please login!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to login screen
      Navigator.of(context).pop();
    } else {
      // Error occurred, handle accordingly
      print('Failed to reset password');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reset password. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reset Password',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email Address'),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Enter New Password'),
                  obscureText: true,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _confirmPasswordController,
                  decoration:
                      InputDecoration(labelText: 'Confirm New Password'),
                  obscureText: true,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _forgotPassword,
                  child: Text(
                    'Reset Password',
                    style: TextStyle(
                      color: Colors.white, // Set white text color
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.blue, // Set blue background color for button
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
}
