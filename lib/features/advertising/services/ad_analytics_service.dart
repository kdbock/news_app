import '../repositories/ad_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ad_status.dart';

class AdAnalyticsService {
  final AdRepository _repository;
  final FirebaseFirestore _firestore;

  AdAnalyticsService({
    required AdRepository repository,
    FirebaseFirestore? firestore,
  }) : _repository = repository,
       _firestore = firestore ?? FirebaseFirestore.instance;

  // Get performance metrics for a business
  Future<Map<String, dynamic>> getBusinessMetrics(String businessId) async {
    try {
      final ads = await _repository.getBusinessAds(businessId);

      int totalImpressions = 0;
      int totalClicks = 0;
      double totalSpent = 0.0;
      int activeAds = 0;
      int pendingAds = 0;

      for (var ad in ads) {
        totalImpressions += ad.impressions;
        totalClicks += ad.clicks;
        totalSpent += ad.cost;

        if (ad.status == AdStatus.active &&
            ad.endDate.isAfter(DateTime.now())) {
          activeAds++;
        }

        if (ad.status == AdStatus.pending) {
          pendingAds++;
        }
      }

      // Calculate overall CTR
      final double overallCTR =
          totalImpressions > 0 ? (totalClicks / totalImpressions) * 100 : 0.0;

      return {
        'totalImpressions': totalImpressions,
        'totalClicks': totalClicks,
        'totalSpent': totalSpent,
        'activeAds': activeAds,
        'pendingAds': pendingAds,
        'overallCTR': overallCTR,
      };
    } catch (e) {
      debugPrint('Error getting business metrics: $e');
      return {
        'totalImpressions': 0,
        'totalClicks': 0,
        'totalSpent': 0.0,
        'activeAds': 0,
        'pendingAds': 0,
        'overallCTR': 0.0,
        'error': e.toString(),
      };
    }
  }

  // Get monthly performance data
  Future<Map<String, Map<int, dynamic>>> getMonthlyPerformanceData(
    String businessId, {
    int months = 6,
  }) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - months + 1, 1);

      // Query the impression logs collection (or use the ads collection)
      final snapshot =
          await _firestore
              .collection('ad_impressions')
              .where('businessId', isEqualTo: businessId)
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .get();

      // Initialize data structures
      final Map<int, int> monthlyImpressions = {};
      final Map<int, int> monthlyClicks = {};

      // For each month in the range, initialize with zero
      for (int i = 0; i < months; i++) {
        final month = now.month - i;
        final adjustedMonth = month <= 0 ? month + 12 : month;
        monthlyImpressions[adjustedMonth] = 0;
        monthlyClicks[adjustedMonth] = 0;
      }

      // Process each impression/click
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final isClick = data['isClick'] == true;

        final month = timestamp.month;

        if (monthlyImpressions.containsKey(month)) {
          if (isClick) {
            monthlyClicks[month] = (monthlyClicks[month] ?? 0) + 1;
          } else {
            monthlyImpressions[month] = (monthlyImpressions[month] ?? 0) + 1;
          }
        }
      }

      return {'impressions': monthlyImpressions, 'clicks': monthlyClicks};
    } catch (e) {
      debugPrint('Error getting monthly performance data: $e');
      return {'impressions': {}, 'clicks': {}};
    }
  }

  // Export data to BigQuery or analytics system
  Future<void> exportDataToBigQuery(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Implement when needed
    throw UnimplementedError('BigQuery export not yet implemented');
  }
}
