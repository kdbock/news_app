import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';

class InvestorDashboardScreen extends StatefulWidget {
  const InvestorDashboardScreen({super.key});

  @override
  State<InvestorDashboardScreen> createState() =>
      _InvestorDashboardScreenState();
}

class _InvestorDashboardScreenState extends State<InvestorDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _investorData = {};
  List<Map<String, dynamic>> _recentReports = [];

  // User metrics
  int _monthlyActiveUsers = 0;
  int _totalAppDownloads = 0;

  // Content metrics
  int _totalArticles = 0;
  int _totalSponsored = 0;

  // Financial metrics
  double _monthlyRevenue = 0;
  double _yearToDateRevenue = 0;
  double _projectedAnnual = 0;

  // Growth metrics
  double _userGrowthRate = 0;
  double _revenueGrowthRate = 0;

  // Chart data
  List<FlSpot> _revenueData = [];
  List<FlSpot> _userGrowthData = []; // Future use for user growth visualization

  @override
  void initState() {
    super.initState();
    _loadInvestorData();
  }

  Future<void> _loadInvestorData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not logged in');
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!userDoc.exists || userDoc.data()?['isInvestor'] != true) {
        throw Exception('Not authorized as investor');
      }

      final dashboardSnapshot =
          await FirebaseFirestore.instance
              .collection('investorDashboard')
              .doc('latest')
              .get();

      if (!dashboardSnapshot.exists) {
        throw Exception('Investor data not found');
      }

      final data = dashboardSnapshot.data()!;

      final reportsSnapshot =
          await FirebaseFirestore.instance
              .collection('investorReports')
              .orderBy('publishedAt', descending: true)
              .limit(5)
              .get();

      final reports =
          reportsSnapshot.docs.map((doc) {
            final rData = doc.data();
            return {
              'id': doc.id,
              'title': rData['title'] ?? '',
              'publishedAt': rData['publishedAt'] ?? Timestamp.now(),
              'type': rData['type'] ?? 'general',
              'fileUrl': rData['fileUrl'] ?? '',
            };
          }).toList();

      final List<dynamic> revenueHistory = data['revenueHistory'] ?? [];
      final List<dynamic> userGrowthHistory = data['userGrowthHistory'] ?? [];

      final revenueSpots =
          revenueHistory.asMap().entries.map((entry) {
            return FlSpot(
              entry.key.toDouble(),
              entry.value['value'].toDouble(),
            );
          }).toList();

      final userGrowthSpots =
          userGrowthHistory.asMap().entries.map((entry) {
            return FlSpot(
              entry.key.toDouble(),
              entry.value['value'].toDouble(),
            );
          }).toList();

      setState(() {
        _investorData = data;
        _recentReports = reports;

        _monthlyActiveUsers = data['monthlyActiveUsers'] ?? 0;
        _totalAppDownloads = data['totalAppDownloads'] ?? 0;

        _totalArticles = data['totalArticles'] ?? 0;
        _totalSponsored = data['totalSponsored'] ?? 0;

        _monthlyRevenue = data['monthlyRevenue']?.toDouble() ?? 0;
        _yearToDateRevenue = data['yearToDateRevenue']?.toDouble() ?? 0;
        _projectedAnnual = data['projectedAnnual']?.toDouble() ?? 0;

        _userGrowthRate = data['userGrowthRate']?.toDouble() ?? 0;
        _revenueGrowthRate = data['revenueGrowthRate']?.toDouble() ?? 0;

        _revenueData = revenueSpots;
        _userGrowthData = userGrowthSpots;

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading investor data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvestorData,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadInvestorData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildFinancialMetrics(),
                      const SizedBox(height: 24),
                      _buildRevenueChart(),
                      const SizedBox(height: 24),
                      _buildUserMetrics(),
                      const SizedBox(height: 24),
                      _buildContentMetrics(),
                      const SizedBox(height: 24),
                      _buildRecentReports(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildHeader() {
    final date = _investorData['lastUpdated'] ?? Timestamp.now();
    final lastUpdated = DateFormat('MMMM d, yyyy').format(date.toDate());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Financial Overview',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          'Last updated: $lastUpdated',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildFinancialMetrics() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revenue',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Monthly Revenue',
                currencyFormat.format(_monthlyRevenue),
                Icons.trending_up,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'YTD Revenue',
                currencyFormat.format(_yearToDateRevenue),
                Icons.calendar_today,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Projected Annual',
                currencyFormat.format(_projectedAnnual),
                Icons.show_chart,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Growth Rate',
                '${_revenueGrowthRate.toStringAsFixed(1)}%',
                _revenueGrowthRate >= 0
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                _revenueGrowthRate >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  const months = [
                    'Jan',
                    'Feb',
                    'Mar',
                    'Apr',
                    'May',
                    'Jun',
                    'Jul',
                    'Aug',
                    'Sep',
                    'Oct',
                    'Nov',
                    'Dec',
                  ];
                  final index = value.toInt();
                  return Text(
                    index >= 0 && index < months.length ? months[index] : '',
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _revenueData,
              isCurved: true,
              color: const Color(0xFFd2982a),
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [const Color(0xFFd2982a).withAlpha(51)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMetrics() {
    final numberFormat = NumberFormat('#,###');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Metrics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Monthly Active Users',
                numberFormat.format(_monthlyActiveUsers),
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Total App Downloads',
                numberFormat.format(_totalAppDownloads),
                Icons.download,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMetricCard(
          'User Growth Rate',
          '${_userGrowthRate.toStringAsFixed(1)}%',
          _userGrowthRate >= 0 ? Icons.trending_up : Icons.trending_down,
          _userGrowthRate >= 0 ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildContentMetrics() {
    final numberFormat = NumberFormat('#,###');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Content Metrics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Articles',
                numberFormat.format(_totalArticles),
                Icons.article,
                Colors.indigo,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Sponsored Content',
                numberFormat.format(_totalSponsored),
                Icons.monetization_on,
                const Color(0xFFd2982a),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentReports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Reports',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._recentReports.map((report) {
          final date = (report['publishedAt'] as Timestamp).toDate();
          final formattedDate = DateFormat('MMM d, yyyy').format(date);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: _getReportIcon(report['type']),
              title: Text(report['title']),
              subtitle: Text('Published: $formattedDate'),
              trailing: IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  // Download report
                  _downloadReport(report['fileUrl']);
                },
              ),
              onTap: () {
                // View report details
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25), // Fixed deprecated withOpacity
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Icon _getReportIcon(String type) {
    switch (type) {
      case 'financial':
        return Icon(Icons.attach_money, color: Colors.green[700]);
      case 'user':
        return Icon(Icons.people, color: Colors.blue[700]);
      case 'content':
        return Icon(Icons.article, color: Colors.indigo[700]);
      case 'quarterly':
        return Icon(Icons.event_note, color: Colors.purple[700]);
      default:
        return Icon(Icons.description, color: Colors.grey[700]);
    }
  }

  Future<void> _downloadReport(String fileUrl) async {
    if (fileUrl.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report URL not available')));
      return;
    }

    try {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $fileUrl';
      }
    } catch (e) {
      if (!mounted) return; // Fixed use of BuildContext across async gap
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error downloading report: $e')));
    }
  }
}
