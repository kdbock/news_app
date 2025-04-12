import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EnhancedAdAnalyticsScreen extends StatefulWidget {
  final String? adId; // Optional - if provided, shows analytics for specific ad

  const EnhancedAdAnalyticsScreen({super.key, this.adId});

  @override
  State<EnhancedAdAnalyticsScreen> createState() => _EnhancedAdAnalyticsScreenState();
}

class _EnhancedAdAnalyticsScreenState extends State<EnhancedAdAnalyticsScreen> {
  String _selectedTimeRange = 'Last 7 days';
  final List<String> _timeRanges = ['Last 7 days', 'Last 30 days', 'Last 90 days', 'Year to date', 'Custom range'];
  bool _isLoading = true;
  
  // Analytics data
  Map<String, dynamic> _analyticsData = {};
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }
  
  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch analytics data based on selected time range and adId if provided
      // This would call your analytics service
      
      // Simulating API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Sample data structure
      setState(() {
        _analyticsData = {
          'impressions': 12345,
          'clicks': 823,
          'ctr': 6.67,
          'spent': 499.00,
          'costPerClick': 0.61,
          'conversionRate': 3.2,
          'roi': 127.5,
          'dailyImpressions': [
            {'date': DateTime.now().subtract(const Duration(days: 6)), 'value': 1200},
            {'date': DateTime.now().subtract(const Duration(days: 5)), 'value': 1800},
            {'date': DateTime.now().subtract(const Duration(days: 4)), 'value': 1500},
            {'date': DateTime.now().subtract(const Duration(days: 3)), 'value': 2100},
            {'date': DateTime.now().subtract(const Duration(days: 2)), 'value': 1900},
            {'date': DateTime.now().subtract(const Duration(days: 1)), 'value': 2400},
            {'date': DateTime.now(), 'value': 1450},
          ],
          'dailyClicks': [
            {'date': DateTime.now().subtract(const Duration(days: 6)), 'value': 80},
            {'date': DateTime.now().subtract(const Duration(days: 5)), 'value': 120},
            {'date': DateTime.now().subtract(const Duration(days: 4)), 'value': 95},
            {'date': DateTime.now().subtract(const Duration(days: 3)), 'value': 145},
            {'date': DateTime.now().subtract(const Duration(days: 2)), 'value': 132},
            {'date': DateTime.now().subtract(const Duration(days: 1)), 'value': 180},
            {'date': DateTime.now(), 'value': 71},
          ],
          'audience': {
            'age': [
              {'label': '18-24', 'value': 25},
              {'label': '25-34', 'value': 35},
              {'label': '35-44', 'value': 20},
              {'label': '45-54', 'value': 12},
              {'label': '55+', 'value': 8},
            ],
            'gender': [
              {'label': 'Male', 'value': 52},
              {'label': 'Female', 'value': 48},
            ],
            'location': [
              {'label': 'Kinston', 'value': 42},
              {'label': 'Goldsboro', 'value': 18},
              {'label': 'New Bern', 'value': 15},
              {'label': 'Greenville', 'value': 12},
              {'label': 'Other', 'value': 13},
            ],
          },
        };
        _isLoading = false;
      });
    } catch (e) {
      // Handle errors
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.adId != null ? 'Ad Performance' : 'Advertising Analytics'),
        backgroundColor: const Color(0xFFd2982a),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range selector
                  _buildTimeRangeSelector(),
                  
                  const SizedBox(height: 24),
                  
                  // Top metrics cards
                  _buildMetricCards(),
                  
                  const SizedBox(height: 24),
                  
                  // Performance over time chart
                  _buildPerformanceChart(),
                  
                  const SizedBox(height: 24),
                  
                  // Audience demographics
                  _buildAudienceSection(),
                  
                  const SizedBox(height: 24),
                  
                  // ROI analysis
                  _buildRoiSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Range',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTimeRange,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _timeRanges.map((range) {
                return DropdownMenuItem<String>(
                  value: range,
                  child: Text(range),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue == 'Custom range') {
                  _showDateRangePicker();
                  return;
                }
                
                setState(() {
                  _selectedTimeRange = newValue!;
                  _customDateRange = null;
                });
                _loadAnalyticsData();
              },
            ),
            
            if (_customDateRange != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'From: ${DateFormat('MMM d, yyyy').format(_customDateRange!.start)} to ${DateFormat('MMM d, yyyy').format(_customDateRange!.end)}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showDateRangePicker() async {
    final initialDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
    
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange ?? initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFd2982a),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedRange != null) {
      setState(() {
        _customDateRange = pickedRange;
        _selectedTimeRange = 'Custom range';
      });
      _loadAnalyticsData();
    }
  }
  
  Widget _buildMetricCards() {
    final metrics = [
      {'label': 'Impressions', 'value': _formatNumber(_analyticsData['impressions'] ?? 0), 'icon': Icons.visibility},
      {'label': 'Clicks', 'value': _formatNumber(_analyticsData['clicks'] ?? 0), 'icon': Icons.touch_app},
      {'label': 'CTR', 'value': '${(_analyticsData['ctr'] ?? 0).toStringAsFixed(2)}%', 'icon': Icons.percent},
      {'label': 'Spent', 'value': '\$${(_analyticsData['spent'] ?? 0).toStringAsFixed(2)}', 'icon': Icons.attach_money},
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(metric['icon'] as IconData, color: const Color(0xFFd2982a), size: 32),
                const SizedBox(height: 8),
                Text(
                  metric['label'] as String,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  metric['value'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
  
  Widget _buildPerformanceChart() {
    // Implementation for performance chart using fl_chart
    // This would be a more detailed implementation than shown here
    return const Placeholder(
      fallbackHeight: 300,
    );
  }
  
  Widget _buildAudienceSection() {
    // Implementation for audience demographics section
    return const Placeholder(
      fallbackHeight: 400,
    );
  }
  
  Widget _buildRoiSection() {
    // Implementation for ROI analysis section
    return const Placeholder(
      fallbackHeight: 300,
    );
  }
}