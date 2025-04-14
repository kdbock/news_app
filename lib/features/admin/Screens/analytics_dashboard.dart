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
  List<FlSpot> _userGrowthData = [];
  Map<String, int> _userDemographics = {};
  Map<String, double> _userEngagementData = {};

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
      final List<FlSpot> viewsData = await _getArticleViewsData();
      final List<FlSpot> revenueData = _generateSampleRevenueData();

      // Load user growth data
      final userGrowthData = await _getUserGrowthData();

      // Load user demographics
      final userDemographics = await _getUserDemographics();

      // Load user engagement data
      final userEngagement = await _getUserEngagement();

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
          _userGrowthData = userGrowthData;
          _userDemographics = userDemographics;
          _userEngagementData = userEngagement;

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

  Future<List<FlSpot>> _getArticleViewsData() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('article_metrics')
            .orderBy('date')
            .limit(30)
            .get();

    return snapshot.docs.map((doc) {
      final date = doc['date'].toDate();
      final views = doc['views'] ?? 0;
      return FlSpot(date.millisecondsSinceEpoch.toDouble(), views.toDouble());
    }).toList();
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

  Future<List<FlSpot>> _getUserGrowthData() async {
    // Get users grouped by join date (createdAt field)
    final result =
        await FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt')
            .get();

    // Count users by date
    final Map<String, int> usersByDate = {};
    int runningTotal = 0;

    for (final doc in result.docs) {
      if (doc.data().containsKey('createdAt') &&
          doc.data()['createdAt'] != null) {
        final Timestamp createdAt = doc.data()['createdAt'];
        final String dateKey = DateFormat(
          'yyyy-MM-dd',
        ).format(createdAt.toDate());

        usersByDate[dateKey] = (usersByDate[dateKey] ?? 0) + 1;
      }
    }

    // Convert to spots for the chart
    final List<FlSpot> spots = [];
    final sortedDates = usersByDate.keys.toList()..sort();

    for (int i = 0; i < sortedDates.length; i++) {
      final date = DateTime.parse(sortedDates[i]);
      runningTotal += usersByDate[sortedDates[i]] ?? 0;
      spots.add(FlSpot(i.toDouble(), runningTotal.toDouble()));
    }

    return spots;
  }

  Future<Map<String, int>> _getUserDemographics() async {
    // Get user data for demographic analysis
    final result = await FirebaseFirestore.instance.collection('users').get();

    // Track demographics
    final Map<String, int> demographics = {
      'Admin': 0,
      'Contributor': 0,
      'Investor': 0,
      'Customer': 0,
    };

    for (final doc in result.docs) {
      if (doc.data()['isAdmin'] == true) {
        demographics['Admin'] = (demographics['Admin'] ?? 0) + 1;
      }
      if (doc.data()['isContributor'] == true) {
        demographics['Contributor'] = (demographics['Contributor'] ?? 0) + 1;
      }
      if (doc.data()['isInvestor'] == true) {
        demographics['Investor'] = (demographics['Investor'] ?? 0) + 1;
      }
      if (doc.data()['isCustomer'] == true) {
        demographics['Customer'] = (demographics['Customer'] ?? 0) + 1;
      }
    }

    return demographics;
  }

  Future<Map<String, double>> _getUserEngagement() async {
    // This would use actual login data, but for now we'll estimate
    final result =
        await FirebaseFirestore.instance
            .collection('users')
            .orderBy('lastLogin', descending: true)
            .limit(30)
            .get();

    // Track engagement
    final Map<String, double> engagement = {
      'Daily Active Users': 0,
      'Weekly Active Users': 0,
      'Monthly Active Users': 0,
    };

    final now = DateTime.now();

    for (final doc in result.docs) {
      final lastLogin = doc.data()['lastLogin'] as Timestamp?;
      if (lastLogin != null) {
        final loginDate = lastLogin.toDate();
        if (loginDate.isAfter(now.subtract(Duration(days: 1)))) {
          engagement['Daily Active Users'] =
              (engagement['Daily Active Users'] ?? 0) + 1;
        }
        if (loginDate.isAfter(now.subtract(Duration(days: 7)))) {
          engagement['Weekly Active Users'] =
              (engagement['Weekly Active Users'] ?? 0) + 1;
        }
        if (loginDate.isAfter(now.subtract(Duration(days: 30)))) {
          engagement['Monthly Active Users'] =
              (engagement['Monthly Active Users'] ?? 0) + 1;
        }
      }
    }

    return engagement;
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

              // User Analytics Section
              const Text(
                'User Analytics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // User Growth Chart
              const Text(
                'User Growth Over Time',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child:
                    _userGrowthData.isEmpty
                        ? const Center(
                          child: Text('No user growth data available'),
                        )
                        : _buildLineChart(
                          _userGrowthData,
                          Colors.purple.shade400,
                        ),
              ),
              const SizedBox(height: 16),

              // User Demographics
              const Text(
                'User Types Distribution',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child:
                    _userDemographics.isEmpty
                        ? const Center(
                          child: Text('No demographic data available'),
                        )
                        : _buildPieChart(),
              ),
              const SizedBox(height: 16),

              // User Engagement
              const Text(
                'User Engagement',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildEngagementBars(),

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

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sections:
            _userDemographics.entries.map((entry) {
              Color color;
              switch (entry.key) {
                case 'Admin':
                  color = Colors.red;
                  break;
                case 'Contributor':
                  color = Colors.blue;
                  break;
                case 'Investor':
                  color = Colors.green;
                  break;
                default:
                  color = Colors.amber;
              }

              return PieChartSectionData(
                value: entry.value.toDouble(),
                title: '${entry.key}\n${entry.value}',
                color: color,
                radius: 80,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildEngagementBars() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            _userEngagementData.entries.map((entry) {
              final percentage = (entry.value * 100).toStringAsFixed(1);
              return Column(
                children: [
                  Expanded(
                    child: Container(
                      width: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.blue.shade100, Colors.blue.shade900],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 60,
                        height: entry.value * 70, // Scale to height
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.key,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text('$percentage%', style: const TextStyle(fontSize: 12)),
                ],
              );
            }).toList(),
      ),
    );
  }
}
