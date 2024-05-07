import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shop_cfast/screens/main_screen.dart';

import '../main.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  final storage = FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/logo.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: 24.0),
            // Email TextField
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 16.0),
            // Password TextField
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24.0),
            // Login Button with Loading Spinner
            ElevatedButton(
              onPressed: isLoading ? null : () => login(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: isLoading
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : Text(
                      'Login',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> login() async {
    setState(() {
      isLoading = true;
    });

    final String apiUrl = 'https://bworldapp.online/cfastapi/auth.php';

    var headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Content-Language': 'en',
    };

    var body = json.encode({
      "email": emailController.text,
      "password": passwordController.text,
      "auth_field": "email",
    });

    try {
      final response =
          await http.post(Uri.parse(apiUrl), headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          storeUserData(responseData);
          showSuccessDialog();
        } else {
          showSnackBar('Login Failed, please try again');
        }
      } else {
        showSnackBar(
            'Failed to connect to the server. Please try again later.');
      }
    } on http.ClientException catch (e) {
      showSnackBar('Network error: $e');
    } on FormatException catch (_) {
      showSnackBar('Invalid server response. Please try again later.');
    } catch (error) {
      showSnackBar('An error occurred. Please try again later.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Login Successful'),
          content: Column(
            children: [
              Text('You have successfully logged in.'),
              SizedBox(height: 16),
              Text('Redirecting in 3 seconds...'),
            ],
          ),
        );
      },
    );

    Future.delayed(Duration(seconds: 3), () {
      Navigator.pop(context);
      navigateToHomeScreen();
    });
  }

  Future<void> storeUserData(Map<String, dynamic> data) async {
    await storage.write(key: 'authToken', value: data['extra']['authToken']);
    await storage.write(key: 'name', value: data['name'] ?? '');
    await storage.write(key: 'email', value: data['email'] ?? '');
    await storage.write(key: 'phone', value: data['phone'] ?? '');
    await storage.write(key: 'photo_url', value: data['photo_url'] ?? '');
    await storage.write(key: 'gender_id', value: data['gender_id'] ?? '0');
    await storage.write(key: 'isLoggedIn', value: '1');

    print('isLoggedIn: ${await storage.read(key: 'isLoggedIn')}');
  }

  void navigateToHomeScreen() {
    showSnackBar('Login successful', isSuccess: true);
    print('Navigating to HomeScreen');
    Fluttertoast.showToast(msg: 'Navigating to HomeScreen');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MyApp(),
      ),
    );
  }

  void showSnackBar(String message, {bool isSuccess = false}) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
      backgroundColor: isSuccess ? Colors.green.shade300 : Colors.red.shade300,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
