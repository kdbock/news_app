import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neusenews/features/admin/Screens/admin_review_screen.dart';
import 'package:neusenews/features/admin/Screens/event_review_screen.dart';

class ContentReviewTab extends StatefulWidget {
  const ContentReviewTab({super.key});

  @override
  State<ContentReviewTab> createState() => _ContentReviewTabState();
}

class _ContentReviewTabState extends State<ContentReviewTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to be logged in to access this area'),
          ),
        );
        return;
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final bool isAdmin = userDoc.data()?['isAdmin'] ?? false;

      if (!mounted) return;
      if (!isAdmin) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have permission to access this area'),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error checking permissions: $e')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFd2982a)),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFd2982a),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Sponsored Articles'),
            Tab(text: 'Sponsored Events'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [AdminReviewScreen(), EventReviewScreen()],
          ),
        ),
      ],
    );
  }
}
