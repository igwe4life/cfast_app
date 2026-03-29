import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../constants.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  _FaqScreenState createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  InAppWebViewController? _controller;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
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
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri('$baseUrl/page/faq')),
            initialSettings: InAppWebViewSettings(
              transparentBackground: true,
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

              await controller?.evaluateJavascript(source: "javascript:(function() { var header = document.querySelector('.header');if (header) header.parentNode.removeChild(header);var prefooter = document.querySelector('.text-center mt-4 mb-4 ms-0 me-0');if (prefooter) prefooter.parentNode.removeChild(prefooter);var footer = document.querySelector('.main-footer');if (footer) footer.parentNode.removeChild(footer);var sidebar = document.querySelector('.col-md-4.reg-sidebar');if (sidebar) sidebar.parentNode.removeChild(sidebar);})()")
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
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            ),
        ],
      ),
    );
  }
}
