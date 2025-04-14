import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // For charts

class AdManagementScreen extends StatefulWidget {
  const AdManagementScreen({super.key});

  @override
  State<AdManagementScreen> createState() => _AdManagementScreenState();
}

class _AdManagementScreenState extends State<AdManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingAds = [];
  List<Map<String, dynamic>> _activeAds = [];

  // Analytics data
  int _totalAds = 0;
  int _totalImpressions = 0;
  int _totalClicks = 0;
  double _totalRevenue = 0.0;
  double _averageCTR = 0.0;

  // Time period analytics data
  Map<String, dynamic> _monthlyData = {};
  Map<String, dynamic> _advertiserPerformance = {};

  @override
  void initState() {
    super.initState();
    _loadAds();
    _loadAnalyticsData();
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
              'impressions': data['impressions'] ?? 0,
              'clicks': data['clicks'] ?? 0,
            };
          }).toList();

      setState(() {
        _pendingAds = pendingAds;
        _activeAds = activeAds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading ads: $e')));
      }
    }
  }

  Future<void> _loadAnalyticsData() async {
    try {
      // Get all ads (not just active or pending)
      final adsSnapshot =
          await FirebaseFirestore.instance.collection('ads').get();

      int totalAds = adsSnapshot.size;
      int totalImpressions = 0;
      int totalClicks = 0;
      double totalRevenue = 0.0;

      // Monthly data for charts
      Map<int, int> monthlyImpressions = {};
      Map<int, int> monthlyClicks = {};
      Map<int, double> monthlyRevenue = {};
      Map<String, Map<String, dynamic>> advertiserStats = {};

      // Initialize monthly data
      final now = DateTime.now();
      for (int i = 5; i >= 0; i--) {
        final month = now.month - i > 0 ? now.month - i : now.month - i + 12;
        monthlyImpressions[month] = 0;
        monthlyClicks[month] = 0;
        monthlyRevenue[month] = 0.0;
      }

      // Process all ads
      for (var doc in adsSnapshot.docs) {
        final data = doc.data();
        final impressions = data['impressions'] ?? 0;
        final clicks = data['clicks'] ?? 0;
        final cost = (data['cost'] ?? 0).toDouble();
        final businessId = data['businessId'] ?? 'unknown';
        final businessName = data['businessName'] ?? 'Unknown Business';

        totalImpressions += (impressions as int);
        totalClicks += (clicks as num).toInt();
        totalRevenue += cost;

        // Update monthly data if ad has startDate
        if (data['startDate'] != null) {
          final startDate = (data['startDate'] as Timestamp).toDate();
          if (startDate.isAfter(DateTime(now.year, now.month - 6))) {
            final month = startDate.month;
            monthlyImpressions[month] =
                (monthlyImpressions[month] ?? 0) + impressions.toInt();
            monthlyClicks[month] = (monthlyClicks[month] ?? 0) + clicks.toInt();
            monthlyRevenue[month] = (monthlyRevenue[month] ?? 0) + cost;
          }
        }

        // Update advertiser stats
        if (!advertiserStats.containsKey(businessId)) {
          advertiserStats[businessId] = {
            'businessName': businessName,
            'impressions': 0,
            'clicks': 0,
            'revenue': 0.0,
            'adCount': 0,
          };
        }
        advertiserStats[businessId]!['impressions'] += impressions.toInt();
        advertiserStats[businessId]!['clicks'] += clicks.toInt();
        advertiserStats[businessId]!['revenue'] += cost;
        advertiserStats[businessId]!['adCount'] += 1;
      }

      // Calculate CTR
      final averageCTR =
          totalImpressions > 0 ? (totalClicks / totalImpressions) * 100 : 0.0;

      // Create chart data
      final List<FlSpot> impressionsData = [];
      final List<FlSpot> clicksData = []; // Add this line
      final List<FlSpot> revenueData = [];

      monthlyImpressions.forEach((month, value) {
        impressionsData.add(FlSpot(month.toDouble(), value.toDouble()));
      });

      monthlyClicks.forEach((month, value) {
        clicksData.add(FlSpot(month.toDouble(), value.toDouble()));
      });

      monthlyRevenue.forEach((month, value) {
        revenueData.add(FlSpot(month.toDouble(), value));
      });

      // Sort data
      impressionsData.sort((a, b) => a.x.compareTo(b.x));
      revenueData.sort((a, b) => a.x.compareTo(b.x));

      // Sort advertisers by revenue
      final sortedAdvertisers =
          advertiserStats.entries.toList()..sort(
            (a, b) => (b.value['revenue'] as double).compareTo(
              a.value['revenue'] as double,
            ),
          );

      setState(() {
        _totalAds = totalAds;
        _totalImpressions = totalImpressions;
        _totalClicks = totalClicks;
        _totalRevenue = totalRevenue;
        _averageCTR = averageCTR;
        _monthlyData = {
          'impressions': impressionsData,
          'clicks': clicksData, // Add this line
          'revenue': revenueData,
        };
        _advertiserPerformance = Map.fromEntries(sortedAdvertisers.take(10));
      });
    } catch (e) {
      debugPrint('Error loading analytics data: $e');
    }
  }

  Future<void> _approveAd(String id) async {
    try {
      await FirebaseFirestore.instance.collection('ads').doc(id).update({
        'status': 'active',
        'approvedAt': FieldValue.serverTimestamp(),
        'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad approved successfully!')),
        );
      }

      _loadAds(); // Refresh list
      _loadAnalyticsData(); // Refresh analytics
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error approving ad: $e')));
      }
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

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Ad rejected')));
        }

        _loadAds(); // Refresh list
        _loadAnalyticsData(); // Refresh analytics
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error rejecting ad: $e')));
        }
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
      length: 3, // Now 3 tabs: Pending, Active, Analytics
      child: Column(
        children: [
          TabBar(
            labelColor: const Color(0xFFd2982a),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFFd2982a),
            tabs: const [
              Tab(text: 'Pending Review'),
              Tab(text: 'Active Ads'),
              Tab(text: 'Analytics'), // New tab!
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPendingAdsList(),
                _buildActiveAdsList(),
                _buildAnalyticsView(), // New view!
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAdsList() {
    // Existing implementation...
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
    // Existing implementation...
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

  // NEW METHOD: Analytics View
  Widget _buildAnalyticsView() {
    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall metrics
            _buildMetricsOverview(),

            const SizedBox(height: 24),

            // Performance charts
            _buildPerformanceCharts(),

            const SizedBox(height: 24),

            // Top advertisers
            _buildTopAdvertisers(),
          ],
        ),
      ),
    );
  }

  // NEW METHOD: Metrics overview cards
  Widget _buildMetricsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Advertising Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1, // Change from 1.5 to 1.7 for more height
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Ads',
              _totalAds.toString(),
              Icons.ad_units,
              const Color(0xFFd2982a),
            ),
            _buildMetricCard(
              'Total Impressions',
              NumberFormat.compact().format(_totalImpressions),
              Icons.visibility,
              Colors.blue,
            ),
            _buildMetricCard(
              'Total Clicks',
              NumberFormat.compact().format(_totalClicks),
              Icons.touch_app,
              Colors.green,
            ),
            _buildMetricCard(
              'Revenue',
              NumberFormat.currency(symbol: '\$').format(_totalRevenue),
              Icons.attach_money,
              Colors.purple,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Average Click-Through Rate',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_averageCTR.toStringAsFixed(2)}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFd2982a),
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _averageCTR / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFd2982a),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // NEW METHOD: Performance charts
  Widget _buildPerformanceCharts() {
    if (_monthlyData.isEmpty || (_monthlyData['impressions'] as List).isEmpty) {
      return const SizedBox.shrink();
    }

    final impressionsData = _monthlyData['impressions'] as List<FlSpot>;
    final revenueData = _monthlyData['revenue'] as List<FlSpot>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Trends',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Impressions chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Impressions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final month = value.toInt();
                              return Text(
                                DateFormat.MMM().format(DateTime(0, month)),
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: impressionsData,
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.lightBlue],
                          ),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Color.fromRGBO(
                                  0,
                                  122,
                                  255,
                                  0.3,
                                ), // Blue with 0.3 opacity
                                Color.fromRGBO(
                                  104,
                                  195,
                                  255,
                                  0.1,
                                ), // Light blue with 0.1 opacity
                              ],
                            ),
                          ),
                        ),
                      ],
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Revenue chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Revenue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '\$${value.toInt()}',
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final month = value.toInt();
                              return Text(
                                DateFormat.MMM().format(DateTime(0, month)),
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: revenueData,
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [Colors.purple, Colors.purpleAccent],
                          ),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Color.fromRGBO(
                                  128,
                                  0,
                                  128,
                                  0.3,
                                ), // Purple with 0.3 opacity
                                Color.fromRGBO(
                                  255,
                                  0,
                                  255,
                                  0.1,
                                ), // Purple accent with 0.1 opacity
                              ],
                            ),
                          ),
                        ),
                      ],
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // NEW METHOD: Top advertisers table
  Widget _buildTopAdvertisers() {
    if (_advertiserPerformance.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Advertisers',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Business')),
                DataColumn(label: Text('Ads')),
                DataColumn(label: Text('Impressions')),
                DataColumn(label: Text('Clicks')),
                DataColumn(label: Text('Revenue')),
                DataColumn(label: Text('CTR')),
              ],
              rows:
                  _advertiserPerformance.entries.map((entry) {
                    final business = entry.value;
                    final impressions = business['impressions'] as int;
                    final clicks = business['clicks'] as int;
                    final ctr =
                        impressions > 0 ? (clicks / impressions) * 100 : 0.0;

                    return DataRow(
                      cells: [
                        DataCell(Text(business['businessName'] ?? 'Unknown')),
                        DataCell(Text(business['adCount'].toString())),
                        DataCell(
                          Text(NumberFormat.compact().format(impressions)),
                        ),
                        DataCell(Text(NumberFormat.compact().format(clicks))),
                        DataCell(
                          Text('\$${business['revenue'].toStringAsFixed(2)}'),
                        ),
                        DataCell(Text('${ctr.toStringAsFixed(2)}%')),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
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
          // Your existing ad card implementation
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

                // Performance metrics for active ads
                if (!isPending && ad['impressions'] != null) ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Impressions: ${NumberFormat.compact().format(ad['impressions'])}',
                      ),
                      Text(
                        'Clicks: ${NumberFormat.compact().format(ad['clicks'] ?? 0)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CTR: ${ad['impressions'] > 0 ? ((ad['clicks'] ?? 0) / ad['impressions'] * 100).toStringAsFixed(2) : 0}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
