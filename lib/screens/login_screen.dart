import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:news_app/services/auth_service.dart';
import 'package:news_app/screens/home_screen.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';  // Comment out temporarily

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Define both service and direct instances
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance; // Add this
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Add this
  // Remove or comment out Apple Sign-In
  // final OAuthCredential _appleCredential = AppleAuthProvider.credential('');

  // Use separate form keys for login and register
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  // Newsletter options
  bool _textAlerts = false;
  bool _dailyDigest = false;
  bool _sportsNewsletter = false;
  bool _politicalNewsletter = false;
  bool _privacyPolicyAccepted = false;

  // State
  bool _isLoading = false;
  String _errorMessage = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    ); // Login + Register tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  // --- Firebase Auth Methods ---
  // Update login method to use authService
  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      print("Attempting login with email: ${_emailController.text.trim()}");
      final user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      print("Login completed, user: $user");
      if (mounted) {
        // Try both navigation approaches to identify which works
        print("Navigating to home screen");
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print("Error during login: $e");
      setState(() => _errorMessage = "Login failed: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;

    if (!_privacyPolicyAccepted) {
      setState(() => _errorMessage = 'Please accept the privacy policy');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Use authService instead of direct Firebase calls
      final user = await _authService.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Save additional user data
      if (user != null) {
        await _saveUserData(user.uid);
      }

      if (mounted) {
        _tempNavigateToHome(); // Use direct navigation for now
      }
    } catch (e) {
      setState(() => _errorMessage = "Registration failed: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveUserData(String userId) async {
    // Implement Firestore/Database save here
    print('Saving user data for $userId');
  }

  Future<void> _signInWithGoogle() async {
    try {
      final user = await _authService.signInWithGoogle();

      if (user != null && mounted) {
        _tempNavigateToHome(); // Use direct navigation for now
      }
    } catch (e) {
      setState(() => _errorMessage = "Google sign-in failed: $e");
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent!')),
        );
        _tabController.animateTo(0);
      }
    } catch (e) {
      setState(() => _errorMessage = "Password reset failed: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'weak-password':
        return 'Password must be 6+ characters';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // --- UI Helpers ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

  void _tempNavigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
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
            IconButton(
              icon: Image.asset('assets/images/google_signin.png', height: 40),
              onPressed: _signInWithGoogle,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          // Use the login-specific form key
          key: _loginFormKey,
          child: Column(
            children: [
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
                  onPressed: _resetPassword,
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
                          : _tempNavigateToHome, // Just use the method directly
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: const Color(0xFFd2982a), // Gold
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'LOGIN',
                            style: TextStyle(color: Colors.white),
                          ),
                ),
              ),
              _buildSocialButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          // Use the register-specific form key
          key: _registerFormKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name*',
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name*',
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
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
                                  content: const SingleChildScrollView(
                                    child: Text(
                                      'Your privacy policy text goes here...',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                          ),
                      child: const Text(
                        'I have read and accept the Privacy Policy*',
                        style: TextStyle(decoration: TextDecoration.underline),
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
                    backgroundColor: const Color(0xFFd2982a), // Gold
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'REGISTER',
                            style: TextStyle(color: Colors.white),
                          ),
                ),
              ),
              _buildSocialButtons(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            // Add padding at the top to push logo down slightly
            const SizedBox(height: 8),
            // Add the centered logo
            Center(
              child: Image.asset(
                'assets/images/header.png',
                height: 85, // Adjust height as needed
                fit: BoxFit.contain,
              ),
            ),
            // Add space between logo and tabs
            const SizedBox(height: 8),
          ],
        ),
        toolbarHeight: 100, // Increase height to accommodate the logo
        backgroundColor: Colors.white, // Changed to white
        automaticallyImplyLeading: false, // Remove back button
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            color: const Color(0xFFd2982a), // Gold background for tabs
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight:
                  3.0, // Thicker indicator for white outline effect
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              dividerColor: Colors.white, // White divider
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [Tab(text: 'LOGIN'), Tab(text: 'REGISTER')],
              // Add decoration to create white border effect
              indicator: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white, width: 3.0),
                ),
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildLoginTab(), _buildRegisterTab()],
      ),
    );
  }
}
