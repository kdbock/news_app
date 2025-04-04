import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({super.key, required this.url, required this.title});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  final bool _readerModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                setState(() => _isLoading = true);
              },
              onPageFinished: (String url) {
                setState(() => _isLoading = false);
                // Inject CSS to hide Google ads
                _controller.runJavaScript('''
          document.querySelectorAll('.adsbygoogle').forEach(function(ad) {
            ad.style.display = 'none';
          });
        ''');
                // Add reader mode injection for better reading experience
                if (_readerModeEnabled) {
                  _injectReaderMode();
                }
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url));
  }

  void _injectReaderMode() {
    _controller.runJavaScript('''
      document.body.style.fontSize = '18px';
      document.body.style.lineHeight = '1.6';
      document.body.style.margin = '0 auto';
      document.body.style.maxWidth = '800px';
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFFd2982a),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              final url = Uri.parse(widget.url);
              final currentContext = context;
              final state = mounted;

              try {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } catch (e) {
                if (state) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('Could not open $url')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFd2982a)),
            ),
        ],
      ),
    );
  }
}
