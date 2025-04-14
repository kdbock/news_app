import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsTipReviewScreen extends StatefulWidget {
  const NewsTipReviewScreen({super.key});

  @override
  State<NewsTipReviewScreen> createState() => _NewsTipReviewScreenState();
}

class _NewsTipReviewScreenState extends State<NewsTipReviewScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _newsTips = [];
  List<Map<String, dynamic>> _filteredTips = [];
  String _filterStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _loadNewsTips();
  }

  Future<void> _loadNewsTips() async {
    setState(() => _isLoading = true);

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('news_tips')
              .orderBy('submittedAt', descending: true)
              .get();

      final tips =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? 'Untitled News Tip',
              'description': data['description'] ?? '',
              'location': data['location'] ?? 'Unknown Location',
              'contactInfo': data['contactInfo'] ?? '',
              'isAnonymous': data['isAnonymous'] ?? false,
              'submitterId': data['submitterId'],
              'submitterName': data['submitterName'] ?? 'Anonymous',
              'status': data['status'] ?? 'pending',
              'submittedAt': data['submittedAt']?.toDate() ?? DateTime.now(),
              'mediaUrls': data['mediaUrls'] ?? [],
              'reviewedBy': data['reviewedBy'],
              'reviewedAt': data['reviewedAt']?.toDate(),
              'reviewNotes': data['reviewNotes'] ?? '',
            };
          }).toList();

      setState(() {
        _newsTips = tips;
        _filterTipsByStatus(_filterStatus);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading news tips: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading news tips: $e')));
      }
    }
  }

  void _filterTipsByStatus(String status) {
    setState(() {
      _filterStatus = status;
      if (status == 'all') {
        _filteredTips = List.from(_newsTips);
      } else {
        _filteredTips =
            _newsTips
                .where(
                  (tip) => tip['status'].toString().toLowerCase() == status,
                )
                .toList();
      }
    });
  }

  Future<void> _updateTipStatus(
    String tipId,
    String status, [
    String? notes,
  ]) async {
    try {
      final updates = {
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
      };

      if (notes != null) {
        updates['reviewNotes'] = notes;
      }

      await FirebaseFirestore.instance
          .collection('news_tips')
          .doc(tipId)
          .update(updates);

      // If approved, create an article draft
      if (status == 'approved') {
        final tipDoc =
            await FirebaseFirestore.instance
                .collection('news_tips')
                .doc(tipId)
                .get();

        if (tipDoc.exists) {
          final tipData = tipDoc.data()!;

          // Create article draft
          await FirebaseFirestore.instance.collection('articles_draft').add({
            'title': 'Draft: ${tipData['title'] ?? 'News Tip'}',
            'content': tipData['description'] ?? '',
            'source': 'News Tip',
            'sourceTipId': tipId,
            'status': 'draft',
            'category': 'Local News',
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': FirebaseAuth.instance.currentUser?.uid,
            'mediaUrls': tipData['mediaUrls'] ?? [],
            'location': tipData['location'],
          });
        }
      }

      // Refresh the list
      _loadNewsTips();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('News tip $status successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error updating news tip: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating news tip: $e')));
      }
    }
  }

  void _reviewTip(Map<String, dynamic> tip) {
    final reviewController = TextEditingController(
      text: tip['reviewNotes'] ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Review News Tip: ${tip['title']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submitted by: ${tip['isAnonymous'] ? 'Anonymous' : tip['submitterName']}',
                  ),
                  const SizedBox(height: 8),
                  Text('Location: ${tip['location']}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(tip['description']),
                  const SizedBox(height: 16),

                  // Show media if available
                  if ((tip['mediaUrls'] as List).isNotEmpty) ...[
                    const Text(
                      'Media:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: (tip['mediaUrls'] as List).length,
                        itemBuilder: (context, index) {
                          final mediaUrl = (tip['mediaUrls'] as List)[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => _launchUrl(mediaUrl),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  mediaUrl,
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => Container(
                                        height: 100,
                                        width: 100,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.broken_image),
                                      ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Text(
                    'Review Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: reviewController,
                    decoration: const InputDecoration(
                      hintText: 'Add review notes here...',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateTipStatus(
                    tip['id'],
                    'rejected',
                    reviewController.text,
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'REJECT',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateTipStatus(
                    tip['id'],
                    'approved',
                    reviewController.text,
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text(
                  'APPROVE',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open: $url')));
      }
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
        // Status filter tabs
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterChip('All', 'all'),
              _buildFilterChip('Pending', 'pending'),
              _buildFilterChip('Approved', 'approved'),
              _buildFilterChip('Rejected', 'rejected'),
            ],
          ),
        ),

        // News tips list
        Expanded(
          child:
              _filteredTips.isEmpty
                  ? const Center(child: Text('No news tips found'))
                  : ListView.builder(
                    itemCount: _filteredTips.length,
                    itemBuilder: (context, index) {
                      final tip = _filteredTips[index];
                      return _buildNewsTipCard(tip);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _filterStatus == status;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _filterTipsByStatus(status),
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFFd2982a).withOpacity(0.3),
      checkmarkColor: const Color(0xFFd2982a),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFd2982a) : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildNewsTipCard(Map<String, dynamic> tip) {
    final timestamp = tip['submittedAt'] as DateTime;
    final dateFormat = DateFormat.yMMMd().add_jm();
    final formattedDate = dateFormat.format(timestamp);

    Color statusColor;
    switch (tip['status'].toString().toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _reviewTip(tip),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tip['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      tip['status'].toString().toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Submission info
              const SizedBox(height: 8),
              Text(
                'From: ${tip['isAnonymous'] ? 'Anonymous' : tip['submitterName']} • $formattedDate',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),

              // Location
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: Color(0xFFd2982a),
                  ),
                  const SizedBox(width: 4),
                  Text(tip['location']),
                ],
              ),

              // Preview of description
              const SizedBox(height: 8),
              Text(
                tip['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Media preview
              if ((tip['mediaUrls'] as List).isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.photo, size: 16),
                    const SizedBox(width: 4),
                    Text('${(tip['mediaUrls'] as List).length} media items'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
