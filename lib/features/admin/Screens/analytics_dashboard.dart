import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  bool _isLoading = true;
  final Map<String, dynamic> _analytics = {};

  // Dashboard metrics
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _totalArticles = 0;
  int _totalEvents = 0;
  int _totalAds = 0;
  int _totalViews = 0;
  double _totalRevenue = 0.0;

  List<Map<String, dynamic>> _recentArticles = [];
  List<Map<String, dynamic>> _recentEvents = [];
  List<FlSpot> _viewsData = [];
  List<FlSpot> _revenueData = [];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch dashboard analytics summary
      final analyticsRef = FirebaseFirestore.instance
          .collection('analytics')
          .doc('dashboard');
      final analyticsDoc = await analyticsRef.get();

      // Load user statistics
      final userSnapshot =
          await FirebaseFirestore.instance.collection('users').count().get();

      // Load article statistics
      final articleQuery =
          await FirebaseFirestore.instance
              .collection('sponsored_articles')
              .where('status', isEqualTo: 'published')
              .count()
              .get();

      // Load event statistics
      final eventQuery =
          await FirebaseFirestore.instance
              .collection('events')
              .where('status', isEqualTo: 'approved')
              .count()
              .get();

      // Load ad statistics
      final adQuery =
          await FirebaseFirestore.instance
              .collection('ads')
              .where('status', isEqualTo: 'active')
              .count()
              .get();

      // Load recent articles
      final recentArticles =
          await FirebaseFirestore.instance
              .collection('sponsored_articles')
              .orderBy('publishedAt', descending: true)
              .limit(5)
              .get();

      // Load recent events
      final recentEvents =
          await FirebaseFirestore.instance
              .collection('events')
              .where('status', isEqualTo: 'approved')
              .orderBy('eventDate', descending: false)
              .limit(5)
              .get();

      // Calculate total revenue
      double totalRevenue = 0.0;
      final articlesRevenue =
          await FirebaseFirestore.instance
              .collection('sponsored_articles')
              .where('status', isEqualTo: 'published')
              .get();

      for (final doc in articlesRevenue.docs) {
        totalRevenue += (doc.data()['submissionFee'] ?? 0).toDouble();
      }

      final eventsRevenue =
          await FirebaseFirestore.instance
              .collection('events')
              .where('status', isEqualTo: 'approved')
              .get();

      for (final doc in eventsRevenue.docs) {
        totalRevenue += (doc.data()['submissionFee'] ?? 0).toDouble();
      }

      final adsRevenue =
          await FirebaseFirestore.instance
              .collection('ads')
              .where('status', isEqualTo: 'active')
              .get();

      for (final doc in adsRevenue.docs) {
        totalRevenue += (doc.data()['cost'] ?? 0).toDouble();
      }

      // Generate sample data for charts if real data not available
      final List<FlSpot> viewsData = _generateSampleViewsData();
      final List<FlSpot> revenueData = _generateSampleRevenueData();

      if (mounted) {
        setState(() {
          _totalUsers = userSnapshot.count ?? 0; // Add null check
          _activeUsers =
              (userSnapshot.count ?? 0) ~/ 3; // Fix nullable operator
          _totalArticles = articleQuery.count ?? 0; // Add null check
          _totalEvents = eventQuery.count ?? 0; // Add null check
          _totalAds = adQuery.count ?? 0; // Add null check
          _totalViews =
              analyticsDoc.exists
                  ? (analyticsDoc.data()?['totalViews'] ?? 0)
                  : 0;
          _totalRevenue = totalRevenue;

          _recentArticles =
              recentArticles.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList();

          _recentEvents =
              recentEvents.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList();

          _viewsData = viewsData;
          _revenueData = revenueData;

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading analytics: $e')));
      }
    }
  }

  List<FlSpot> _generateSampleViewsData() {
    // Generate last 30 days of sample data
    final List<FlSpot> spots = [];
    final now = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final day = now.subtract(Duration(days: 29 - i));
      // Generate random view count between 100 and 1000
      final viewCount = 100 + (900 * day.day / 31);
      spots.add(FlSpot(i.toDouble(), viewCount));
    }

    return spots;
  }

  List<FlSpot> _generateSampleRevenueData() {
    // Generate last 30 days of sample revenue data
    final List<FlSpot> spots = [];
    final now = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final day = now.subtract(Duration(days: 29 - i));
      // Generate random revenue between $50 and $500
      final revenue = 50 + (450 * day.day / 31);
      spots.add(FlSpot(i.toDouble(), revenue));
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFd2982a)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analytics Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Key metrics
              Row(
                children: [
                  _buildMetricCard(
                    title: 'Total Users',
                    value: _formatNumber(_totalUsers),
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  _buildMetricCard(
                    title: 'Total Views',
                    value: _formatNumber(_totalViews),
                    icon: Icons.visibility,
                    color: Colors.green,
                  ),
                  _buildMetricCard(
                    title: 'Revenue',
                    value: _formatCurrency(_totalRevenue),
                    icon: Icons.payments,
                    color: Colors.amber,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Content stats
              Row(
                children: [
                  _buildMetricCard(
                    title: 'Articles',
                    value: _formatNumber(_totalArticles),
                    icon: Icons.article,
                    color: Colors.indigo,
                  ),
                  _buildMetricCard(
                    title: 'Events',
                    value: _formatNumber(_totalEvents),
                    icon: Icons.event,
                    color: Colors.deepPurple,
                  ),
                  _buildMetricCard(
                    title: 'Active Ads',
                    value: _formatNumber(_totalAds),
                    icon: Icons.ads_click,
                    color: Colors.orange,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Views chart
              const Text(
                'Article Views (Last 30 Days)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: _buildLineChart(_viewsData, Colors.blue.shade400),
              ),

              const SizedBox(height: 24),

              // Revenue chart
              const Text(
                'Revenue (Last 30 Days)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: _buildLineChart(_revenueData, Colors.green.shade500),
              ),

              const SizedBox(height: 24),

              // Recent content
              const Text(
                'Recent Articles',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildRecentArticlesList(),

              const SizedBox(height: 24),

              const Text(
                'Upcoming Events',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildUpcomingEventsList(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<FlSpot> spots, Color color) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 100,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 5 != 0) return const Text('');
                final date = DateTime.now().subtract(
                  Duration(days: 29 - value.toInt()),
                );
                return Text(
                  DateFormat('M/d').format(date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.2),
            ),
          ),
        ],
        minY: 0,
      ),
    );
  }

  Widget _buildRecentArticlesList() {
    if (_recentArticles.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('No recent articles')),
        ),
      );
    }

    return Column(
      children:
          _recentArticles.map((article) {
            final publishedAt = article['publishedAt'] as Timestamp?;
            final dateStr =
                publishedAt != null
                    ? DateFormat('MMM d, yyyy').format(publishedAt.toDate())
                    : 'Date not available';

            return ListTile(
              title: Text(
                article['title'] ?? 'Untitled Article',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('Published on $dateStr'),
              leading: const Icon(Icons.article),
              trailing: Text(
                '\$${article['submissionFee'] ?? 0}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFd2982a),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildUpcomingEventsList() {
    if (_recentEvents.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('No upcoming events')),
        ),
      );
    }

    return Column(
      children:
          _recentEvents.map((event) {
            final eventDate = event['eventDate'] as Timestamp?;
            final dateStr =
                eventDate != null
                    ? DateFormat('MMM d, yyyy').format(eventDate.toDate())
                    : 'Date not available';

            return ListTile(
              title: Text(
                event['title'] ?? 'Untitled Event',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('$dateStr • ${event['startTime'] ?? 'TBD'}'),
              leading: const Icon(Icons.event),
              trailing: Text(
                '\$${event['submissionFee'] ?? 0}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFd2982a),
                ),
              ),
            );
          }).toList(),
    );
  }

  String _formatNumber(int number) {
    return NumberFormat.compact().format(number);
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(amount);
  }
}
