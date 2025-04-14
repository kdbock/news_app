import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neusenews/widgets/app_drawer.dart';
import 'package:intl/intl.dart';
// Remove the problematic import
// import 'package:firebase_firestore_platform_interface/firebase_firestore_platform_interface.dart';

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

  // Helper functions moved to class level
  String getDefaultTitle(String type) {
    switch (type) {
      case 'article':
        return 'Untitled Article';
      case 'event':
        return 'Untitled Event';
      case 'news_tip':
        return 'News Tip';
      case 'ad':
        return 'Advertisement';
      default:
        return 'Untitled';
    }
  }

  Timestamp? safelyExtractDate(Map<String, dynamic> data) {
    // Try various date fields in order
    final dateFields = ['submittedAt', 'createdAt', 'publishedAt', 'date'];
    for (final field in dateFields) {
      try {
        if (data.containsKey(field) && data[field] != null) {
          final value = data[field];
          if (value is Timestamp) return value;
        }
      } catch (e) {
        // Continue to next field
      }
    }
    return null;
  }

  String safelyExtractImage(Map<String, dynamic> data, String type) {
    try {
      if (type == 'article' &&
          data.containsKey('headerImageUrl') &&
          data['headerImageUrl'] != null) {
        return data['headerImageUrl'];
      }
      if (data.containsKey('imageUrl') && data['imageUrl'] != null) {
        return data['imageUrl'];
      }
      if (type == 'news_tip' && data.containsKey('mediaUrls')) {
        final mediaUrls = data['mediaUrls'];
        if (mediaUrls is List && mediaUrls.isNotEmpty) {
          return mediaUrls[0];
        }
      }
    } catch (e) {
      debugPrint('Error extracting image: $e');
    }
    return '';
  }

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
        // Filter by type - convert plural tab names to singular types
        String typeToShow = _tabs[tabIndex].toLowerCase();

        // Convert plural tab names to singular as stored in the data
        if (typeToShow == 'articles')
          typeToShow = 'article';
        else if (typeToShow == 'events')
          typeToShow = 'event';
        else if (typeToShow == 'news tips')
          typeToShow = 'news_tip';
        else if (typeToShow == 'ads')
          typeToShow = 'ad';

        debugPrint('Filtering for type: $typeToShow');

        _filteredContributions =
            _contributions.where((item) {
              final itemType = item['type']?.toString().toLowerCase() ?? '';
              final matches = itemType == typeToShow;
              return matches;
            }).toList();

        debugPrint(
          'Found ${_filteredContributions.length} matching contributions',
        );
      }
    });
  }

  Future<void> _loadAllContributions() async {
    setState(() => _isLoading = true);

    try {
      // Get current user ID
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      List<Map<String, dynamic>> allContributions = [];
      debugPrint('Current user ID: ${user.uid}');

      // Function to safely process any document from any collection
      Map<String, dynamic> safelyExtractDocument(
        DocumentSnapshot doc,
        String type,
        String collection,
      ) {
        try {
          // IMPORTANT: Convert DocumentSnapshot to Map SAFELY
          // This is the key step that avoids the "status doesn't exist" error
          Map<String, dynamic> safeData = {};

          // First check if the document exists and has data
          if (doc.exists) {
            // Convert to map and catch any potential errors
            try {
              final rawData = doc.data();
              if (rawData != null && rawData is Map<String, dynamic>) {
                safeData = rawData;
              }
            } catch (e) {
              debugPrint('Error converting document to map: $e');
            }
          }

          // Now build our contribution object with guaranteed fields
          return {
            'id': doc.id,
            'type': type,
            'title':
                safeData['title'] ??
                safeData['headline'] ??
                getDefaultTitle(type),
            'status': safeData['status'] ?? 'pending_review',
            'date': safelyExtractDate(safeData) ?? Timestamp.now(),
            'imageUrl': safelyExtractImage(safeData, type),
            'collection': collection,
          };
        } catch (e) {
          debugPrint('Error safely extracting document: $e');
          // Return a minimal valid document if anything fails
          return {
            'id': doc.id,
            'type': type,
            'title': getDefaultTitle(type),
            'status': 'unknown',
            'date': Timestamp.now(),
            'imageUrl': '',
            'collection': collection,
          };
        }
      }

      // Process sponsored articles with our safe approach
      try {
        final articlesSnapshot =
            await _firestore
                .collection('sponsored_articles')
                .where('submittedBy', isEqualTo: user.uid)
                .get();

        debugPrint('Found ${articlesSnapshot.docs.length} articles');

        for (var doc in articlesSnapshot.docs) {
          allContributions.add(
            safelyExtractDocument(doc, 'article', 'sponsored_articles'),
          );
        }
      } catch (e) {
        debugPrint('Error getting articles: $e');
      }

      // Process events with same safe approach
      try {
        final eventsSnapshot =
            await _firestore
                .collection('events')
                .where('createdBy', isEqualTo: user.uid)
                .get();

        for (var doc in eventsSnapshot.docs) {
          allContributions.add(safelyExtractDocument(doc, 'event', 'events'));
        }
      } catch (e) {
        debugPrint('Error getting events: $e');
      }

      // Process news tips with safe approach
      try {
        final tipsSnapshot =
            await _firestore
                .collection('news_tips')
                .where('submitterId', isEqualTo: user.uid)
                .get();

        for (var doc in tipsSnapshot.docs) {
          allContributions.add(
            safelyExtractDocument(doc, 'news_tip', 'news_tips'),
          );
        }
      } catch (e) {
        debugPrint('Error getting news tips: $e');
      }

      // Process ads with safe approach
      try {
        final adsSnapshot =
            await _firestore
                .collection('ads')
                .where('createdBy', isEqualTo: user.uid)
                .get();

        for (var doc in adsSnapshot.docs) {
          allContributions.add(safelyExtractDocument(doc, 'ad', 'ads'));
        }
      } catch (e) {
        debugPrint('Error getting ads: $e');
      }

      // Sort all contributions by date with error handling
      try {
        allContributions.sort((a, b) {
          try {
            final Timestamp? aDate = a['date'] as Timestamp?;
            final Timestamp? bDate = b['date'] as Timestamp?;

            // Handle null dates
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1; // a is "older" (at the end)
            if (bDate == null) return -1; // b is "older" (at the end)

            return bDate.compareTo(aDate); // Newest first
          } catch (e) {
            debugPrint('Error comparing dates: $e');
            return 0; // Keep original order if comparison fails
          }
        });
      } catch (e) {
        debugPrint('Error sorting contributions: $e');
        // Continue without sorting if it fails
      }

      for (var contribution in allContributions) {
        debugPrint(
          'Added contribution: ${contribution['id']}, type: ${contribution['type']}, status: ${contribution['status']}',
        );
      }

      setState(() {
        _contributions = allContributions;
        _filteredContributions = allContributions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading contributions: $e')),
      );

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
    // Add a try-catch around the entire method
    try {
      // DEBUG: Print all keys in the contribution map to see what's actually available
      debugPrint('Card keys: ${contribution.keys.join(", ")}');

      // Safely get values with fallbacks for everything
      final String title = contribution['title']?.toString() ?? 'Untitled';
      final String type = contribution['type']?.toString() ?? 'unknown';
      final String statusValue =
          contribution['status']?.toString() ?? 'pending';

      // Parse timestamp with full error handling
      Timestamp? timestamp;
      DateTime date = DateTime.now();
      try {
        timestamp = contribution['date'] as Timestamp?;
        if (timestamp != null) {
          date = timestamp.toDate();
        }
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
      final dateStr = DateFormat.yMMMd().format(date);

      // Status styling with completely safe handling
      Color statusColor = Colors.orange; // Default
      if (statusValue.toLowerCase().contains('publish') ||
          statusValue.toLowerCase().contains('approve')) {
        statusColor = Colors.green;
      } else if (statusValue.toLowerCase().contains('reject')) {
        statusColor = Colors.red;
      }

      // Type icon
      IconData typeIcon;
      switch (type) {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                        Icon(
                          typeIcon,
                          size: 16,
                          color: const Color(0xFFd2982a),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatContributionType(type),
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
                        color: Color.fromRGBO(
                          (statusColor.r * 255)
                              .round(), // Convert double to int
                          (statusColor.g * 255)
                              .round(), // Convert double to int
                          (statusColor.b * 255)
                              .round(), // Convert double to int
                          0.1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        _formatStatus(statusValue),
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
                              title,
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
    } catch (e) {
      // If anything goes wrong, show a fallback card with error info
      debugPrint('Error building card: $e');
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error loading contribution details. Please try again later.',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
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

  String _formatStatus(String? status) {
    if (status == null) return 'PENDING';

    final statusLower = status.toLowerCase();
    if (statusLower.contains('pending') || statusLower.contains('review')) {
      return 'PENDING';
    } else if (statusLower.contains('publish') ||
        statusLower.contains('approve')) {
      return 'APPROVED';
    } else if (statusLower.contains('reject')) {
      return 'REJECTED';
    } else {
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
