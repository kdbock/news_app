import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:neusenews/models/ad.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' as flutter;

class AdService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add this static map as a class property instead of inside the function
  static final Map<AdType, int> _lastAdCounts = {};

  // Create a new ad
  Future<String> createAd(Ad ad) async {
    try {
      // Check authentication
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Make sure businessId matches current user
      final adData = ad.toFirestore();
      if (ad.businessId != user.uid) {
        throw Exception('Ad business ID does not match authenticated user');
      }

      // Save to Firestore
      DocumentReference docRef = await _firestore.collection('ads').add(adData);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create ad: $e');
    }
  }

  // Get all ads for a business
  Stream<List<Ad>> getBusinessAds(String businessId) {
    return _firestore
        .collection('ads')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Ad.fromFirestore(doc)).toList(),
        );
  }

  // Get all active ads
  Stream<List<Ad>> getActiveAds() {
    return _firestore
        .collection('ads')
        .where(
          'status',
          isEqualTo: 'active',
        ) // Use string instead of enum index
        .where('endDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Ad.fromFirestore(doc)).toList(),
        );
  }

  // Update method to be more efficient
  Stream<List<Ad>> getActiveAdsByType(AdType type) {
    final now = DateTime.now();
    final typeIndex = type.index;

    // Only query once and cache result
    return FirebaseFirestore.instance
        .collection('ads')
        .where('type', isEqualTo: typeIndex)
        .snapshots()
        .map((snapshot) {
          final List<Ad> allAds = [];

          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();

              // Handle dates safely
              final Timestamp? startTimestamp = data['startDate'] as Timestamp?;
              final Timestamp? endTimestamp = data['endDate'] as Timestamp?;

              final startDate =
                  startTimestamp?.toDate() ??
                  DateTime.now().subtract(const Duration(days: 1));
              final endDate =
                  endTimestamp?.toDate() ??
                  DateTime.now().add(const Duration(days: 30));

              // Check if ad is within date range
              final bool isInDateRange =
                  startDate.isBefore(now) && endDate.isAfter(now);

              if (isInDateRange) {
                try {
                  final ad = Ad.fromFirestore(doc);
                  allAds.add(ad);
                } catch (e) {
                  // Silent error handling - don't flood console
                }
              }
            } catch (e) {
              // Silent error handling - don't flood console
            }
          }

          return allAds;
        })
        .asBroadcastStream(); // Important: make it reusable by multiple subscribers
  }

  // Record an impression
  Future<void> recordImpression(String adId) async {
    try {
      await _firestore.collection('ads').doc(adId).update({
        'impressions': FieldValue.increment(1),
      });

      // Also update CTR
      DocumentSnapshot doc = await _firestore.collection('ads').doc(adId).get();
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      int impressions = data['impressions'] ?? 0;
      int clicks = data['clicks'] ?? 0;

      if (impressions > 0) {
        double ctr = clicks / impressions * 100;
        await _firestore.collection('ads').doc(adId).update({'ctr': ctr});
      }
    } catch (e) {
      flutter.debugPrint("Error recording impression: $e");
    }
  }

  // Record a click
  Future<void> recordClick(String adId) async {
    try {
      await _firestore.collection('ads').doc(adId).update({
        'clicks': FieldValue.increment(1),
      });

      // Also update CTR
      DocumentSnapshot doc = await _firestore.collection('ads').doc(adId).get();
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      int impressions = data['impressions'] ?? 0;
      int clicks = data['clicks'] ?? 0;

      if (impressions > 0) {
        double ctr = clicks / impressions * 100;
        await _firestore.collection('ads').doc(adId).update({'ctr': ctr});
      }
    } catch (e) {
      flutter.debugPrint("Error recording click: $e");
    }
  }

  // Get ad analytics
  Future<Map<String, dynamic>> getAdAnalytics() async {
    QuerySnapshot snapshot = await _firestore.collection('ads').get();

    int totalImpressions = 0;
    int totalClicks = 0;
    double totalRevenue = 0.0;
    int activeAds = 0;

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      totalImpressions += (data['impressions'] as num?)?.toInt() ?? 0;
      totalClicks += (data['clicks'] as num?)?.toInt() ?? 0;
      totalRevenue += data['cost']?.toDouble() ?? 0.0;

      if (data['status'] == 'active') {
        activeAds++;
      }
    }

    double overallCTR =
        totalImpressions > 0 ? totalClicks / totalImpressions * 100 : 0.0;

    return {
      'totalImpressions': totalImpressions,
      'totalClicks': totalClicks,
      'overallCTR': overallCTR,
      'totalRevenue': totalRevenue,
      'activeAds': activeAds,
    };
  }

  // Upload ad image
  Future<String> uploadAdImage(String adId, File imageFile) async {
    try {
      final ref = _storage.ref().child(
        'ads/$adId/${DateTime.now().millisecondsSinceEpoch}',
      );
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update the ad with the image URL
      await _firestore.collection('ads').doc(adId).update({
        'imageUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Get advertiser analytics
  Future<Map<String, dynamic>> getAdvertiserAnalytics(String businessId) async {
    try {
      // Get the user's ads
      final QuerySnapshot snapshot =
          await _firestore
              .collection('ads')
              .where('businessId', isEqualTo: businessId)
              .get();

      // Process ads and metrics
      List<Ad> activeAds = [];
      List<Ad> pastAds = [];
      int totalImpressions = 0;
      int totalClicks = 0;
      double totalSpend = 0.0;

      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final ad = Ad.fromFirestore(doc);

        // Add to respective lists
        if (ad.status == 'active' && ad.endDate.isAfter(now)) {
          activeAds.add(ad);
        } else if (ad.status == 'expired' || ad.endDate.isBefore(now)) {
          pastAds.add(ad);
        }

        // Calculate metrics
        totalImpressions += ad.impressions;
        totalClicks += ad.clicks;
        totalSpend += ad.cost;
      }

      // Calculate average CTR
      double averageCtr =
          totalImpressions > 0 ? (totalClicks / totalImpressions) * 100 : 0.0;

      // Sort ads by start date (newest first)
      activeAds.sort((a, b) => b.startDate.compareTo(a.startDate));
      pastAds.sort((a, b) => b.startDate.compareTo(a.startDate));

      return {
        'activeAds': activeAds,
        'pastAds': pastAds,
        'metrics': {
          'totalImpressions': totalImpressions,
          'totalClicks': totalClicks,
          'averageCtr': averageCtr,
          'totalSpend': totalSpend,
        },
      };
    } catch (e) {
      throw Exception('Failed to get advertiser analytics: $e');
    }
  }

  // Cancel an ad
  Future<void> cancelAd(String adId) async {
    try {
      await _firestore.collection('ads').doc(adId).update({
        'status': 'expired',
      });
    } catch (e) {
      throw Exception('Failed to cancel ad: $e');
    }
  }

  Future<void> debugAdsByType() async {
    // Check each ad type
    for (AdType type in AdType.values) {
      final snapshot =
          await _firestore
              .collection('ads')
              .where('type', isEqualTo: type.index)
              .get();

      flutter.debugPrint(
        'Found ${snapshot.docs.length} ads with type ${type.index} (${_getAdTypeName(type)})',
      );

      // For each ad, check if it's active
      int activeCount = 0;
      for (var doc in snapshot.docs) {
        final ad = Ad.fromFirestore(doc);
        final now = DateTime.now();
        if (ad.status == 'active' &&
            ad.startDate.isBefore(now) &&
            ad.endDate.isAfter(now)) {
          activeCount++;
          flutter.debugPrint(' - Active ad: ${ad.headline} (${ad.id})');
        } else {
          flutter.debugPrint(
            ' - Inactive ad: ${ad.headline} (${ad.id}) - Status: ${ad.status}, '
            'Start: ${ad.startDate}, End: ${ad.endDate}',
          );
        }
      }

      flutter.debugPrint(
        ' => $activeCount active ads for ${_getAdTypeName(type)}',
      );
    }
  }

  String _getAdTypeName(AdType type) {
    switch (type) {
      case AdType.titleSponsor:
        return 'Title Sponsor';
      case AdType.inFeedDashboard:
        return 'In-Feed Dashboard';
      case AdType.inFeedNews:
        return 'In-Feed News';
      case AdType.weather:
        return 'Weather Sponsor';
    }
  }

  // Sanitize input URLs to prevent security vulnerabilities
  String sanitizeUrl(String url) {
    // Ensure URL starts with http:// or https://
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://$url';
    }
    return url;
  }

  // Validate image URL before displaying
  Future<bool> isValidImageUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!uri.isAbsolute) return false;

      // Optional: You could add additional checks here
      // For example, checking if the URL is from a trusted domain

      return true;
    } catch (e) {
      flutter.debugPrint('Invalid image URL: $e');
      return false;
    }
  }

  // Add secure impression tracking with rate limiting
  final Map<String, DateTime> _lastImpressionTime = {};

  Future<void> recordImpressionSecurely(String adId) async {
    try {
      // Rate limit impressions from the same device to prevent abuse
      final now = DateTime.now();
      if (_lastImpressionTime.containsKey(adId)) {
        final lastTime = _lastImpressionTime[adId]!;
        if (now.difference(lastTime).inMinutes < 5) {
          // Don't count impressions from the same device within 5 minutes
          return;
        }
      }

      _lastImpressionTime[adId] = now;

      await FirebaseFirestore.instance.collection('ads').doc(adId).update({
        'impressions': FieldValue.increment(1),
        'lastImpressionAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      flutter.debugPrint('Error recording impression: $e');
    }
  }
}
