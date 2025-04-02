import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:neusenews/models/ad.dart';

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
    _loadPendingAds();
  }

  Future<void> _loadPendingAds() async {
    setState(() => _isLoading = true);

    try {
      final snapshot =
          await _firestore
              .collection('ads')
              .where('status', isEqualTo: AdStatus.pending.index)
              .get();

      setState(() {
        _pendingAds =
            snapshot.docs.map((doc) => Ad.fromFirestore(doc)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading ads: $e')));
    }
  }

  Future<void> _approveAd(Ad ad) async {
    try {
      await _firestore.collection('ads').doc(ad.id).update({
        'status': AdStatus.active.index,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ad approved successfully')));

      _loadPendingAds();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving ad: $e')));
    }
  }

  Future<void> _rejectAd(Ad ad) async {
    try {
      await _firestore.collection('ads').doc(ad.id).update({
        'status': AdStatus.rejected.index,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ad rejected')));

      _loadPendingAds();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error rejecting ad: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Advertisements'),
        backgroundColor: const Color(0xFFd2982a),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _pendingAds.isEmpty
              ? const Center(child: Text('No pending ads to review'))
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              ad.headline,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(ad.businessName),
            trailing: Text(_getAdTypeDisplayName(ad.type)),
          ),
          if (ad.imageUrl.isNotEmpty)
            Image.network(
              ad.imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 50),
                    ),
                  ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ad.description),
                const SizedBox(height: 8),
                Text('Link: ${ad.linkUrl}'),
                const Divider(),
                _buildInfoRow(
                  'Start Date:',
                  DateFormat('MM/dd/yyyy').format(ad.startDate),
                ),
                _buildInfoRow(
                  'End Date:',
                  DateFormat('MM/dd/yyyy').format(ad.endDate),
                ),
                _buildInfoRow('Ad Cost:', '\$${ad.cost.toStringAsFixed(2)}'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectAd(ad),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveAd(ad),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getAdTypeDisplayName(AdType type) {
    switch (type) {
      case AdType.titleSponsor:
        return 'Title Sponsor';
      case AdType.inFeedDashboard:
        return 'In-Feed Dashboard Ad';
      case AdType.inFeedNews:
        return 'In-Feed News Ad';
      case AdType.weather:
        return 'Weather Sponsor';
    }
  }
}
