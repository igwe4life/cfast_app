import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_cfast/screens/signup_page.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'forgot_password.dart';
import 'main_screen.dart';
import 'profile_page.dart';
import 'signup_page.dart'; // Import the SignupScreen

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light
        .copyWith(statusBarColor: Colors.transparent));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Login',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 40.0),
                    Container(
                      height: 80,
                      width: 120,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/logo.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.0),
                    TextFormField(
                      controller: emailController,
                      cursorColor: Colors.white,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        icon: Icon(Icons.email, color: Colors.black),
                        hintText: "Email",
                        border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black)),
                        hintStyle: TextStyle(color: Colors.black),
                      ),
                    ),
                    SizedBox(height: 30.0),
                    TextFormField(
                      controller: passwordController,
                      cursorColor: Colors.white,
                      obscureText: true,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        icon: Icon(Icons.lock, color: Colors.black),
                        hintText: "Password",
                        border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black)),
                        hintStyle: TextStyle(color: Colors.black),
                      ),
                    ),
                    SizedBox(height: 30.0),
                    ElevatedButton(
                      onPressed: emailController.text.isEmpty ||
                              passwordController.text.isEmpty
                          ? null
                          : () {
                              setState(() {
                                _isLoading = true;
                              });
                              signIn(emailController.text,
                                  passwordController.text);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.all(15.0),
                      ),
                      child: Text(
                        "Login",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 15.0),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignupScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.all(15.0),
                      ),
                      child: Text(
                        "Register",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 15.0),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgotPasswordWidget(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.all(15.0),
                      ),
                      child: Text(
                        "Forgot Password",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  signIn(String email, pass) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    Map data = {'email': email, 'password': pass};
    var jsonResponse = null;
    var response = await http.post(
        Uri.parse('https://cfast.ng/cfastapi/auth_login.php'),
        body: data);

    //showToast("${response.body} Login response");

    if (response.statusCode == 200) {
      jsonResponse = json.decode(response.body);
      print(
          "Login Response: $jsonResponse"); // Print the entire response for debugging

      if (jsonResponse != null && jsonResponse['status'] == 'success') {
        // Login successful
        sharedPreferences.setString("token", jsonResponse['authToken']);
        sharedPreferences.setString("status", jsonResponse['status']);
        sharedPreferences.setInt("uid", jsonResponse['uid']);
        sharedPreferences.setString("name", jsonResponse['name']);
        sharedPreferences.setString("email", jsonResponse['email']);
        sharedPreferences.setString("photo_url", jsonResponse['photo_url']);
        sharedPreferences.setString("phone", jsonResponse['phone']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(),
          ),
        );
      } else {
        // Login failed, show error message
        setState(() {
          _isLoading = false;
        });
        showToast(jsonResponse['message'] ?? "Login failed");
      }
    } else {
      // Handle HTTP error
      print("HTTP Error: ${response.statusCode}");
      print("Response body: ${response.body}");
      setState(() {
        _isLoading = false;
      });
      showToast("An error occurred. Please try again later.");
    }
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

  void showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
