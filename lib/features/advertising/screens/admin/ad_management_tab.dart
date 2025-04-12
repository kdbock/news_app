import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// Updated imports to use the new model locations
import 'package:neusenews/features/advertising/models/ad.dart';
import 'package:neusenews/features/advertising/models/ad_type.dart';
import 'package:neusenews/features/advertising/models/ad_status.dart';
// Removed redundant import as it references the current file

class AdManagementTab extends StatefulWidget {
  const AdManagementTab({super.key});

  @override
  State<AdManagementTab> createState() => _AdManagementTabState();
}

class _AdManagementTabState extends State<AdManagementTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AdStatus? _statusFilter;
  AdType? _typeFilter;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterSection(),
        Expanded(
          child: _buildAdList(),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<AdStatus?>(
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              value: _statusFilter,
              items: [
                const DropdownMenuItem<AdStatus?>(
                  value: null,
                  child: Text('All Status'),
                ),
                ...AdStatus.values.map((status) => DropdownMenuItem<AdStatus?>(
                      value: status,
                      child: Text(_getStatusName(status)),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _statusFilter = value;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<AdType?>(
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              value: _typeFilter,
              items: [
                const DropdownMenuItem<AdType?>(
                  value: null,
                  child: Text('All Types'),
                ),
                ...AdType.values.map((type) => DropdownMenuItem<AdType?>(
                      value: type,
                      child: Text(_getAdTypeName(type)),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _typeFilter = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdList() {
    Query query = _firestore.collection('ads').orderBy('startDate', descending: true);
    
    // Apply filters if selected
    if (_statusFilter != null) {
      query = query.where('status', isEqualTo: _statusFilter!.index);
    }
    
    if (_typeFilter != null) {
      query = query.where('type', isEqualTo: _typeFilter!.index);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFd2982a)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No advertisements found.'));
        }

        final ads = snapshot.data!.docs;

        return ListView.builder(
          itemCount: ads.length,
          itemBuilder: (context, index) {
            final adDoc = ads[index];
            final adData = adDoc.data() as Map<String, dynamic>;
            
            // Convert Firestore data to Ad object
            final Ad ad = Ad(
              id: adDoc.id,
              businessId: adData['businessId'] ?? '',
              businessName: adData['businessName'] ?? '',
              headline: adData['headline'] ?? '',
              description: adData['description'] ?? '',
              imageUrl: adData['imageUrl'] ?? '',
              linkUrl: adData['linkUrl'] ?? '',
              type: AdType.values[adData['type'] ?? 0],
              status: AdStatus.values[adData['status'] ?? 0],
              startDate: (adData['startDate'] as Timestamp).toDate(),
              endDate: (adData['endDate'] as Timestamp).toDate(),
              impressions: adData['impressions'] ?? 0,
              clicks: adData['clicks'] ?? 0,
              ctr: adData['ctr']?.toDouble() ?? 0.0,
              cost: adData['cost']?.toDouble() ?? 0.0,
            );
            
            return _buildAdCard(ad);
          },
        );
      },
    );
  }

  Widget _buildAdCard(Ad ad) {
    final DateFormat formatter = DateFormat('MM/dd/yyyy');
    final bool isActive = ad.status == AdStatus.active && 
                          ad.endDate.isAfter(DateTime.now());
    final Color statusColor = _getStatusColor(ad.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              ad.headline,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(ad.businessName),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(51), // Approximate equivalent to 0.2 opacity
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                _getStatusName(ad.status),
                style: TextStyle(color: statusColor),
              ),
            ),
          ),
          
          if (ad.imageUrl.isNotEmpty)
            Image.network(
              ad.imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 150,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported),
              ),
            ),
            
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Type: ${_getAdTypeName(ad.type)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Duration: ${formatter.format(ad.startDate)} to ${formatter.format(ad.endDate)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Performance: ${ad.impressions} impressions, ${ad.clicks} clicks (${ad.ctr.toStringAsFixed(2)}% CTR)',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Revenue: \$${ad.cost.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFd2982a),
                  ),
                ),
              ],
            ),
          ),
          
          OverflowBar(
            children: [
              if (ad.status == AdStatus.pending)
                TextButton(
                  onPressed: () => _approveAd(ad),
                  child: const Text('APPROVE'),
                ),
              if (ad.status == AdStatus.pending)
                TextButton(
                  onPressed: () => _rejectAd(ad),
                  child: const Text(
                    'REJECT',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              if (!isActive && ad.status == AdStatus.active)
                TextButton(
                  onPressed: () => _markAsExpired(ad),
                  child: const Text('MARK EXPIRED'),
                ),
              TextButton(
                onPressed: () => _deleteAd(ad),
                child: const Text(
                  'DELETE',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approveAd(Ad ad) async {
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('ads').doc(ad.id).update({
        'status': AdStatus.active.index,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad approved')),
        );
      }
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

  Future<void> _rejectAd(Ad ad) async {
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('ads').doc(ad.id).update({
        'status': AdStatus.rejected.index,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad rejected')),
        );
      }
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

  Future<void> _markAsExpired(Ad ad) async {
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('ads').doc(ad.id).update({
        'status': AdStatus.expired.index,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad marked as expired')),
        );
      }
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

  Future<void> _deleteAd(Ad ad) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Advertisement'),
        content: const Text('Are you sure you want to delete this ad? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await _firestore.collection('ads').doc(ad.id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad deleted')),
        );
      }
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
      // Add default case to prevent null return
      default:
        return 'Unknown'; // This prevents the null return error
    }
  }

  String _getStatusName(AdStatus status) {
    switch (status) {
      case AdStatus.pending:
        return 'Pending';
      case AdStatus.active:
        return 'Active';
      case AdStatus.rejected:
        return 'Rejected';
      case AdStatus.expired:
        return 'Expired';
      case AdStatus.deleted:
        return 'Deleted';
      // Add default case to prevent null return
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(AdStatus status) {
    switch (status) {
      case AdStatus.pending:
        return Colors.orange;
      case AdStatus.active:
        return Colors.green;
      case AdStatus.rejected:
        return Colors.red;
      case AdStatus.expired:
      case AdStatus.deleted:
        return Colors.grey;
      default:
        return Colors.grey; // Default color to prevent null return
    }
  }
}
