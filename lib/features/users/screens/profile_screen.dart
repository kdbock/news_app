import 'package:flutter/material.dart';
import 'package:neusenews/features/users/screens/edit_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:neusenews/providers/auth_provider.dart' as app_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    // Get user data from auth provider
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final user = authProvider.user;
    final userData = authProvider.userData;

    if (user == null) {
      // Redirect to login if not authenticated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Get safe versions of user data with null checks
    final String firstName = userData?['firstName'] ?? '';
    final String lastName = userData?['lastName'] ?? '';
    final String email = user.email ?? '';
    final String phone = userData?['phone'] ?? '';
    final String zipCode = userData?['zipCode'] ?? '';
    final String birthday = formatTimestamp(userData?['birthday']);
    final bool textAlerts = userData?['textAlerts'] ?? false;
    final bool dailyDigest = userData?['dailyDigest'] ?? false;
    final bool sportsNewsletter = userData?['sportsNewsletter'] ?? false;
    final bool politicalNewsletter = userData?['politicalNewsletter'] ?? false;
    final dynamic createdAt = userData?['createdAt'];
    final String formattedDate = formatTimestamp(createdAt);

    // Display user profile
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFd2982a).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        // Safely create initials
                        _getInitials(firstName, lastName),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFd2982a),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    '$firstName $lastName',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Profile details
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Email
            _buildInfoRow('Email', email),
            const Divider(),

            // Phone
            _buildInfoRow('Phone', phone.isNotEmpty ? phone : 'Not provided'),
            const Divider(),

            // ZIP Code
            _buildInfoRow(
              'ZIP Code',
              zipCode.isNotEmpty ? zipCode : 'Not provided',
            ),
            const Divider(),

            // Birthday
            _buildInfoRow(
              'Birthday',
              birthday.isNotEmpty ? birthday : 'Not provided',
            ),

            const SizedBox(height: 32),

            // Newsletter subscriptions
            const Text(
              'Newsletter Subscriptions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildSubscriptionRow('Text News Alerts', textAlerts),
            const Divider(),

            _buildSubscriptionRow('Neuse News Daily Digest', dailyDigest),
            const Divider(),

            _buildSubscriptionRow(
              'Neuse News Sports Newsletter',
              sportsNewsletter,
            ),
            const Divider(),

            _buildSubscriptionRow(
              'NC Political News Newsletter',
              politicalNewsletter,
            ),

            const SizedBox(height: 32),

            // Edit Profile Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => EditProfileScreen(
                          firstName: firstName,
                          lastName: lastName,
                          email: email,
                          phone: phone,
                          zipCode: zipCode,
                          birthday: birthday,
                          textAlerts: textAlerts,
                          dailyDigest: dailyDigest,
                          sportsNewsletter: sportsNewsletter,
                          politicalNewsletter: politicalNewsletter,
                        ),
                  ),
                ).then((_) {
                  // Refresh user data when returning from edit profile
                  authProvider.refreshUserData();
                });
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFFd2982a),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to safely create initials
  String _getInitials(String firstName, String lastName) {
    String firstInitial =
        firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    String lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';

    // Return non-empty initials or a default
    if (firstInitial.isNotEmpty || lastInitial.isNotEmpty) {
      return '$firstInitial$lastInitial';
    }
    return 'U'; // Default for "User"
  }

  // Helper method for building info rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Helper method for building subscription rows
  Widget _buildSubscriptionRow(String label, bool isSubscribed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isSubscribed ? Colors.green[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isSubscribed ? 'Subscribed' : 'Not Subscribed',
              style: TextStyle(
                color: isSubscribed ? Colors.green[800] : Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format timestamp
  String formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('MMM d, yyyy').format(timestamp.toDate());
    }
    return 'N/A';
  }
}
