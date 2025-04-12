import 'package:flutter/material.dart';
import 'package:neusenews/features/advertising/widgets/ad_analytics_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
            // Replace all individual widgets with the unified dashboard
            AdAnalyticsDashboard(
              // Get the current user's business ID
              businessId: FirebaseAuth.instance.currentUser?.uid,
              // Show all dashboard components
              showPerformanceChart: true,
              showAudienceBreakdown: true,
              showConversionMetrics: true,
              showRoiCalculator: true,
            ),
          ],
        ),
      ),
    );
  }
}
