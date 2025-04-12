import 'package:flutter/material.dart';
import 'package:neusenews/features/advertising/widgets/ad_performance_chart.dart';
import 'package:neusenews/features/advertising/widgets/audience_breakdown_widget.dart';
import 'package:neusenews/features/advertising/widgets/conversion_metrics_widget.dart';
import 'package:neusenews/features/advertising/widgets/roi_calculator_widget.dart';

class AdAnalyticsScreen extends StatelessWidget {
  const AdAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad Analytics'),
        backgroundColor: const Color(0xFFd2982a),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdPerformanceChart(),
            const SizedBox(height: 24),
            const AudienceBreakdownWidget(),
            const SizedBox(height: 24),
            const ConversionMetricsWidget(),
            const SizedBox(height: 24),
            const RoiCalculatorWidget(),
          ],
        ),
      ),
    );
  }
}
