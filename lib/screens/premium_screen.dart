import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../constants.dart';

class PremiumScreen extends StatefulWidget {
  final int uuid; // Define uuid parameter here
  final String uemail; // Define uemail parameter here
  final String uphone; // Define uphone parameter here

  const PremiumScreen(
      {super.key, required this.uuid,
      required this.uemail,
      required this.uphone}); // Constructor with named parameters

  @override
  _PremiumScreenState createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  InAppWebViewController? _controller;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Premium Services',
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
            initialUrlRequest: URLRequest(url: WebUri('$baseUrl/premium/index.php?uid=${widget.uuid}&email=${widget.uemail}&phone=${widget.uphone}')),
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
