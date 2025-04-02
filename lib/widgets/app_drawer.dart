import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:neusenews/screens/admin/admin_dashboard_screen.dart';
import 'package:neusenews/screens/submit_news_tip.dart';
import 'package:neusenews/screens/submit_sponsored_event.dart';
import 'package:neusenews/screens/submit_sponsored_article.dart';
import 'package:neusenews/screens/profile_screen.dart';
import 'package:neusenews/screens/settings_screen.dart';
import 'package:neusenews/screens/my_contributions_screen.dart';
import 'package:neusenews/screens/investor_dashboard_screen.dart';
import 'package:neusenews/screens/advertising_options_screen.dart';
import 'package:provider/provider.dart';
import 'package:neusenews/providers/auth_provider.dart' as app_auth;
import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(
      context,
      listen: true,
    );
    final user = authProvider.user;
    final userData = authProvider.userData;

    final isAdmin = authProvider.isAdmin;
    final isContributor = authProvider.isContributor;
    final isInvestor = authProvider.isInvestor;

    String firstName = '';
    if (userData != null && userData['firstName'] != null) {
      firstName = userData['firstName'];
    } else if (user?.displayName != null) {
      firstName = user!.displayName!.split(' ').first;
    }

    log('Building drawer with user: ${user?.email}');
    log('User data: $userData');
    log('First name: $firstName');
    log(
      'User roles - Admin: $isAdmin, Contributor: $isContributor, Investor: $isInvestor',
    );

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header with logo and greeting
          Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/header.png',
                  height: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  user != null ? 'Hello, $firstName' : 'Welcome, Guest',
                  style: const TextStyle(
                    color: Color(0xFF2d2c31),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Order Classifieds Link
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFd2982a),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: const Icon(Icons.newspaper, color: Colors.white),
              title: const Text(
                'Order Classifieds',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _launchURL(
                  context,
                  'https://www.neusenews.com/order-classifieds',
                );
              },
            ),
          ),

          // Submit section
          const Divider(),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
            child: Text(
              'SUBMIT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(
              Icons.tips_and_updates,
              color: Color(0xFFd2982a),
            ),
            title: const Text('Submit News Tip'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubmitNewsTipScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.event, color: Color(0xFFd2982a)),
            title: const Text('Submit Sponsored Event'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubmitSponsoredEventScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.newspaper, color: Color(0xFFd2982a)),
            title: const Text('Submit Sponsored Article'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubmitSponsoredArticleScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.ads_click, color: Color(0xFFd2982a)),
            title: const Text('Advertise with Us'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdvertisingOptionsScreen(),
                ),
              );
            },
          ),

          // Admin section
          if (isAdmin) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 8.0),
              child: Text(
                'ADMIN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.red),
              title: const Text('Admin Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminDashboardScreen(),
                  ),
                );
              },
            ),
          ],

          // Contributor section
          if (isContributor) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 8.0),
              child: Text(
                'CONTRIBUTOR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('My Contributions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyContributionsScreen(),
                  ),
                );
              },
            ),
          ],

          // Investor section
          if (isInvestor) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 8.0),
              child: Text(
                'INVESTOR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.trending_up, color: Colors.green),
              title: const Text('Investor Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InvestorDashboardScreen(),
                  ),
                );
              },
            ),
          ],

          // Authenticated user options
          if (user != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFFd2982a)),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFFd2982a)),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFd2982a)),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await Provider.of<app_auth.AuthProvider>(
                  context,
                  listen: false,
                ).signOut();
              },
            ),
          ] else ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.login, color: Color(0xFFd2982a)),
              title: const Text('Sign In'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
            ),

            ListTile(
              leading: const Icon(Icons.person_add, color: Color(0xFFd2982a)),
              title: const Text('Register'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/register');
              },
            ),
          ],
        ],
      ),
    );
  }
}

// Helper method for launching URLs
Future<void> _launchURL(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $url')));
    }
  }
}