import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FaqScreen extends StatefulWidget {
  @override
  _FaqScreenState createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
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
            setState(() {
              _isLoading = false;
            });

            _controller
                .runJavaScript("javascript:(function() { " +
                    "var header = document.querySelector('.header');" +
                    "if (header) header.parentNode.removeChild(header);" +
                    "var prefooter = document.querySelector('.text-center mt-4 mb-4 ms-0 me-0');" +
                    "if (prefooter) prefooter.parentNode.removeChild(prefooter);" +
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
        ),
      )
      ..loadRequest(Uri.parse('https://cfast.ng/page/faq'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FAQ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            ),
        ],
      ),
    );
  }
}
