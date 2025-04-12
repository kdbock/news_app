import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neusenews/features/advertising/services/ad_service.dart';
import 'package:neusenews/di/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdAnalyticsDashboard extends StatefulWidget {
  final String? businessId;
  final bool showRoiCalculator;
  final bool showPerformanceChart;
  final bool showAudienceBreakdown;
  final bool showConversionMetrics;

  const AdAnalyticsDashboard({
    super.key,
    this.businessId,
    this.showRoiCalculator = true,
    this.showPerformanceChart = true,
    this.showAudienceBreakdown = true,
    this.showConversionMetrics = true,
  });

  @override
  State<AdAnalyticsDashboard> createState() => _AdAnalyticsDashboardState();
}

class _AdAnalyticsDashboardState extends State<AdAnalyticsDashboard> {
  final AdService _adService = serviceLocator<AdService>();
  bool _isLoading = true;

  // Analytics data
  int _totalImpressions = 0;
  int _totalClicks = 0;
  double _averageCTR = 0;
  int _conversions = 0;
  double _conversionRate = 0;

  // ROI Calculator
  final _adSpendController = TextEditingController(text: '500');
  final _conversionRateController = TextEditingController(text: '5');
  final _averageOrderValueController = TextEditingController(text: '75');
  double _roi = 0.0;
  double _totalRevenue = 0.0;

  // Chart data
  List<FlSpot> _impressionData = [];
  List<FlSpot> _clickData = [];
  Map<String, double> _audienceData = {};

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
    _calculateRoi();
  }

  @override
  void dispose() {
    _adSpendController.dispose();
    _conversionRateController.dispose();
    _averageOrderValueController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      // Use businessId or current user's ID
      final String businessId =
          widget.businessId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

      if (businessId.isEmpty) {
        throw Exception('No business ID available');
      }

      // Get ad data from repository
      final QuerySnapshot adSnapshot =
          await FirebaseFirestore.instance
              .collection('ads')
              .where('businessId', isEqualTo: businessId)
              .get();

      // Calculate metrics
      int impressions = 0;
      int clicks = 0;
      final Map<int, int> monthlyImpressions = {};
      final Map<int, int> monthlyClicks = {};
      final Map<String, int> audienceCounts = {
        '18-24': 0,
        '25-34': 0,
        '35-44': 0,
        '45+': 0,
      };

      // Initialize monthly data for past 6 months
      final now = DateTime.now();
      for (int i = 5; i >= 0; i--) {
        final month = now.month - i > 0 ? now.month - i : now.month - i + 12;
        monthlyImpressions[month] = 0;
        monthlyClicks[month] = 0;
      }

      // Process all ads
      for (final doc in adSnapshot.docs) {
        final ad = doc.data() as Map<String, dynamic>;

        // Accumulate metrics
        final adImpressions = ad['impressions'] as int? ?? 0;
        final adClicks = ad['clicks'] as int? ?? 0;

        impressions += adImpressions;
        clicks += adClicks;

        // Monthly data
        final startDate = (ad['startDate'] as Timestamp?)?.toDate() ?? now;
        if (startDate.isAfter(DateTime(now.year, now.month - 6))) {
          final month = startDate.month;
          monthlyImpressions[month] =
              (monthlyImpressions[month] ?? 0) + adImpressions;
          monthlyClicks[month] = (monthlyClicks[month] ?? 0) + adClicks;
        }

        // Audience data - in real implementation, this would come from analytics
        // This is a placeholder that distributes audience based on ad ID to simulate real data
        final adId = doc.id;
        if (adId.isNotEmpty) {
          final hash = adId.codeUnits.fold<int>(
            0,
            (accumulator, code) => accumulator + code,
          );
          audienceCounts['18-24'] = audienceCounts['18-24']! + (hash % 10);
          audienceCounts['25-34'] =
              audienceCounts['25-34']! + ((hash ~/ 10) % 10);
          audienceCounts['35-44'] =
              audienceCounts['35-44']! + ((hash ~/ 100) % 10);
          audienceCounts['45+'] =
              audienceCounts['45+']! + ((hash ~/ 1000) % 10);
        }
      }

      // Calculate derived metrics
      final ctr = impressions > 0 ? (clicks / impressions) * 100 : 0;

      // Estimate conversions based on clicks and industry average
      final conversions = (clicks * 0.05).round(); // 5% conversion rate
      final conversionRate = clicks > 0 ? (conversions / clicks) * 100 : 0;

      // Create chart data
      final List<FlSpot> impressionsData = [];
      final List<FlSpot> clicksData = [];

      monthlyImpressions.forEach((month, value) {
        impressionsData.add(FlSpot(month.toDouble(), value.toDouble()));
      });

      monthlyClicks.forEach((month, value) {
        clicksData.add(FlSpot(month.toDouble(), value.toDouble()));
      });

      // Sort data by month
      impressionsData.sort((a, b) => a.x.compareTo(b.x));
      clicksData.sort((a, b) => a.x.compareTo(b.x));

      // Convert audience count to percentages
      final totalAudience = audienceCounts.values.fold<int>(
        0,
        (accumulator, countValue) => accumulator + countValue,
      );
      final Map<String, double> audiencePercentages = {};

      if (totalAudience > 0) {
        audienceCounts.forEach((key, value) {
          audiencePercentages[key] = (value / totalAudience) * 100;
        });
      } else {
        // Default distribution if no data
        audiencePercentages['18-24'] = 25;
        audiencePercentages['25-34'] = 35;
        audiencePercentages['35-44'] = 25;
        audiencePercentages['45+'] = 15;
      }

      // Update state
      setState(() {
        _totalImpressions = impressions;
        _totalClicks = clicks;
        _averageCTR = ctr.toDouble();
        _conversions = conversions;
        _conversionRate = conversionRate.toDouble();
        _impressionData = impressionsData;
        _clickData = clicksData;
        _audienceData = audiencePercentages;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading analytics data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateRoi() {
    final adSpend = double.tryParse(_adSpendController.text) ?? 0;
    final conversionRate = double.tryParse(_conversionRateController.text) ?? 0;
    final averageOrderValue =
        double.tryParse(_averageOrderValueController.text) ?? 0;

    // Calculate metrics based on actual clicks
    final expectedConversions = (_totalClicks * conversionRate / 100);
    final totalRevenue = expectedConversions * averageOrderValue;
    final roi = adSpend > 0 ? ((totalRevenue - adSpend) / adSpend) * 100 : 0;

    setState(() {
      _totalRevenue = totalRevenue.toDouble();
      _roi = roi.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (widget.showConversionMetrics) _buildConversionMetrics(),

        const SizedBox(height: 16),

        if (widget.showPerformanceChart) _buildPerformanceChart(),

        const SizedBox(height: 16),

        if (widget.showAudienceBreakdown) _buildAudienceBreakdown(),

        const SizedBox(height: 16),

        if (widget.showRoiCalculator) _buildRoiCalculator(),
      ],
    );
  }

  Widget _buildConversionMetrics() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conversion Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              childAspectRatio: 2,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMetricCard(
                  'Total Impressions',
                  _totalImpressions.toString(),
                ),
                _buildMetricCard('Total Clicks', _totalClicks.toString()),
                _buildMetricCard(
                  'Average CTR',
                  '${_averageCTR.toStringAsFixed(1)}%',
                ),
                _buildMetricCard('Conversions', _conversions.toString()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Conversion Rate',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_conversionRate.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ad Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      spots: _impressionData,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.lightBlue],
                      ),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: _clickData,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [Colors.red, Colors.orange],
                      ),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChartLegend(Colors.blue, 'Impressions'),
                const SizedBox(width: 24),
                _buildChartLegend(Colors.red, 'Clicks'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudienceBreakdown() {
    final List<PieChartSectionData> sections = [];
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
    int i = 0;

    _audienceData.forEach((key, value) {
      sections.add(
        PieChartSectionData(
          value: value,
          title: '${value.round()}%',
          color: colors[i % colors.length],
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      i++;
    });

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Audience Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.5,
              child: PieChart(PieChartData(sections: sections)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('18-24', Colors.blue),
                _buildLegendItem('25-34', Colors.green),
                _buildLegendItem('35-44', Colors.orange),
                _buildLegendItem('45+', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoiCalculator() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ROI Calculator',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _adSpendController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ad Spend (\$)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) => _calculateRoi(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _conversionRateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Conv. Rate (%)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) => _calculateRoi(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _averageOrderValueController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Avg Order (\$)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) => _calculateRoi(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFd2982a).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFd2982a)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Revenue:'),
                      Text(
                        '\$${_totalRevenue.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Return on Investment:'),
                      Text(
                        '${_roi.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFd2982a),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
