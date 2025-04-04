import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neusenews/providers/auth_provider.dart' as app_auth;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = Provider.of<app_auth.AuthProvider>(
      context,
      listen: false,
    );

    // Check if user is already logged in
    if (authProvider.user != null) {
      // User is logged in, navigate to dashboard
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      // User is not logged in, navigate to onboarding or login
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/header.png',
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Color(0xFFd2982a)),
          ],
        ),
      ),
    );
  }
}
