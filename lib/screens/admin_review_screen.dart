import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:news_app/widgets/webview_screen.dart';

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  _AdminReviewScreenState createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingArticles = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchPendingArticles();
  }

  Future<void> _fetchPendingArticles() async {
    setState(() => _isLoading = true);

    try {
      // Check if user is admin
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to access this page.');
      }

      // First get ALL articles to verify the collection exists and has data
      final allArticles =
          await _firestore.collection('sponsored_articles').get();
      debugPrint(
        'Found ${allArticles.docs.length} total articles in collection',
      );

      // Log all article statuses to help debug
      for (var doc in allArticles.docs) {
        debugPrint('Article ID: ${doc.id}, Status: ${doc.data()['status']}');
      }

      // Now get pending articles
      final snapshot =
          await _firestore
              .collection('sponsored_articles')
              .where('status', isEqualTo: 'pending_review')
              .orderBy('submittedAt', descending: true)
              .get();

      debugPrint('Found ${snapshot.docs.length} pending articles');

      final articles =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? 'Untitled Article',
              'content': data['content'] ?? '',
              'authorName': data['authorName'] ?? 'Anonymous',
              'companyName': data['companyName'] ?? 'Unknown Company',
              'submittedAt': data['submittedAt']?.toDate() ?? DateTime.now(),
              'headerImageUrl': data['headerImageUrl'] ?? '',
              'ctaLink': data['ctaLink'] ?? '',
              'ctaText': data['ctaText'] ?? 'Learn More',
              'category': data['category'] ?? 'Uncategorized',
            };
          }).toList();

      setState(() {
        _pendingArticles = articles;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching pending articles: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading articles: $e')));
      }
    }
  }

  Future<void> _approveArticle(String id) async {
    try {
      setState(() => _isLoading = true);

      // Set the status to published and add publishedAt date
      await _firestore.collection('sponsored_articles').doc(id).update({
        'status': 'published',
        'publishedAt': FieldValue.serverTimestamp(),
        'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // Refresh the list
      await _fetchPendingArticles();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article approved and published!')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving article: $e')));
    }
  }

  Future<void> _rejectArticle(String id) async {
    try {
      // Show dialog to get rejection reason
      final reason = await showDialog<String>(
        context: context,
        builder: (context) => _buildRejectDialog(),
      );

      if (reason == null) {
        return; // User cancelled
      }

      setState(() => _isLoading = true);

      // Set the status to rejected and add reason
      await _firestore.collection('sponsored_articles').doc(id).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // Refresh the list
      await _fetchPendingArticles();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Article rejected')));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error rejecting article: $e')));
    }
  }

  Widget _buildRejectDialog() {
    final controller = TextEditingController();
    return AlertDialog(
      title: const Text('Reject Article'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Reason for rejection',
          hintText: 'Provide feedback to the author',
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Reject'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Review'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _fetchPendingArticles,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFd2982a)),
              )
              : _pendingArticles.isEmpty
              ? const Center(child: Text('No pending articles to review'))
              : ListView.builder(
                itemCount: _pendingArticles.length,
                itemBuilder: (context, index) {
                  final article = _pendingArticles[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (article['headerImageUrl'] != null &&
                            article['headerImageUrl'].isNotEmpty)
                          Image.network(
                            article['headerImageUrl'],
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => const SizedBox(
                                  height: 150,
                                  child: Center(
                                    child: Icon(Icons.broken_image, size: 50),
                                  ),
                                ),
                          ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFd2982a),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'PENDING',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      article['category'] ?? 'Uncategorized',
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),
                              Text(
                                article['title'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),
                              Text(
                                'By ${article['authorName']} • ${article['companyName']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),

                              const SizedBox(height: 8),
                              Text(
                                'Submitted on ${DateFormat('MMM d, yyyy').format(article['submittedAt'])}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),

                              const SizedBox(height: 16),
                              Text(
                                article['content'].length > 200
                                    ? '${article['content'].substring(0, 200)}...'
                                    : article['content'],
                                style: const TextStyle(fontSize: 14),
                              ),

                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  if (article['ctaLink'] != null &&
                                      article['ctaLink'].isNotEmpty)
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => WebViewScreen(
                                                  url: article['ctaLink'],
                                                  title: 'Preview Link',
                                                ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.link),
                                      label: const Text('Preview Link'),
                                    ),

                                  const Spacer(),

                                  TextButton(
                                    onPressed: () => _showFullArticle(article),
                                    child: const Text('View Full Article'),
                                  ),
                                ],
                              ),

                              const Divider(),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed:
                                        () => _rejectArticle(article['id']),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed:
                                        () => _approveArticle(article['id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFd2982a),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Approve'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }

  void _showFullArticle(Map<String, dynamic> article) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog.fullscreen(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Full Article Preview'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Article image
                    if (article['headerImageUrl'] != null &&
                        article['headerImageUrl'].isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          article['headerImageUrl'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => const SizedBox(
                                height: 200,
                                child: Center(
                                  child: Icon(Icons.broken_image, size: 50),
                                ),
                              ),
                        ),
                      ),

                    const SizedBox(height: 16),
                    // Title
                    Text(
                      article['title'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),
                    // Author and company
                    Text(
                      'By ${article['authorName']} • ${article['companyName']}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),

                    const SizedBox(height: 16),
                    // Article content
                    Text(
                      article['content'],
                      style: const TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 24),
                    // CTA button
                    if (article['ctaLink'] != null &&
                        article['ctaLink'].isNotEmpty)
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => WebViewScreen(
                                      url: article['ctaLink'],
                                      title: 'Preview Link',
                                    ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFd2982a),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            article['ctaText'] ?? 'Learn More',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
