import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:neusenews/screens/admin/article_preview_screen.dart';
import 'package:neusenews/screens/admin/event_preview_screen.dart';

class ContentReviewTab extends StatefulWidget {
  const ContentReviewTab({super.key});

  @override
  State<ContentReviewTab> createState() => _ContentReviewTabState();
}

class _ContentReviewTabState extends State<ContentReviewTab>
    with TickerProviderStateMixin {
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
          tabs: const [Tab(text: 'Articles'), Tab(text: 'Events')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildArticlesTab(), _buildEventsTab()],
          ),
        ),
      ],
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

        final articles = snapshot.data?.docs ?? [];

        if (articles.isEmpty) {
          return const Center(child: Text('No articles pending review'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final article = articles[index].data() as Map<String, dynamic>;
            final articleId = articles[index].id;

            final submittedAt = article['submittedAt'] as Timestamp?;
            final submittedDate =
                submittedAt != null
                    ? DateFormat.yMMMd().format(submittedAt.toDate())
                    : 'Unknown date';

            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              child: ListTile(
                title: Text(
                  article['title'] ?? 'Untitled Article',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Submitted: $submittedDate by ${article['authorName'] ?? 'Unknown'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => ArticlePreviewScreen(
                            id: articleId,
                            data: article,
                          ),
                    ),
                  );
                },
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

        final events = snapshot.data?.docs ?? [];

        if (events.isEmpty) {
          return const Center(child: Text('No events pending review'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index].data() as Map<String, dynamic>;
            final eventId = events[index].id;

            final submittedAt = event['submittedAt'] as Timestamp?;
            final submittedDate =
                submittedAt != null
                    ? DateFormat.yMMMd().format(submittedAt.toDate())
                    : 'Unknown date';

            final eventDate = event['eventDate'] as Timestamp?;
            final formattedEventDate =
                eventDate != null
                    ? DateFormat.yMMMd().format(eventDate.toDate())
                    : 'Unknown date';

            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              child: ListTile(
                title: Text(
                  event['title'] ?? 'Untitled Event',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Event date: $formattedEventDate'),
                    Text(
                      'Submitted: $submittedDate by ${event['organizerName'] ?? 'Unknown'}',
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              EventPreviewScreen(id: eventId, data: event),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
