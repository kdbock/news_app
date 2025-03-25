import 'package:flutter/material.dart';
import 'dart:async';
import 'package:news_app/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showGetStarted = false;

  @override
  void initState() {
    super.initState();
    // After 2 seconds, show the "Get Started" button
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showGetStarted = true;
        });
      }
    });
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo centered at the top
            Expanded(
              flex: 3,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Image.asset(
                    'assets/images/loading_logo.png',
                    // If you don't have the asset yet, use a placeholder
                    errorBuilder:
                        (context, error, stackTrace) => const Icon(
                          Icons.newspaper,
                          size: 120,
                          color: Color(0xFFd2982a),
                        ),
                  ),
                ),
              ),
            ),

            // Tagline
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Text(
                  'HYPER-LOCAL NEWS WITH NO POP-UP ADS, NO AP NEWS AND NO ONLINE SUBSCRIPTION FEES. NO KIDDING!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d2c31),
                    height: 1.3,
                  ),
                ),
              ),
            ),

            // Get Started Button (animated)
            Expanded(
              flex: 2,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _showGetStarted ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 800),
                  child: ElevatedButton(
                    onPressed: _navigateToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFd2982a),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 60,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'GET STARTED',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom space
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
