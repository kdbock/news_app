import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neusenews/features/admin/Screens/admin_review_screen.dart';
import 'package:neusenews/features/admin/Screens/event_review_screen.dart';
import 'package:neusenews/features/admin/screens/analytics_dashboard.dart';
import 'package:neusenews/features/admin/screens/user_management_screen.dart';
import 'package:neusenews/features/advertising/screens/admin/ad_management_screen.dart';
import 'package:neusenews/widgets/app_drawer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _hasAdminAccess = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _checkAdminAccess();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAccess() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'You must be logged in to access this area';
        });
        return;
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final isAdmin = userDoc.data()?['isAdmin'] ?? false;

      setState(() {
        _hasAdminAccess = isAdmin;
        _isLoading = false;
        if (!isAdmin) {
          _errorMessage = 'You do not have administrator access';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error checking permissions: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2d2c31),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFd2982a)),
        ),
      );
    }

    if (!_hasAdminAccess) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2d2c31),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    () => Navigator.of(
                      context,
                    ).pushReplacementNamed('/dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd2982a),
                  foregroundColor: Colors.white,
                ),
                child: const Text('BACK TO HOME'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFd2982a),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFFd2982a),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.article), text: 'Articles'),
            Tab(icon: Icon(Icons.event), text: 'Events'),
            Tab(icon: Icon(Icons.ads_click), text: 'Ads'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
          ],
          isScrollable: true,
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          const AnalyticsDashboard(),
          const AdminReviewScreen(),
          const EventReviewScreen(),
          const AdManagementScreen(),
          const UserManagementScreen(),
        ],
      ),
    );
  }
}
