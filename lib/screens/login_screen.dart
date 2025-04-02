import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:neusenews/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthScreen extends StatefulWidget {
  final int initialTab;

  const AuthScreen({super.key, this.initialTab = 0});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _loginFormKey = GlobalKey<FormState>();
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
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
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

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      print("Attempting login with: ${_emailController.text.trim()}");

      // Use your AuthService instead of the Provider
      // This avoids the Provider context issues
      final user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      print("Login result: ${user != null ? 'Success' : 'Failed'}");

      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Exception: ${e.code} - ${e.message}");
      setState(() {
        _errorMessage = _getFirebaseError(e.code);
      });
    } catch (e) {
      print("Generic error: $e");
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<User?> register(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'isAdmin': false,
          'isContributor': false,
          'isInvestor': false,
          'isCustomer': true,
          'userType': 'customer',
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('Registration error: ${e.message}');
      rethrow;
    }
  }

  Future<void> updateUserRolesAfterLogin(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        // If the user document doesn't exist, create a default one
        await userDoc.set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'isAdmin': false,
          'isContributor': false,
          'isInvestor': false,
          'isCustomer': true,
          'userType': 'customer',
        });
      } else {
        // Optionally, update the last login timestamp
        await userDoc.update({'lastLogin': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      debugPrint('Error updating user roles: $e');
      throw Exception('Failed to update user roles');
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
    debugPrint('Saving user data for $userId');
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
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign In is not available on this device');
      }

      if (Platform.isAndroid) {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId:
                '236600949564-5nsalftfmgc6u1r3am1lcsbpp14m71ct.apps.googleusercontent.com', // Use your Web Client ID
            redirectUri: Uri.parse(
              'https://neuse-news-df5fd.firebaseapp.com/__/auth/handler',
            ), // Use your Redirect URI
          ),
        );
      } else {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );
      }

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

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 20.0),
        child: Form(
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
                          : () {
                            if (_loginFormKey.currentState!.validate()) {
                              _login(); // Use your existing _login method instead of mixing approaches
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: const Color(0xFFd2982a),
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
        padding: const EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 20.0),
        child: Form(
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
                                        SizedBox(height: 15),
                                        Text(
                                          'INFORMATION WE COLLECT',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          '• Personal Information: Name, email address, phone number, ZIP code, and date of birth provided during registration.\n'
                                          '• Usage Data: Information on how you access and use the Service.\n'
                                          '• Device Information: Device type, operating system, and browser information.\n'
                                          '• Location Data: General location based on IP address or ZIP code.',
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'HOW WE USE YOUR INFORMATION',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          '• To provide and maintain our Service\n'
                                          '• To notify you about changes to our Service\n'
                                          '• To allow you to participate in interactive features\n'
                                          '• To provide customer support\n'
                                          '• To gather analysis to improve our Service\n'
                                          '• To send newsletters and marketing communications you have opted into\n'
                                          '• To monitor the usage of our Service\n'
                                          '• To detect, prevent and address technical issues',
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'DISCLOSURE OF DATA',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          'We may disclose your Personal Data in the following situations:\n'
                                          '• To affiliates: Including Neuse News, NC Political News, and Neuse News Sports\n'
                                          '• To service providers: To perform service-related services or assist in analyzing how our Service is used\n'
                                          '• For business transfers: In connection with any merger, acquisition, or sale of assets\n'
                                          '• With your consent: With your explicit permission\n'
                                          '• For legal requirements: To comply with legal obligations',
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'SECURITY',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          'The security of your data is important to us, but remember that no method of transmission over the Internet or method of electronic storage is 100% secure.',
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'YOUR RIGHTS',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          'You have the right to:\n'
                                          '• Access, update, or delete your personal information\n'
                                          '• Object to or restrict the processing of your personal data\n'
                                          '• Request a portable copy of your personal data\n'
                                          '• Opt out of marketing communications',
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'CHANGES TO THIS PRIVACY POLICY',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
                                        ),
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
                    backgroundColor: const Color(0xFFd2982a),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Stack(
            children: [
              Container(color: Colors.white, height: 48.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  dividerColor: Colors.transparent,
                  indicatorWeight: 0,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFFd2982a),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 6.0),
                  tabs: [
                    _buildCustomTab("LOGIN", _tabController.index == 0),
                    _buildCustomTab("REGISTER", _tabController.index == 1),
                  ],
                  onTap: (index) {
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildLoginTab(), _buildRegisterTab()],
      ),
    );
  }

  Widget _buildCustomTab(String text, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFd2982a) : const Color(0xFFb88116),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}
