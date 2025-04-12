import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:neusenews/features/advertising/models/ad.dart';
import 'package:neusenews/features/advertising/models/ad_type.dart';
import 'package:neusenews/features/advertising/models/ad_status.dart';
import 'package:neusenews/features/advertising/repositories/ad_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdService {
  final AdRepository repository;
  final FirebaseAuth auth;

  AdService({required this.repository, required this.auth});

  // Create a new ad
  Future<String> createAd(Ad ad, File imageFile) async {
    try {
      // Create the ad first to get an ID
      final adId = await repository.createAd(ad);

      // Upload the image if provided
      if (imageFile.path.isNotEmpty) {
        await repository.uploadAdImage(adId, imageFile);
      }

      return adId;
    } catch (e) {
      debugPrint('Error creating ad: $e');
      rethrow;
    }
  }

  // Get active ads by type
  Stream<List<Ad>> getActiveAdsByType(AdType type) {
    return repository.getActiveAdsByType(type);
  }

  // Get active ads by type (one-time fetch)
  Future<List<Ad>> getActiveAdsByTypeOnce(AdType type) {
    return repository.getActiveAdsByTypeOnce(type);
  }

  // Record ad impression
  void recordImpression(String adId) {
    try {
      FirebaseFirestore.instance.collection('ads').doc(adId).update({
        'impressions': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint("Error recording impression: $e");
    }
  }

  // Record ad click
  Future<void> recordClick(String adId) async {
    try {
      await FirebaseFirestore.instance.collection('ads').doc(adId).update({
        'clicks': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint("Error recording click: $e");
    }
  }

  // Approve an ad
  Future<void> approveAd(String adId) async {
    try {
      await repository.updateAdStatus(adId, AdStatus.active);
    } catch (e) {
      debugPrint('Error approving ad: $e');
      rethrow;
    }
  }

  // Reject an ad
  Future<void> rejectAd(String adId, String rejectionReason) async {
    try {
      await repository.updateAdStatus(
        adId,
        AdStatus.rejected,
        rejectionReason: rejectionReason,
      );
    } catch (e) {
      debugPrint('Error rejecting ad: $e');
      rethrow;
    }
  }

  // Calculate ad cost based on type and duration
  double calculateAdCost(AdType type, int durationWeeks) {
    switch (type) {
      case AdType.titleSponsor:
        return 249.0 * durationWeeks;
      case AdType.inFeedDashboard:
        return 149.0 * durationWeeks;
      case AdType.inFeedNews:
        return 99.0 * durationWeeks;
      case AdType.weather:
        return 199.0 * durationWeeks;
      case AdType.bannerAd:
        return 129.0 * durationWeeks;
      default:
        return 99.0 * durationWeeks;
    }
  }

  // Delete an ad
  Future<void> deleteAd(String adId) async {
    try {
      await repository.deleteAd(adId);
    } catch (e) {
      debugPrint('Error deleting ad: $e');
      rethrow;
    }
  }

  // Get pending ads for approval
  Future<List<Ad>> getPendingAdsForApproval() async {
    try {
      return await repository.getPendingAds();
    } catch (e) {
      debugPrint('Error getting pending ads: $e');
      return [];
    }
  }

  // Replace ensureDebugAdsExist with a safer implementation
  Future<void> ensureDebugAdsExist() async {
    // In production, we should not create debug ads
    if (!kDebugMode) {
      return;
    }

    try {
      // Check if we have any ads at all before creating debug ones
      final existingAds = await repository.getActiveAdsByTypeOnce(
        AdType.weather,
      );
      if (existingAds.isNotEmpty) {
        debugPrint(
          'Found ${existingAds.length} existing ads - not creating debug ads',
        );
        return;
      }

      // Only create debug ads in debug mode AND when no real ads exist
      debugPrint('No ads found, creating debug ads for testing only');

      // Create minimal debug ads code here...
    } catch (e) {
      debugPrint('Error checking for ads: $e');
    }
  }

  // Ad targeting functionality
  Future<List<Ad>> getPersonalizedAdsForUser(String userId, AdType type) async {
    try {
      // Get user's recent article views/interactions from repository
      final userInterests = await repository.getUserInterests(userId);

      // Get active ads of the specified type
      final ads = await getActiveAdsByTypeOnce(type);

      // Sort ads based on relevance to user interests
      if (userInterests.isNotEmpty) {
        ads.sort((a, b) {
          final aRelevance = _calculateRelevanceScore(a, userInterests);
          final bRelevance = _calculateRelevanceScore(b, userInterests);
          return bRelevance.compareTo(aRelevance); // Higher score first
        });
      }

      return ads;
    } catch (e) {
      debugPrint('Error getting personalized ads: $e');
      // Fallback to regular ads if personalization fails
      return getActiveAdsByTypeOnce(type);
    }
  }

  // Helper method to calculate ad relevance
  double _calculateRelevanceScore(Ad ad, List<String> interests) {
    // Simple relevance calculation - count matching keywords
    double score = 0;

    final adText =
        '${ad.headline} ${ad.description} ${ad.businessName}'.toLowerCase();

    for (final interest in interests) {
      if (adText.contains(interest.toLowerCase())) {
        score += 1.0;
      }
    }

    return score;
  }

  // Ad serving functionality
  Future<Ad?> getNextAdForDisplay(String userId, AdType type) async {
    try {
      // Get active ads of the requested type
      final availableAds = await getActiveAdsByTypeOnce(type);

      if (availableAds.isEmpty) return null;

      // For now, we'll simplify this by just returning a random ad
      // Later you can implement full frequency capping with viewedAds
      return availableAds[DateTime.now().millisecondsSinceEpoch %
          availableAds.length];

      /* Original implementation to restore later:
      // Get recently viewed ads by this user
      final List<AdView> viewedAds = await repository.getRecentlyViewedAdsByUser(userId, type);
      
      // Apply frequency capping - don't show same ad more than 3 times in 24 hours
      final adIdsViewedRecently = viewedAds
          .where((ad) => ad.viewedAt.isAfter(DateTime.now().subtract(const Duration(hours: 24))))
          .fold<Map<String, int>>({}, (map, ad) {
            map[ad.adId] = (map[ad.adId] ?? 0) + 1;
            return map;
          });
      
      // Filter out ads that have been viewed 3+ times in last 24 hours
      final eligibleAds = availableAds.where((ad) {
        final viewCount = adIdsViewedRecently[ad.id] ?? 0;
        return viewCount < 3;
      }).toList();
      */
    } catch (e) {
      debugPrint('Error getting next ad for display: $e');
      return null;
    }
  }
}
