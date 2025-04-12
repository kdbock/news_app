import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import 'package:intl/intl.dart';

class AdManagementScreen extends StatefulWidget {
  const AdManagementScreen({super.key});

  @override
  State<AdManagementScreen> createState() => _AdManagementScreenState();
}

class _AdManagementScreenState extends State<AdManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingAds = [];
  List<Map<String, dynamic>> _activeAds = [];

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    setState(() => _isLoading = true);

    try {
      // Fetch pending ads
      final pendingSnapshot =
          await FirebaseFirestore.instance
              .collection('ads')
              .where('status', isEqualTo: 'pending_review')
              .orderBy('createdAt', descending: true)
              .get();

      final pendingAds =
          pendingSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? 'Untitled Ad',
              'businessName': data['businessName'] ?? 'Unknown Business',
              'adType': data['adType'] ?? 'Unknown Type',
              'imageUrl': data['imageUrl'] ?? '',
              'startDate': data['startDate']?.toDate(),
              'endDate': data['endDate']?.toDate(),
              'cost': data['cost'] ?? 0.0,
              'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
              'targetUrl': data['targetUrl'] ?? '',
              'status': data['status'] ?? 'pending_review',
            };
          }).toList();

      // Fetch active ads
      final activeSnapshot =
          await FirebaseFirestore.instance
              .collection('ads')
              .where('status', isEqualTo: 'active')
              .orderBy('endDate')
              .get();

      final activeAds =
          activeSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? 'Untitled Ad',
              'businessName': data['businessName'] ?? 'Unknown Business',
              'adType': data['adType'] ?? 'Unknown Type',
              'imageUrl': data['imageUrl'] ?? '',
              'startDate': data['startDate']?.toDate(),
              'endDate': data['endDate']?.toDate(),
              'cost': data['cost'] ?? 0.0,
              'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
              'targetUrl': data['targetUrl'] ?? '',
              'status': data['status'] ?? 'active',
            };
          }).toList();

      setState(() {
        _pendingAds = pendingAds;
        _activeAds = activeAds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading ads: $e')));
    }
  }

  Future<void> _approveAd(String id) async {
    try {
      await FirebaseFirestore.instance.collection('ads').doc(id).update({
        'status': 'active',
        'approvedAt': FieldValue.serverTimestamp(),
        'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad approved successfully!')),
      );

      _loadAds(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving ad: $e')));
    }
  }

  Future<void> _rejectAd(String id) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Reject Ad'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              hintText: 'Provide feedback to the advertiser',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('REJECT'),
            ),
          ],
        );
      },
    );

    if (reason != null) {
      try {
        await FirebaseFirestore.instance.collection('ads').doc(id).update({
          'status': 'rejected',
          'rejectionReason': reason,
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ad rejected')));

        _loadAds(); // Refresh list
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error rejecting ad: $e')));
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

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: const Color(0xFFd2982a),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFFd2982a),
            tabs: const [Tab(text: 'Pending Review'), Tab(text: 'Active Ads')],
          ),
          Expanded(
            child: TabBarView(
              children: [_buildPendingAdsList(), _buildActiveAdsList()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAdsList() {
    if (_pendingAds.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No ads pending review',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAds,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _pendingAds.length,
        itemBuilder: (context, index) {
          final ad = _pendingAds[index];
          return _buildAdCard(ad, isPending: true);
        },
      ),
    );
  }

  Widget _buildActiveAdsList() {
    if (_activeAds.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No active ads',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAds,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _activeAds.length,
        itemBuilder: (context, index) {
          final ad = _activeAds[index];
          return _buildAdCard(ad, isPending: false);
        },
      ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad, {required bool isPending}) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final startDate = ad['startDate'];
    final endDate = ad['endDate'];

    final dateRangeText =
        startDate != null && endDate != null
            ? '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}'
            : 'Date range not specified';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with business info
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad['businessName'] ?? 'Unknown Business',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        ad['adType'] ?? 'Unknown Type',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${ad['cost'] ?? 0}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFd2982a),
                  ),
                ),
              ],
            ),
          ),

          // Ad image if available
          if (ad['imageUrl'] != null && ad['imageUrl'].isNotEmpty)
            Image.network(
              ad['imageUrl'],
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.white60,
                    ),
                  ),
            ),

          // Ad details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad['title'] ?? 'Untitled Ad',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(dateRangeText),
                const SizedBox(height: 4),
                if (ad['targetUrl'] != null && ad['targetUrl'].isNotEmpty)
                  Text(
                    'Link: ${ad['targetUrl']}',
                    style: const TextStyle(color: Colors.blue),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 16),

                // Action buttons for pending ads
                if (isPending)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _rejectAd(ad['id']),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('REJECT'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => _approveAd(ad['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('APPROVE'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
