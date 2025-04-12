import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:neusenews/features/advertising/models/ad.dart';
import 'package:neusenews/features/advertising/models/ad_type.dart';
import 'package:neusenews/features/advertising/models/ad_status.dart';
import 'package:neusenews/services/role_service.dart';
import 'package:neusenews/utils/error_handler.dart';

class ReviewAdsScreen extends StatefulWidget {
  const ReviewAdsScreen({super.key});

  @override
  State<ReviewAdsScreen> createState() => _ReviewAdsScreenState();
}

class _ReviewAdsScreenState extends State<ReviewAdsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Ad> _pendingAds = [];

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoadAds();
  }

  Future<void> _checkAdminAndLoadAds() async {
    setState(() => _isLoading = true);

    try {
      // Check if user has admin access
      bool isAdmin = await RoleService.hasAdminAccess();
      if (!isAdmin && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You do not have administrator access')),
        );
        return;
      }

      await _loadPendingAds();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPendingAds() async {
    try {
      final snapshot = await _firestore
          .collection('ads')
          .where('status', isEqualTo: AdStatus.pending.index)
          .orderBy('startDate', descending: false)
          .get();

      if (mounted) {
        setState(() {
          _pendingAds = snapshot.docs.map((doc) {
            final data = doc.data();
            return Ad(
              id: doc.id,
              businessId: data['businessId'] ?? '',
              businessName: data['businessName'] ?? '',
              headline: data['headline'] ?? '',
              description: data['description'] ?? '',
              imageUrl: data['imageUrl'] ?? '',
              linkUrl: data['linkUrl'] ?? '',
              type: AdType.values[data['type'] ?? 0],
              status: AdStatus.values[data['status'] ?? 0],
              startDate: (data['startDate'] as Timestamp).toDate(),
              endDate: (data['endDate'] as Timestamp).toDate(),
              impressions: data['impressions'] ?? 0,
              clicks: data['clicks'] ?? 0,
              ctr: data['ctr']?.toDouble() ?? 0.0,
              cost: data['cost']?.toDouble() ?? 0.0,
            );
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ads: $e')),
        );
      }
    }
  }

  Future<void> _approveAd(Ad ad) async {
    try {
      // Update ad status directly from this screen
      await _firestore.collection('ads').doc(ad.id).update({
        'status': AdStatus.active.index,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advertisement approved successfully')),
        );
        _loadPendingAds();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.handleAdError(
          context,
          'Failed to approve advertisement',
          e,
          onRetry: () => _approveAd(ad),
        );
      }
    }
  }

  Future<void> _rejectAd(Ad ad) async {
    // Show dialog to get rejection reason
    String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text('Rejection Reason'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for rejecting this advertisement:'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Enter rejection reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('REJECT'),
            ),
          ],
        );
      },
    );

    if (reason == null) return; // User canceled

    try {
      await _firestore.collection('ads').doc(ad.id).update({
        'status': AdStatus.rejected.index,
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advertisement rejected')),
        );
        _loadPendingAds();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting ad: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Advertisements'),
        backgroundColor: const Color(0xFFd2982a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingAds,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFd2982a)),
            )
          : _pendingAds.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No pending advertisements to review',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _pendingAds.length,
                  itemBuilder: (context, index) {
                    final ad = _pendingAds[index];
                    return _buildAdReviewCard(ad);
                  },
                ),
    );
  }

  Widget _buildAdReviewCard(Ad ad) {
    final DateFormat formatter = DateFormat('MM/dd/yyyy');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with business info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFd2982a),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.business, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ad.businessName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getAdTypeName(ad.type),
                    style: const TextStyle(
                      color: Color(0xFFd2982a),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ad title & detail
          ListTile(
            title: Text(
              ad.headline,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(ad.description),
                const SizedBox(height: 8),
                Text('Link: ${ad.linkUrl}'),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: 'Campaign Duration: ',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      TextSpan(
                        text: '${formatter.format(ad.startDate)} to ${formatter.format(ad.endDate)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: 'Ad Cost: ',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      TextSpan(
                        text: '\$${ad.cost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFd2982a),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            isThreeLine: true,
          ),

          // Ad image
          if (ad.imageUrl.isNotEmpty)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Image.network(
                ad.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                  ),
                ),
              ),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectAd(ad),
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text('REJECT'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveAd(ad),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('APPROVE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAdTypeName(AdType type) {
    switch (type) {
      case AdType.titleSponsor:
        return 'Title Sponsor';
      case AdType.inFeedDashboard:
        return 'In-Feed Dashboard';
      case AdType.inFeedNews:
        return 'In-Feed News';
      case AdType.weather:
        return 'Weather Sponsor';
      case AdType.bannerAd:
        return 'Banner Ad';
    }
  }
}
