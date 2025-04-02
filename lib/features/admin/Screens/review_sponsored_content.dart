import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:neusenews/features/admin/screens/article_preview_screen.dart';
import 'package:neusenews/features/admin/screens/event_preview_screen.dart';

class ReviewSponsoredContentScreen extends StatefulWidget {
  const ReviewSponsoredContentScreen({super.key});

  @override
  State<ReviewSponsoredContentScreen> createState() =>
      _ReviewSponsoredContentScreenState();
}

class _ReviewSponsoredContentScreenState
    extends State<ReviewSponsoredContentScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return; // Check if still mounted

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to be logged in to access this area'),
          ),
        );
        return;
      }

      // Check if user has admin role
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final bool isAdmin = userDoc.data()?['isAdmin'] ?? false;

      // Check if still mounted before updating state or navigating
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
      // Check if still mounted before showing error
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
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2d2c31),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFd2982a)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Sponsored Content'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFd2982a),
          unselectedLabelColor: Colors.grey,
          tabs: const [Tab(text: 'Articles'), Tab(text: 'Events')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildArticlesTab(), _buildEventsTab()],
      ),
    );
  }

  Widget _buildArticlesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('sponsored_articles')
              .where('status', isEqualTo: 'pending_review')
              .orderBy('submittedAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFd2982a)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('No articles pending review'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final DateTime submittedAt =
                data['submittedAt']?.toDate() ?? DateTime.now();

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(
                  data['title'] ?? 'No Title',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('By: ${data['authorName'] ?? 'Unknown'}'),
                    Text('Company: ${data['companyName'] ?? 'Unknown'}'),
                    Text(
                      'Submitted: ${DateFormat('MM/dd/yyyy').format(submittedAt)}',
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.blue),
                      onPressed: () => _previewArticle(docs[index].id, data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _approveArticle(docs[index].id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => _rejectArticle(docs[index].id),
                    ),
                  ],
                ),
                isThreeLine: true,
                onTap: () => _previewArticle(docs[index].id, data),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEventsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('events')
              .where('status', isEqualTo: 'pending_review')
              .orderBy('submittedAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFd2982a)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('No events pending review'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final DateTime eventDate =
                data['startDate']?.toDate() ?? DateTime.now();

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(
                  data['eventTitle'] ?? 'No Title',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Venue: ${data['venue'] ?? 'TBD'}'),
                    Text('Date: ${DateFormat('MM/dd/yyyy').format(eventDate)}'),
                    Text('Type: ${data['eventType'] ?? 'Unknown'}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.blue),
                      onPressed: () => _previewEvent(docs[index].id, data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _approveEvent(docs[index].id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => _rejectEvent(docs[index].id),
                    ),
                  ],
                ),
                isThreeLine: true,
                onTap: () => _previewEvent(docs[index].id, data),
              ),
            );
          },
        );
      },
    );
  }

  void _previewArticle(String id, Map<String, dynamic> data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ArticlePreviewScreen(id: id, data: data),
      ),
    );
  }

  void _previewEvent(String id, Map<String, dynamic> data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventPreviewScreen(id: id, data: data),
      ),
    );
  }

  Future<void> _approveArticle(String id) async {
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Approve Article'),
              content: const Text(
                'Are you sure you want to approve this article? '
                'It will be published immediately.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('APPROVE'),
                ),
              ],
            ),
      );

      if (confirm != true) return;

      // Check if still mounted before proceeding
      if (!mounted) return;

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Update article status in Firestore
      await FirebaseFirestore.instance
          .collection('sponsored_articles')
          .doc(id)
          .update({
            'status': 'published',
            'publishedAt': FieldValue.serverTimestamp(),
            'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
            'reviewedAt': FieldValue.serverTimestamp(),
            // Add 30 days from now as expiration date
            'expiresAt': Timestamp.fromDate(
              DateTime.now().add(const Duration(days: 30)),
            ),
          });

      // Check if still mounted before showing success message
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article approved and published!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving article: $e')));
    }
  }

  Future<void> _rejectArticle(String id) async {
    try {
      // Show confirmation dialog with reason field
      final String? reason = await showDialog<String>(
        context: context,
        builder: (context) {
          String rejectionReason = '';
          return AlertDialog(
            title: const Text('Reject Article'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Are you sure you want to reject this article?'),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Reason for rejection (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) => rejectionReason = value,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(rejectionReason),
                child: const Text('REJECT'),
              ),
            ],
          );
        },
      );

      if (reason == null) return; // User canceled

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Update article status in Firestore
      await FirebaseFirestore.instance
          .collection('sponsored_articles')
          .doc(id)
          .update({
            'status': 'rejected',
            'rejectionReason': reason,
            'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
            'reviewedAt': FieldValue.serverTimestamp(),
          });

      // Notify success
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Article rejected')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error rejecting article: $e')));
    }
  }

  Future<void> _approveEvent(String id) async {
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Approve Event'),
              content: const Text(
                'Are you sure you want to approve this event? '
                'It will be published immediately.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('APPROVE'),
                ),
              ],
            ),
      );

      if (confirm != true) return;

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Update event status in Firestore
      await FirebaseFirestore.instance.collection('events').doc(id).update({
        'status': 'published',
        'publishedAt': FieldValue.serverTimestamp(),
        'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // Notify success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event approved and published!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving event: $e')));
    }
  }

  Future<void> _rejectEvent(String id) async {
    try {
      // Show confirmation dialog with reason field
      final String? reason = await showDialog<String>(
        context: context,
        builder: (context) {
          String rejectionReason = '';
          return AlertDialog(
            title: const Text('Reject Event'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Are you sure you want to reject this event?'),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Reason for rejection (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) => rejectionReason = value,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(rejectionReason),
                child: const Text('REJECT'),
              ),
            ],
          );
        },
      );

      if (reason == null) return; // User canceled

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Update event status in Firestore
      await FirebaseFirestore.instance.collection('events').doc(id).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // Notify success
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Event rejected')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error rejecting event: $e')));
    }
  }
}
