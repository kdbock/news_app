import 'package:flutter/material.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Create a single source of truth for navigation
class AppNavigator {
  static void goToDashboard(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
  }

  static void goToLogin(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showButton = false;
  bool _showDebugButton = false;
  bool _showOfflineButton = false;
  bool _navigating = false;

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

    // If still on splash after 10 seconds, show debug button
    Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showDebugButton = true;
        });
      }
    });

    // Check authentication status after a delay
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _checkAuthAndNavigate();
      }
    });
  }

  // Update the _navigateToLogin method to prevent duplicate navigation
  void _navigateToLogin() {
    if (!_navigating) {
      _navigating = true;
      AppNavigator.goToLogin(context);
    }
  }

  // Replace the _checkAuthAndNavigate method with this more reliable version
  void _checkAuthAndNavigate() async {
    // Check auth status first, then connectivity only if needed
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Go directly to dashboard if logged in
        AppNavigator.goToDashboard(context);
        return;
      }

      // Only check connectivity for non-authenticated users
      final connectivityResult = await Connectivity().checkConnectivity();

      // If we're definitely offline, show offline button but don't block navigation
      if (connectivityResult == ConnectivityResult.none) {
        if (mounted) {
          setState(() {
            _showOfflineButton = true;
          });
        }
      }

      // Always show the "Get Started" button, regardless of connectivity
      if (mounted) {
        setState(() {
          _showButton = true;
        });
      }

      // Auto-navigate to login after a delay if user doesn't interact
      if (connectivityResult != ConnectivityResult.none) {
        Timer(const Duration(seconds: 3), () {
          if (mounted && !_navigating) {
            _navigating = true;
            AppNavigator.goToLogin(context);
          }
        });
      }
    } catch (e) {
      debugPrint("Error checking auth state: $e");

      // Show both buttons on error, but don't auto-navigate
      if (mounted) {
        setState(() {
          _showButton = true;
          _showOfflineButton = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Splash screen content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/loading_logo.png', width: 240),
                  const SizedBox(height: 24),
                  const Text(
                    'HYPER-LOCAL NEWS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2d2c31),
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
                onPressed: _navigateToLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd2982a),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 16.0,
                  ),
                ),
                child: const Text(
                  'GET STARTED',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Debug button (shown after delay)
          if (_showDebugButton)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextButton(
                onPressed: () {
                  AppNavigator.goToDashboard(context);
                },
                child: const Text('Debug: Go to Dashboard'),
              ),
            ),

          // Offline mode button
          if (_showOfflineButton)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  AppNavigator.goToDashboard(context);
                },
                child: const Text('Continue Offline'),
              ),
            ),
        ],
      ),
    );
  }
}
