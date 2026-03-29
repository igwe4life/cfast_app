import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../constants.dart';
import 'login_page.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  InAppWebViewController? _controller;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Signup',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue, // Set the background color to blue
        centerTitle: true,
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri('$baseUrl/register')),
            initialSettings: InAppWebViewSettings(
              transparentBackground: true,
              useShouldOverrideUrlLoading: true,
            ),
            onWebViewCreated: (controller) {
              _controller = controller;
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
              });
            },
            onLoadStop: (controller, url) async {
              setState(() {
                _isLoading = false;
              });

              await controller?.evaluateJavascript(source: "javascript:(function() { var header = document.querySelector('.header');if (header) header.parentNode.removeChild(header);var footer = document.querySelector('.main-footer');if (footer) footer.parentNode.removeChild(footer);var sidebar = document.querySelector('.col-md-4.reg-sidebar');if (sidebar) sidebar.parentNode.removeChild(sidebar);})()")
                  .then((value) => debugPrint('Header, Footer, and Sidebar removed'))
                  .catchError((onError) => debugPrint('Error removing Header, Footer, and Sidebar: $onError'));
            },
            onProgressChanged: (controller, progress) {
              if (progress == 100) {
                setState(() {
                  _isLoading = false;
                });
              } else {
                setState(() {
                  _isLoading = true;
                });
              }
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              var uri = navigationAction.request.url;
              if (uri != null && uri.toString().startsWith('$baseUrl/account')) {
                _showSuccessToast();
                _redirectToLoginScreen();
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.blue, // Set the loading indicator color
              ),
            ),
        ],
      ),
    );
  }

  void _showSuccessToast() {
    Fluttertoast.showToast(msg: 'Registration Successful!');
  }

  void _redirectToLoginScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }
}
