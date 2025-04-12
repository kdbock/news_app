import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:neusenews/features/advertising/models/ad_type.dart';
import 'package:neusenews/features/advertising/models/ad_status.dart';
import 'package:neusenews/widgets/app_drawer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:neusenews/features/advertising/screens/advertiser/ad_creation_screen.dart';
import 'package:neusenews/features/advertising/widgets/ad_analytics_dashboard.dart';

class AdvertiserDashboardScreen extends StatefulWidget {
  const AdvertiserDashboardScreen({super.key});

  @override
  State<AdvertiserDashboardScreen> createState() =>
      _AdvertiserDashboardScreenState();
}

class _AdvertiserDashboardScreenState extends State<AdvertiserDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;

  // Dashboard metrics
  int _activeAds = 0;
  int _pendingAds = 0;
  int _totalImpressions = 0;
  int _totalClicks = 0;
  double _averageCTR = 0;
  double _totalSpent = 0;

  // Monthly data for charts
  List<FlSpot> _impressionsData = [];
  List<FlSpot> _clicksData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAdvertiserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdvertiserData() async {
    setState(() => _isLoading = true);

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get all ads for this advertiser
      final adSnapshot =
          await _firestore
              .collection('ads')
              .where('businessId', isEqualTo: userId)
              .get();

      if (!mounted) return;

      // Calculate metrics
      int activeAds = 0;
      int pendingAds = 0;
      int totalImpressions = 0;
      int totalClicks = 0;
      double totalSpent = 0;

      final now = DateTime.now();

      // Map to store monthly impressions and clicks
      final Map<int, int> monthlyImpressions = {};
      final Map<int, int> monthlyClicks = {};

      // Initialize maps for past 6 months
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        monthlyImpressions[month.month] = 0;
        monthlyClicks[month.month] = 0;
      }

      for (final doc in adSnapshot.docs) {
        final ad = doc.data();
        final adStatus = ad['status'] as int;
        final endDate = (ad['endDate'] as Timestamp).toDate();

        // Active ads
        if (adStatus == AdStatus.active.index &&
            endDate.isAfter(DateTime.now())) {
          activeAds++;
        }

        // Pending ads
        if (adStatus == AdStatus.pending.index) {
          pendingAds++;
        }

        // Metrics
        final impressions = ad['impressions'] as int? ?? 0;
        final clicks = ad['clicks'] as int? ?? 0;
        totalImpressions += impressions;
        totalClicks += clicks;

        final cost = ad['cost'] as num? ?? 0;
        totalSpent += cost.toDouble();

        // Get ad start date's month (for monthly data)
        final startDate = (ad['startDate'] as Timestamp).toDate();

        // Only include recent data (last 6 months)
        if (startDate.isAfter(DateTime(now.year, now.month - 6))) {
          monthlyImpressions[startDate.month] =
              (monthlyImpressions[startDate.month] ?? 0) + impressions;
          monthlyClicks[startDate.month] =
              (monthlyClicks[startDate.month] ?? 0) + clicks;
        }
      }

      // Calculate CTR
      final averageCTR =
          totalImpressions > 0
              ? (totalClicks / totalImpressions) * 100
              : 0.0; // Ensure it's a double

      // Create chart data
      final impressionsData = <FlSpot>[];
      final clicksData = <FlSpot>[];

      monthlyImpressions.forEach((month, impressions) {
        impressionsData.add(FlSpot(month.toDouble(), impressions.toDouble()));
      });

      monthlyClicks.forEach((month, clicks) {
        clicksData.add(FlSpot(month.toDouble(), clicks.toDouble()));
      });

      // Sort spots by month
      impressionsData.sort((a, b) => a.x.compareTo(b.x));
      clicksData.sort((a, b) => a.x.compareTo(b.x));

      setState(() {
        _activeAds = activeAds;
        _pendingAds = pendingAds;
        _totalImpressions = totalImpressions;
        _totalClicks = totalClicks;
        _averageCTR = averageCTR;
        _totalSpent = totalSpent;
        _impressionsData = impressionsData;
        _clicksData = clicksData;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading advertiser data: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advertiser Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFd2982a),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Active Ads'),
            Tab(text: 'Ad History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateAd(),
            tooltip: 'Create New Ad',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFd2982a)),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildActiveAdsTab(),
                  _buildAdHistoryTab(),
                ],
              ),
    );
  }

  Widget _buildOverviewTab() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return RefreshIndicator(
      onRefresh: _loadAdvertiserData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key metrics cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16.0,
              crossAxisSpacing: 16.0,
              childAspectRatio: 1.5,
              children: [
                _buildMetricCard(
                  'Active Ads',
                  _activeAds.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Pending Approval',
                  _pendingAds.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
                _buildMetricCard(
                  'Impressions',
                  _totalImpressions.toString(),
                  Icons.visibility,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Clicks',
                  _totalClicks.toString(),
                  Icons.touch_app,
                  Colors.purple,
                ),
                _buildMetricCard(
                  'Avg. CTR',
                  '${_averageCTR.toStringAsFixed(2)}%',
                  Icons.trending_up,
                  Colors.teal,
                ),
                _buildMetricCard(
                  'Total Spent',
                  currencyFormat.format(_totalSpent),
                  Icons.attach_money,
                  const Color(0xFFd2982a),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Replace multiple separate widgets with the unified dashboard
            AdAnalyticsDashboard(
              businessId: _auth.currentUser?.uid,
              // Customize which sections to show
              showRoiCalculator: true,
              showPerformanceChart: true,
              showAudienceBreakdown: true,
              showConversionMetrics: true,
            ),

            const SizedBox(height: 24),

            // CTA button for new ad
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToCreateAd(),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('CREATE NEW AD'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd2982a),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAdsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('ads')
              .where('businessId', isEqualTo: _auth.currentUser?.uid)
              .where('status', isEqualTo: AdStatus.active.index)
              .where(
                'endDate',
                isGreaterThan: Timestamp.fromDate(DateTime.now()),
              )
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFd2982a)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final activeAds = snapshot.data?.docs ?? [];

        if (activeAds.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.ad_units, size: 72, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No active ads',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Create a new ad to get started',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: activeAds.length,
          itemBuilder: (context, index) {
            final ad = activeAds[index].data() as Map<String, dynamic>;

            final endDate = (ad['endDate'] as Timestamp).toDate();
            final daysLeft = endDate.difference(DateTime.now()).inDays;

            final adType = AdType.values[ad['type'] as int];
            final impressions = ad['impressions'] as int? ?? 0;
            final clicks = ad['clicks'] as int? ?? 0;
            final ctr = impressions > 0 ? (clicks / impressions) * 100 : 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ad image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    child: Image.network(
                      ad['imageUrl'] ?? '',
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 150,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 48),
                          ),
                        );
                      },
                    ),
                  ),

                  // Ad content
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFd2982a),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getAdTypeDisplayName(adType),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$daysLeft days left',
                              style: TextStyle(
                                color:
                                    daysLeft < 5
                                        ? Colors.red
                                        : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ad['headline'] ?? 'Untitled Ad',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ad['description'] ?? 'No description provided',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 16),

                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildAdStat('Impressions', impressions.toString()),
                            _buildAdStat('Clicks', clicks.toString()),
                            _buildAdStat('CTR', '${ctr.toStringAsFixed(2)}%'),
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
      },
    );
  }

  Widget _buildAdHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('ads')
              .where('businessId', isEqualTo: _auth.currentUser?.uid)
              .orderBy('startDate', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFd2982a)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allAds = snapshot.data?.docs ?? [];

        if (allAds.isEmpty) {
          return const Center(child: Text('No ad history found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: allAds.length,
          itemBuilder: (context, index) {
            final ad = allAds[index].data() as Map<String, dynamic>;
            final adType = AdType.values[ad['type'] as int];
            final adStatus = AdStatus.values[ad['status'] as int];

            final startDate = (ad['startDate'] as Timestamp).toDate();
            final endDate = (ad['endDate'] as Timestamp).toDate();

            final formattedStartDate = DateFormat.yMMMd().format(startDate);
            final formattedEndDate = DateFormat.yMMMd().format(endDate);

            final impressions = ad['impressions'] as int? ?? 0;
            final clicks = ad['clicks'] as int? ?? 0;

            // Get status color
            Color statusColor;
            switch (adStatus) {
              case AdStatus.active:
                statusColor = Colors.green;
                break;
              case AdStatus.pending:
                statusColor = Colors.orange;
                break;
              case AdStatus.rejected:
                statusColor = Colors.red;
                break;
              case AdStatus.expired:
              case AdStatus.deleted:
                statusColor = Colors.grey;
                break;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(
                      image: NetworkImage(ad['imageUrl'] ?? ''),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        // No need to handle error here as we have backup icon
                      },
                    ),
                  ),
                  child:
                      ad['imageUrl'] == null
                          ? const Icon(Icons.image_not_supported)
                          : null,
                ),
                title: Text(
                  ad['headline'] ?? 'Untitled Ad',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '$formattedStartDate to $formattedEndDate\n'
                  'Type: ${_getAdTypeDisplayName(adType)} • Impressions: $impressions • Clicks: $clicks',
                ),
                isThreeLine: true,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    border: Border.all(color: statusColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusDisplayName(adStatus),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                onTap: () {
                  // Navigate to ad details if needed
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFd2982a),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
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
            spots: _impressionsData,
            isCurved: true,
            gradient: LinearGradient(colors: [Colors.blue, Colors.lightBlue]),
            barWidth: 4,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: _clicksData,
            isCurved: true,
            gradient: LinearGradient(colors: [Colors.red, Colors.orange]),
            barWidth: 4,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(Color color, String label) {
    return Row(
      children: [
        CircleAvatar(backgroundColor: color, radius: 6),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildAdStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12.0)),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
      ],
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
      case AdType.bannerAd:
        return 'Banner Ad';
    }
  }

  String _getStatusDisplayName(AdStatus status) {
    switch (status) {
      case AdStatus.active:
        return 'Active';
      case AdStatus.pending:
        return 'Pending';
      case AdStatus.rejected:
        return 'Rejected';
      case AdStatus.expired:
        return 'Expired';
      case AdStatus.deleted:
        return 'Deleted';
    }
  }

  void _navigateToCreateAd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdCreationScreen()),
    );
  }
}
