import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:news_app/screens/edit_profile_screen.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;

  // User data
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  String _zipCode = '';
  String _birthday = '';
  bool _textAlerts = false;
  bool _dailyDigest = false;
  bool _sportsNewsletter = false;
  bool _politicalNewsletter = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Get current user
      final user = _auth.currentUser;

      if (user != null) {
        // In a real app, fetch additional user data from Firestore
        // For now, we'll use placeholder data + actual Firebase Auth data

        // Parse display name if available
        if (user.displayName != null) {
          final nameParts = user.displayName!.split(' ');
          _firstName = nameParts.first;
          _lastName = nameParts.length > 1 ? nameParts.last : '';
        }

        _email = user.email ?? '';

        // Mock data for demonstration (this would come from Firestore in a real app)
        _phone = '(252) 555-1234';
        _zipCode = '28577';
        _birthday = '01/01/1980';
        _textAlerts = true;
        _dailyDigest = true;
        _sportsNewsletter = false;
        _politicalNewsletter = true;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Color(0xFF2d2c31),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFFd2982a)),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFFd2982a)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => EditProfileScreen(
                        firstName: _firstName,
                        lastName: _lastName,
                        email: _email,
                        phone: _phone,
                        zipCode: _zipCode,
                        birthday: _birthday,
                        textAlerts: _textAlerts,
                        dailyDigest: _dailyDigest,
                        sportsNewsletter: _sportsNewsletter,
                        politicalNewsletter: _politicalNewsletter,
                      ),
                ),
              ).then((_) => _loadUserData()); // Refresh data when returning
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFd2982a)),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User avatar section
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFFd2982a),
                            child: Text(
                              _firstName.isNotEmpty
                                  ? _firstName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$_firstName $_lastName',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _email,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Personal Information section
                    _buildSectionHeader('Personal Information'),
                    _buildInfoItem('Email', _email),
                    _buildInfoItem('Phone', _phone),
                    _buildInfoItem('ZIP Code', _zipCode),
                    _buildInfoItem('Birthday', _birthday),

                    const SizedBox(height: 24),

                    // Newsletter Subscriptions section
                    _buildSectionHeader('Newsletter Subscriptions'),
                    _buildSubscriptionItem('Text News Alerts', _textAlerts),
                    _buildSubscriptionItem(
                      'Neuse News Daily Digest',
                      _dailyDigest,
                    ),
                    _buildSubscriptionItem(
                      'Neuse News Sports Newsletter',
                      _sportsNewsletter,
                    ),
                    _buildSubscriptionItem(
                      'NC Political News Newsletter',
                      _politicalNewsletter,
                    ),

                    const SizedBox(height: 24),

                    // Reading History section
                    _buildSectionHeader('Recent Activity'),
                    _buildActivityItem('Viewed 12 articles this month'),
                    _buildActivityItem('Commented on 3 stories'),
                    _buildActivityItem(
                      'Last login: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                    ),

                    const SizedBox(height: 24),

                    // Account Actions section
                    _buildSectionHeader('Account Actions'),

                    ListTile(
                      leading: const Icon(
                        Icons.password,
                        color: Color(0xFFd2982a),
                      ),
                      title: const Text('Change Password'),
                      onTap: () {
                        // Navigate to change password screen or show dialog
                        _showChangePasswordDialog();
                      },
                      contentPadding: EdgeInsets.zero,
                    ),

                    ListTile(
                      leading: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Delete Account',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        // Show delete account confirmation
                        _showDeleteAccountDialog();
                      },
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 32),

                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.grey[800],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Sign Out'),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFd2982a),
          ),
        ),
        const Divider(thickness: 1),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildSubscriptionItem(String title, bool isSubscribed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            isSubscribed ? Icons.check_circle : Icons.circle_outlined,
            color: isSubscribed ? const Color(0xFFd2982a) : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isSubscribed ? Colors.black : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          const Icon(Icons.history, color: Colors.grey, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter your new password below.'),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'New Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                  ),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (passwordController.text !=
                      confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passwords do not match')),
                    );
                    return;
                  }

                  try {
                    await _auth.currentUser?.updatePassword(
                      passwordController.text,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password updated successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text(
                  'Update',
                  style: TextStyle(color: Color(0xFFd2982a)),
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete your account?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'This will permanently remove your account and all associated data. This action cannot be undone.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await _auth.currentUser?.delete();
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
