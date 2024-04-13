import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'login_page.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              // When progress reaches 100%, it indicates page load is complete
              setState(() {
                _isLoading = false;
              });
            } else {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            // Ensure that the loading state is set to false when the page is finished
            setState(() {
              _isLoading = false;
            });

            // Inject JavaScript code using evaluateJavascript
            _controller
                .runJavaScript("javascript:(function() { " +
                    "var header = document.querySelector('.header');" +
                    "if (header) header.parentNode.removeChild(header);" +
                    "var footer = document.querySelector('.main-footer');" +
                    "if (footer) footer.parentNode.removeChild(footer);" +
                    "var sidebar = document.querySelector('.col-md-4.reg-sidebar');" +
                    "if (sidebar) sidebar.parentNode.removeChild(sidebar);" +
                    "})()")
                .then((value) =>
                    debugPrint('Header, Footer, and Sidebar removed'))
                .catchError((onError) => debugPrint(
                    'Error removing Header, Footer, and Sidebar: $onError'));
          },
          onWebResourceError: (WebResourceError error) {
            // Handle web resource error.
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://cfast.ng/account')) {
              _showSuccessToast();
              _redirectToLoginScreen();

              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://cfast.ng/register'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
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
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
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
        builder: (context) => LoginPage(),
      ),
    );
  }
}
