import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:iconsax/iconsax.dart';
import 'package:ionicons/ionicons.dart';

class LoginBottomSheet extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginBottomSheet({Key? key}) : super(key: key);

  Future<void> _login(BuildContext context) async {
    const String apiUrl = 'https://cfast.ng/api/auth/login';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Content-Language': 'en',
          'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
          'X-AppType': 'docs',
        },
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
          'auth_field': 'email',
        }),
      );

      if (response.statusCode == 200) {
        // Login successful, handle the response (e.g., store authentication token)
        // Update SharedPreferences with user login status
        Navigator.pop(context); // Close the bottom sheet upon successful login
      } else {
        // Login failed, handle error (show a message, etc.)
        // You can display an error message to the user
      }
    } catch (e) {
      // Handle exceptions
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(height: 20),
          // Image.asset(
          //   'assets/logo.png', // Replace with your logo asset path
          //   height: 80,
          //   width: 80,
          //   // Adjust height and width as needed
          // ),
          const Icon(
            Ionicons.log_in,
            size: 64,
          ),
          SizedBox(height: 20),
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _login(context);
            },
            style: ElevatedButton.styleFrom(
              primary: Colors.blue, // Set the background color to blue
              onPrimary: Colors.white, // Set text color to white
            ),
            child: const Text(
              'Login',
              style: TextStyle(
                  color: Colors.white), // In case the above line doesn't work
            ),
          ),
        ],
      ),
    );
  }
}
