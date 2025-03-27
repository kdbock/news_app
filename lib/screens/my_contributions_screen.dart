import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyContributionsScreen extends StatefulWidget {
  const MyContributionsScreen({super.key});

  @override
  State<MyContributionsScreen> createState() => _MyContributionsScreenState();
}

class _MyContributionsScreenState extends State<MyContributionsScreen> {
  bool _isLoading = true;
  List<Article> _myArticles = [];
  List<Map<String, dynamic>> _pendingArticles = [];
  String _activeTab = 'published';

  @override
  void initState() {
    super.initState();
    _loadContributions();
  }

  Future<void> _loadContributions() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not logged in');
      }

      // Load published articles
      final publishedSnapshot =
          await FirebaseFirestore.instance
              .collection('articles')
              .where('authorId', isEqualTo: user.uid)
              .where('status', isEqualTo: 'published')
              .orderBy('publishedAt', descending: true)
              .get();

      final articles =
          publishedSnapshot.docs.map((doc) {
            final data = doc.data();
            return Article(
              id: doc.id,
              title: data['title'] ?? '',
              content: data['content'] ?? '',
              category: data['category'] ?? '',
              author: data['author'] ?? '',
              imageUrl: data['imageUrl'],
              publishedAt:
                  (data['publishedAt'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
              isFeatured: data['isFeatured'] ?? false,
            );
          }).toList();

      // Load pending articles
      final pendingSnapshot =
          await FirebaseFirestore.instance
              .collection('pendingArticles')
              .where('authorId', isEqualTo: user.uid)
              .orderBy('submittedAt', descending: true)
              .get();

      final pendingArticles =
          pendingSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? '',
              'category': data['category'] ?? '',
              'submittedAt': data['submittedAt'] ?? Timestamp.now(),
              'status': data['status'] ?? 'pending',
              'notes': data['reviewNotes'] ?? '',
            };
          }).toList();

      setState(() {
        _myArticles = articles;
        _pendingArticles = pendingArticles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _myArticles = [];
        _pendingArticles = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contributions: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Contributions')),
      body: Column(
        children: [
          // Tab selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(child: _buildTabButton('Published', 'published')),
                Expanded(child: _buildTabButton('Pending', 'pending')),
                Expanded(child: _buildTabButton('Drafts', 'drafts')),
              ],
            ),
          ),

          // Content
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to create new article
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create article feature coming soon')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Article'),
        backgroundColor: const Color(0xFFd2982a),
      ),
    );
  }

  Widget _buildTabButton(String title, String tabId) {
    final bool isActive = _activeTab == tabId;

    return InkWell(
      onTap: () {
        setState(() => _activeTab = tabId);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFFd2982a) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? const Color(0xFFd2982a) : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_activeTab) {
      case 'published':
        return _buildPublishedArticles();
      case 'pending':
        return _buildPendingArticles();
      case 'drafts':
        return _buildDrafts();
      default:
        return const Center(child: Text('Unknown tab'));
    }
  }

  Widget _buildPublishedArticles() {
    if (_myArticles.isEmpty) {
      return _buildEmptyState(
        'You have no published articles',
        'Your published articles will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myArticles.length,
      itemBuilder: (context, index) {
        final article = _myArticles[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.imageUrl != null)
                Image.network(
                  article.imageUrl!,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Published on ${DateFormat('MMM d, yyyy').format(article.publishedAt)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Category: ${article.category}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            // View analytics
                          },
                          child: const Text('View Stats'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // View article
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFd2982a),
                          ),
                          child: const Text('View Article'),
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
    );
  }

  Widget _buildPendingArticles() {
    if (_pendingArticles.isEmpty) {
      return _buildEmptyState(
        'No pending submissions',
        'Articles under review will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingArticles.length,
      itemBuilder: (context, index) {
        final article = _pendingArticles[index];
        final submittedDate = (article['submittedAt'] as Timestamp).toDate();

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Submitted on ${DateFormat('MMM d, yyyy').format(submittedDate)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(article['status']),
                  ],
                ),
                const SizedBox(height: 16),
                if (article['notes'].isNotEmpty) ...[
                  const Text(
                    'Review Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(article['notes']),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        // Edit submission
                      },
                      child: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // View submission details
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFd2982a),
                      ),
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrafts() {
    return _buildEmptyState(
      'No drafts yet',
      'Save drafts to continue writing later',
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending Review';
        break;
      case 'approved':
        color = Colors.green;
        label = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      case 'revisions':
        color = Colors.blue;
        label = 'Needs Revisions';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class Article {
  final String id;
  final String title;
  final String content;
  final String author;
  final String? imageUrl;
  final DateTime publishedAt;
  final bool isFeatured;
  final String category;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    this.imageUrl,
    required this.publishedAt,
    required this.isFeatured,
    required this.category,
  });
}
