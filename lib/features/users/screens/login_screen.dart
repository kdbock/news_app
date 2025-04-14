import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neusenews/services/auth_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:neusenews/features/users/screens/register_screen.dart';
import 'package:neusenews/features/users/screens/password_reset_screen.dart';
import 'dart:io' show Platform;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _loginFormKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    _errorMessage = ''; // Clear previous errors

    try {
      // Check network connectivity first
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'No internet connection. Please check your network settings.';
        });
        return;
      }

      print("Attempting login with: ${_emailController.text.trim()}");

      final user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      print("Login result: ${user != null ? 'Success' : 'Failed'}");

      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        setState(
          () => _errorMessage = 'Login failed. Please check your credentials.',
        );
      }
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Exception: ${e.code} - ${e.message}");
      setState(() {
        _errorMessage = _getFirebaseError(e.code);
      });

      // If it's a network error, offer retry option
      if (e.code == 'network-request-failed') {
        _showNetworkErrorDialog();
      }
    } catch (e) {
      print("Generic error: $e");
      // Only set error message for non-Pigeon errors
      if (!e.toString().contains('PigeonUserDetails')) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      } else {
        // For Pigeon errors, check if we're logged in anyway
        if (FirebaseAuth.instance.currentUser != null && mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Add this method to show a network error dialog with options
  void _showNetworkErrorDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Network Error'),
            content: const Text(
              'Unable to connect to the server. Please check your internet connection and try again.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _login(); // Retry login
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd2982a),
                ),
                child: const Text('RETRY'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Skip authentication and go to dashboard in offline mode
                  Navigator.pushReplacementNamed(context, '/dashboard');
                },
                child: const Text('CONTINUE OFFLINE'),
              ),
            ],
          ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      print("Attempting Google sign-in");
      final user = await _authService.signInWithGoogle();
      print("Google sign-in result: ${user != null ? 'Success' : 'Failed'}");

      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        setState(
          () => _errorMessage = "Google sign-in failed: No user returned",
        );
      }
    } catch (e) {
      print("Google sign-in error: $e");
      setState(() => _errorMessage = "Google sign-in failed: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      print("Attempting Apple sign-in");
      final user = await _authService.signInWithApple();
      print("Apple sign-in result: ${user != null ? 'Success' : 'Failed'}");

      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        setState(
          () => _errorMessage = "Apple sign-in failed: No user returned",
        );
      }
    } catch (e) {
      print("Apple sign-in error: $e");
      setState(() => _errorMessage = "Apple sign-in failed: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text('Or sign in with', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Image.asset('assets/images/google_signin.png', height: 24),
              label: const Text('Sign in with Google'),
              onPressed: _signInWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(width: 16),
            if (Platform.isIOS || Platform.isMacOS)
              ElevatedButton.icon(
                icon: const Icon(Icons.apple, color: Colors.white),
                label: const Text('Sign in with Apple'),
                onPressed: _signInWithApple,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Image.asset(
                'assets/images/header.png',
                height: 85,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        toolbarHeight: 120,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 20.0),
          child: Form(
            key: _loginFormKey,
            child: Column(
              children: [
                Text(
                  'Login to your Account',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2d2c31),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email*'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password*'),
                  obscureText: true,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/password-reset');
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () {
                              if (_loginFormKey.currentState!.validate()) {
                                _login();
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: const Color(0xFFd2982a),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'LOGIN',
                              style: TextStyle(color: Colors.white),
                            ),
                  ),
                ),
                _buildSocialButtons(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFd2982a),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
