import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neusenews/widgets/app_drawer.dart';
import 'package:intl/intl.dart';

class MyContributionsScreen extends StatefulWidget {
  const MyContributionsScreen({super.key});

  @override
  State<MyContributionsScreen> createState() => _MyContributionsScreenState();
}

class _MyContributionsScreenState extends State<MyContributionsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _contributions = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Change from late to nullable with initialization
  TabController? _tabController;

  final List<String> _tabs = ['All', 'Articles', 'Events', 'News Tips', 'Ads'];
  List<Map<String, dynamic>> _filteredContributions = [];

  @override
  void initState() {
    super.initState();
    // Initialize immediately
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController!.addListener(_handleTabChange);
    _loadAllContributions();
  }

  @override
  void dispose() {
    // Add null check before removing listener
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController!.indexIsChanging) {
      _filterContributions(_tabController!.index);
    }
  }

  void _filterContributions(int tabIndex) {
    setState(() {
      if (tabIndex == 0) {
        // Show all contributions
        _filteredContributions = _contributions;
      } else {
        // Filter by type
        String typeToShow = _tabs[tabIndex].toLowerCase();
        if (typeToShow == 'news tips') typeToShow = 'news_tip';

        _filteredContributions =
            _contributions.where((item) {
              return item['type'].toLowerCase() ==
                  typeToShow.replaceAll(' ', '_');
            }).toList();
      }
    });
  }

  Future<void> _loadAllContributions() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      List<Map<String, dynamic>> allContributions = [];

      // 1. Load sponsored articles
      final articlesSnapshot =
          await _firestore
              .collection('sponsored_articles')
              .where('createdBy', isEqualTo: user.uid)
              .orderBy('submittedAt', descending: true)
              .get();

      for (var doc in articlesSnapshot.docs) {
        allContributions.add({
          'id': doc.id,
          'type': 'article',
          'title': doc['title'] ?? 'Untitled Article',
          'status': doc['status'] ?? 'pending_review',
          'date': doc['submittedAt'] ?? Timestamp.now(),
          'imageUrl': doc['headerImageUrl'] ?? '',
          'collection': 'sponsored_articles',
        });
      }

      // 2. Load events
      final eventsSnapshot =
          await _firestore
              .collection('events')
              .where('createdBy', isEqualTo: user.uid)
              .orderBy('createdAt', descending: true)
              .get();

      for (var doc in eventsSnapshot.docs) {
        allContributions.add({
          'id': doc.id,
          'type': 'event',
          'title': doc['title'] ?? 'Untitled Event',
          'status': doc['status'] ?? 'pending_review',
          'date': doc['createdAt'] ?? Timestamp.now(),
          'imageUrl': doc['imageUrl'] ?? '',
          'collection': 'events',
        });
      }

      // 3. Load news tips
      final tipsSnapshot =
          await _firestore
              .collection('news_tips')
              .where('submitterId', isEqualTo: user.uid)
              .orderBy('submittedAt', descending: true)
              .get();

      for (var doc in tipsSnapshot.docs) {
        allContributions.add({
          'id': doc.id,
          'type': 'news_tip',
          'title': doc['headline'] ?? 'News Tip',
          'status': doc['status'] ?? 'pending_review',
          'date': doc['submittedAt'] ?? Timestamp.now(),
          'imageUrl':
              doc['mediaUrls'] != null && (doc['mediaUrls'] as List).isNotEmpty
                  ? doc['mediaUrls'][0]
                  : '',
          'collection': 'news_tips',
        });
      }

      // 4. Load ads
      final adsSnapshot =
          await _firestore
              .collection('ads')
              .where('createdBy', isEqualTo: user.uid)
              .orderBy('createdAt', descending: true)
              .get();

      for (var doc in adsSnapshot.docs) {
        allContributions.add({
          'id': doc.id,
          'type': 'ad',
          'title': doc['title'] ?? 'Advertisement',
          'status': doc['status'] ?? 'pending_review',
          'date': doc['createdAt'] ?? Timestamp.now(),
          'imageUrl': doc['imageUrl'] ?? '',
          'collection': 'ads',
        });
      }

      // Sort all contributions by date
      allContributions.sort((a, b) {
        final aDate = a['date'] as Timestamp;
        final bDate = b['date'] as Timestamp;
        return bDate.compareTo(aDate); // Newest first
      });

      setState(() {
        _contributions = allContributions;
        _filteredContributions = allContributions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading contributions: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure tab controller is available
    if (_tabController == null) {
      _tabController = TabController(length: _tabs.length, vsync: this);
      _tabController!.addListener(_handleTabChange);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Contributions'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
        elevation: 1,
        // Use null check or null-aware operator
        bottom: TabBar(
          controller: _tabController!,
          labelColor: const Color(0xFFd2982a),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFd2982a),
          isScrollable: true,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      drawer: const AppDrawer(),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFd2982a)),
              )
              : _filteredContributions.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inbox, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No ${_tabs[_tabController!.index].toLowerCase()} contributions yet',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _navigateToSubmissionPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFd2982a),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('ADD NEW CONTRIBUTION'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadAllContributions,
                color: const Color(0xFFd2982a),
                child: ListView.builder(
                  itemCount: _filteredContributions.length,
                  itemBuilder: (context, index) {
                    final contribution = _filteredContributions[index];
                    return _buildContributionCard(contribution);
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToSubmissionPage,
        backgroundColor: const Color(0xFFd2982a),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContributionCard(Map<String, dynamic> contribution) {
    // Parse timestamp
    final timestamp = contribution['date'] as Timestamp;
    final date = timestamp.toDate();
    final dateStr = DateFormat.yMMMd().format(date);

    // Status styling
    Color statusColor;
    switch (contribution['status']) {
      case 'approved':
      case 'published':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    // Type icon
    IconData typeIcon;
    switch (contribution['type']) {
      case 'article':
        typeIcon = Icons.article;
        break;
      case 'event':
        typeIcon = Icons.event;
        break;
      case 'news_tip':
        typeIcon = Icons.tips_and_updates;
        break;
      case 'ad':
        typeIcon = Icons.ads_click;
        break;
      default:
        typeIcon = Icons.insert_drive_file;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _viewContributionDetails(contribution),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(typeIcon, size: 16, color: const Color(0xFFd2982a)),
                      const SizedBox(width: 8),
                      Text(
                        _formatContributionType(contribution['type']),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2d2c31),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      _formatStatus(contribution['status']),
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content with optional image
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail if available
                  if (contribution['imageUrl'] != null &&
                      contribution['imageUrl'].isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Image.network(
                          contribution['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: Icon(typeIcon, color: Colors.white),
                              ),
                        ),
                      ),
                    ),

                  // Title and date
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left:
                            contribution['imageUrl'] != null &&
                                    contribution['imageUrl'].isNotEmpty
                                ? 16
                                : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contribution['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Submitted on $dateStr',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatContributionType(String type) {
    switch (type) {
      case 'article':
        return 'Sponsored Article';
      case 'event':
        return 'Event';
      case 'news_tip':
        return 'News Tip';
      case 'ad':
        return 'Advertisement';
      default:
        return 'Contribution';
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pending_review':
        return 'PENDING';
      case 'approved':
      case 'published':
        return 'APPROVED';
      case 'rejected':
        return 'REJECTED';
      default:
        return status.toUpperCase();
    }
  }

  void _viewContributionDetails(Map<String, dynamic> contribution) {
    // Navigate to the appropriate detail screen based on type
    switch (contribution['type']) {
      case 'article':
        Navigator.pushNamed(
          context,
          '/submit-sponsored-article',
          arguments: {'id': contribution['id'], 'viewOnly': true},
        );
        break;
      case 'event':
        Navigator.pushNamed(
          context,
          '/submit-sponsored-event',
          arguments: {'id': contribution['id'], 'viewOnly': true},
        );
        break;
      case 'news_tip':
        Navigator.pushNamed(
          context,
          '/submit-news-tip',
          arguments: {'id': contribution['id'], 'viewOnly': true},
        );
        break;
      case 'ad':
        Navigator.pushNamed(
          context,
          '/advertising-options',
          arguments: {'id': contribution['id'], 'viewOnly': true},
        );
        break;
    }
  }

  void _navigateToSubmissionPage() {
    // Show a bottom sheet with submission options
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add New Contribution',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.article, color: Color(0xFFd2982a)),
                title: const Text('Sponsored Article'),
                onTap: () {
                  Navigator.pop(context); // Close the sheet
                  Navigator.pushNamed(context, '/submit-sponsored-article');
                },
              ),
              ListTile(
                leading: const Icon(Icons.event, color: Color(0xFFd2982a)),
                title: const Text('Sponsored Event'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/submit-sponsored-event');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.tips_and_updates,
                  color: Color(0xFFd2982a),
                ),
                title: const Text('News Tip'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/submit-news-tip');
                },
              ),
              ListTile(
                leading: const Icon(Icons.ads_click, color: Color(0xFFd2982a)),
                title: const Text('Advertisement'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/advertising-options');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
