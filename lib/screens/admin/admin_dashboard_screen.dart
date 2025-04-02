import 'package:flutter/material.dart';
import 'package:neusenews/screens/admin/user_management_tab.dart';
import 'package:neusenews/screens/admin/ad_management_tab.dart';
import 'package:neusenews/screens/admin/analytics_tab.dart';
import 'package:neusenews/screens/admin/content_review_tab.dart';
import 'package:neusenews/services/role_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    setState(() => _isLoading = true);
    try {
      bool isAdmin = await RoleService.hasAdminAccess();
      if (!isAdmin) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You do not have administrator access'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.article), text: 'Content Review'),
            Tab(icon: Icon(Icons.ads_click), text: 'Ads'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: const [
                  AnalyticsTab(),
                  ContentReviewTab(),
                  AdManagementTab(),
                  UserManagementTab(),
                ],
              ),
    );
  }
}
