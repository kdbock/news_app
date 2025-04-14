import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:neusenews/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _registerFormKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  bool _textAlerts = false;
  bool _dailyDigest = false;
  bool _sportsNewsletter = false;
  bool _politicalNewsletter = false;
  bool _privacyPolicyAccepted = false;

  bool _isLoading = false;
  String _errorMessage = '';
  DateTime? _selectedDate;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _zipCodeController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;

    if (!_privacyPolicyAccepted) {
      setState(() => _errorMessage = 'Please accept the privacy policy');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _authService.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        await _saveUserData(user.uid);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getFirebaseError(e.code);
      });
    } catch (e) {
      // Handle the Pigeon error specifically
      if (e.toString().contains('PigeonUserDetails')) {
        // Check if registration was actually successful
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          // Registration was successful despite the error
          await _saveUserData(currentUser.uid);
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
          return; // Exit early to avoid showing error
        }
      }

      // For other errors, show error message
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveUserData(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'email': _emailController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'zipCode': _zipCodeController.text.trim(),
        'birthday':
            _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        'preferences': {
          'textAlerts': _textAlerts,
          'dailyDigest': _dailyDigest,
          'sportsNewsletter': _sportsNewsletter,
          'politicalNewsletter': _politicalNewsletter,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isAdmin': false,
        'isContributor': false,
        'isInvestor': false,
        'isCustomer': true,
        'userType': 'customer',
      });
      print('User data saved successfully for $userId');
    } catch (e) {
      print('Error saving user data: $e');
      // Still allow registration to succeed, just log the error
    }
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 365 * 18),
      ), // Default to 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthdayController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text('Or sign up with', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Image.asset('assets/images/google_signin.png', height: 24),
              label: const Text('Sign up with Google'),
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
                label: const Text('Sign up with Apple'),
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
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 20.0),
          child: Form(
            key: _registerFormKey,
            child: Column(
              children: [
                Text(
                  'Create an Account',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2d2c31),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name*',
                        ),
                        validator:
                            (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name*',
                        ),
                        validator:
                            (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
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
                const SizedBox(height: 15),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password*',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Required';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number*'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _zipCodeController,
                  decoration: const InputDecoration(labelText: 'ZIP Code*'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _birthdayController,
                  decoration: const InputDecoration(labelText: 'Birthday'),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Newsletter Subscriptions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                CheckboxListTile(
                  title: const Text('Text News Alerts'),
                  value: _textAlerts,
                  onChanged: (value) => setState(() => _textAlerts = value!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  title: const Text('Neuse News Daily Digest'),
                  value: _dailyDigest,
                  onChanged: (value) => setState(() => _dailyDigest = value!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  title: const Text('Neuse News Sports Newsletter'),
                  value: _sportsNewsletter,
                  onChanged:
                      (value) => setState(() => _sportsNewsletter = value!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  title: const Text('NC Political News Newsletter'),
                  value: _politicalNewsletter,
                  onChanged:
                      (value) => setState(() => _politicalNewsletter = value!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Checkbox(
                      value: _privacyPolicyAccepted,
                      onChanged:
                          (value) =>
                              setState(() => _privacyPolicyAccepted = value!),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap:
                            () => showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Privacy Policy'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Text(
                                            'PRIVACY POLICY',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Text('Last Updated: March 25, 2025'),
                                          SizedBox(height: 15),
                                          Text(
                                            'Magic Mile Media, LLC ("we," "our," or "us") operates the Neuse News, NC Political News, and Neuse News Sports mobile application (the "Service"). This Privacy Policy informs you of our policies regarding the collection, use, and disclosure of personal data when you use our Service.',
                                          ),
                                          // Privacy policy content continued here...
                                          SizedBox(height: 15),
                                          Text(
                                            'CONTACT US',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            'If you have any questions about this Privacy Policy, please contact us at:\n'
                                            'Magic Mile Media, LLC\n'
                                            'Email: privacy@magicmilemedia.com\n'
                                            'Phone: (252) 555-1212',
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          setState(
                                            () => _privacyPolicyAccepted = true,
                                          );
                                        },
                                        child: const Text(
                                          'Accept',
                                          style: TextStyle(
                                            color: Color(0xFFd2982a),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                            ),
                        child: const Text(
                          'I have read and accept the Privacy Policy*',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                    onPressed: _isLoading ? null : _register,
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
                              'REGISTER',
                              style: TextStyle(color: Colors.white),
                            ),
                  ),
                ),
                _buildSocialButtons(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Login',
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
