import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArticlePreviewScreen extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;

  const ArticlePreviewScreen({super.key, required this.id, required this.data});

  @override
  _ArticlePreviewScreenState createState() => _ArticlePreviewScreenState();
}

class _ArticlePreviewScreenState extends State<ArticlePreviewScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final headerImageUrl = widget.data['headerImageUrl'];
    final title = widget.data['title'] ?? 'No Title';
    final content = widget.data['content'] ?? 'No content provided';
    final authorName = widget.data['authorName'] ?? 'Unknown Author';
    final companyName = widget.data['companyName'] ?? 'Unknown Organization';
    final ctaText = widget.data['ctaText'] ?? 'Learn More';
    final ctaLink = widget.data['ctaLink'] ?? '';
    final DateTime submittedAt =
        widget.data['submittedAt']?.toDate() ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article Preview'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: () => _approveArticle(),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () => _rejectArticle(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header image if available
            if (headerImageUrl != null && headerImageUrl.isNotEmpty)
              Image.network(
                headerImageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    ),
              ),

            // Article metadata
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'SPONSORED',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM dd, yyyy').format(submittedAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By $authorName | $companyName',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ],
              ),
            ),

            // Article content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                content,
                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
            ),

            // Call to action
            if (ctaLink.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {}, // Disabled in preview
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFd2982a),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(ctaText),
                ),
              ),

            // Admin section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _approveArticle(),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('APPROVE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _rejectArticle(context),
                        icon: const Icon(Icons.cancel),
                        label: const Text('REJECT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveArticle() async {
    try {
      setState(() => _isLoading = true);

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

      // Check if still mounted before showing snackbar
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
          .doc(widget.id)
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

      // Check if still mounted before continuing
      if (!mounted) return;

      // Notify success and navigate back
      if (mounted) {
        // Add this check
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article approved and published!')),
        );
      }
      Navigator.of(context).pop(); // Go back to article list
    } catch (e) {
      if (mounted) {
        // Add this check
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error approving article: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rejectArticle(BuildContext context) async {
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

      // Check if still mounted before showing snackbar
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
          .doc(widget.id)
          .update({
            'status': 'rejected',
            'rejectionReason': reason,
            'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
            'reviewedAt': FieldValue.serverTimestamp(),
          });

      // Check if still mounted before continuing
      if (!mounted) return;

      // Notify success and navigate back
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Article rejected')));
      Navigator.of(context).pop(); // Go back to article list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error rejecting article: $e')));
      }
    }
  }
}
