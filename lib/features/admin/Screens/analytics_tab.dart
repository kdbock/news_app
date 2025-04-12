import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  bool _isLoading = true;
  Map<String, dynamic> _metrics = {};
  
  // User engagement metrics
  int _dailyActiveUsers = 0;
  int _monthlyActiveUsers = 0;
  int _totalUsers = 0;
  
  // Content metrics
  int _totalArticles = 0;
  int _publishedToday = 0;
  int _totalViews = 0;
  
  // Revenue metrics
  double _revenueToday = 0.0;
  double _revenueThisMonth = 0.0;
  double _revenueYTD = 0.0;
  
  List<FlSpot> _userGrowthData = [];
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
      final snapshot = await FirebaseFirestore.instance
          .collection('analytics')
          .doc('dashboard')
          .get();
      
      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          _metrics = data;
          
          _dailyActiveUsers = data['dailyActiveUsers'] ?? 0;
          _monthlyActiveUsers = data['monthlyActiveUsers'] ?? 0;
          _totalUsers = data['totalUsers'] ?? 0;
          
          _totalArticles = data['totalArticles'] ?? 0;
          _publishedToday = data['publishedToday'] ?? 0;
          _totalViews = data['totalViews'] ?? 0;
          
          _revenueToday = (data['revenueToday'] ?? 0).toDouble();
          _revenueThisMonth = (data['revenueThisMonth'] ?? 0).toDouble();
          _revenueYTD = (data['revenueYTD'] ?? 0).toDouble();
          
          _userGrowthData = _parseChartData(data['userGrowthByDay'] ?? {});
          _viewsData = _parseChartData(data['viewsByDay'] ?? {});
          _revenueData = _parseChartData(data['revenueByDay'] ?? {});
          
          _isLoading = false;
        });
      } else {
        throw Exception('Analytics data not found');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: $e')),
      );
    }
  }
  
  List<FlSpot> _parseChartData(Map<String, dynamic> data) {
    final List<FlSpot> spots = [];
    final sortedKeys = data.keys.toList()..sort();
    
    for (int i = 0; i < sortedKeys.length; i++) {
      final value = data[sortedKeys[i]] ?? 0;
      spots.add(FlSpot(i.toDouble(), value.toDouble()));
    }
    
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildMetricSections(),
          
          const SizedBox(height: 32),
          _buildChartSection(),
        ],
      ),
    );
  }
  
  Widget _buildMetricSections() {
    return Column(
      children: [
        _buildMetricSection(
          title: 'User Engagement',
          metrics: [
            {'label': 'Daily Active Users', 'value': _formatNumber(_dailyActiveUsers)},
            {'label': 'Monthly Active Users', 'value': _formatNumber(_monthlyActiveUsers)},
            {'label': 'Total Users', 'value': _formatNumber(_totalUsers)},
          ],
          icon: Icons.people,
          color: Colors.blue,
        ),
        
        const SizedBox(height: 16),
        _buildMetricSection(
          title: 'Content',
          metrics: [
            {'label': 'Total Articles', 'value': _formatNumber(_totalArticles)},
            {'label': 'Published Today', 'value': _formatNumber(_publishedToday)},
            {'label': 'Total Views', 'value': _formatNumber(_totalViews)},
          ],
          icon: Icons.article,
          color: Colors.green,
        ),
        
        const SizedBox(height: 16),
        _buildMetricSection(
          title: 'Revenue',
          metrics: [
            {'label': 'Today', 'value': _formatCurrency(_revenueToday)},
            {'label': 'This Month', 'value': _formatCurrency(_revenueThisMonth)},
            {'label': 'Year to Date', 'value': _formatCurrency(_revenueYTD)},
          ],
          icon: Icons.attach_money,
          color: Colors.amber,
        ),
      ],
    );
  }
  
  Widget _buildMetricSection({
    required String title,
    required List<Map<String, String>> metrics,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: metrics.map((metric) {
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        metric['value']!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metric['label']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Growth (30 Days)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: _buildLineChart(_userGrowthData, Colors.blue),
        ),
        
        const SizedBox(height: 32),
        const Text(
          'Article Views (30 Days)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: _buildLineChart(_viewsData, Colors.green),
        ),
        
        const SizedBox(height: 32),
        const Text(
          'Revenue (30 Days)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: _buildLineChart(_revenueData, Colors.amber),
        ),
      ],
    );
  }
  
  Widget _buildLineChart(List<FlSpot> spots, Color color) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
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
      ),
    );
  }
  
  String _formatNumber(int number) {
    return NumberFormat.compact().format(number);
  }
  
  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(amount);
  }
}
