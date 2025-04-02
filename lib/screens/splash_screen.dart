import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showButton = false;

  @override
  void initState() {
    super.initState();

    // Show the Get Started button after 2 seconds
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showButton = true;
        });
      }
    });
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Replace the AdBanner with a static placeholder during splash
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 40.0),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text("Ad Space", style: TextStyle(color: Colors.grey)),
              ),
            ),
          ),
          // Your existing splash screen content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/loading_logo.png', width: 200),
                  const SizedBox(height: 24),
                  _showButton
                      ? const SizedBox() // Empty widget when button is shown
                      : const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFd2982a),
                        ),
                      ),
                ],
              ),
            ),
          ),

          // Get Started button at the bottom
          Padding(
            padding: const EdgeInsets.only(bottom: 60.0),
            child: AnimatedOpacity(
              opacity: _showButton ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: ElevatedButton(
                onPressed: _showButton ? _navigateToLogin : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd2982a),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  elevation: 3.0,
                ),
                child: const Text(
                  "GET STARTED",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
