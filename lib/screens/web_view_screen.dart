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
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                setState(() => isLoading = true);
              },
              onPageFinished: (String url) {
                setState(() => isLoading = false);
                _injectAdBlocker();
              },
              onNavigationRequest: (NavigationRequest request) {
                // Handle external links
                if (request.url.startsWith('http') &&
                    !request.url.contains('neusenews.com')) {
                  launchUrl(
                    Uri.parse(request.url),
                    mode: LaunchMode.externalApplication,
                  );
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url));
  }

  void _injectAdBlocker() {
    // Simple ad blocker script
    controller.runJavaScript('''
      (function() {
        const adSelectors = [
          'ins.adsbygoogle',
          '[data-ad-slot]',
          '[class*="ad-"]',
          '[id*="ad-"]'
        ];
        
        adSelectors.forEach(selector => {
          document.querySelectorAll(selector).forEach(el => {
            el.style.display = 'none';
          });
        });
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              // This is the correct way to use url_launcher
              await launchUrl(
                Uri.parse(widget.url),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFd2982a)),
            ),
        ],
      ),
    );
  }
}
