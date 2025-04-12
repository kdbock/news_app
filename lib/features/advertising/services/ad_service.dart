import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:neusenews/features/advertising/models/ad.dart';
import 'package:neusenews/features/advertising/models/ad_type.dart';
import 'package:neusenews/features/advertising/models/ad_status.dart';
import 'package:neusenews/features/advertising/repositories/ad_repository.dart';

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
  Future<void> recordImpression(String adId) async {
    try {
      await repository.recordImpression(adId);
    } catch (e) {
      debugPrint('Error recording impression: $e');
    }
  }

  // Record ad click
  Future<void> recordClick(String adId) async {
    try {
      await repository.recordClick(adId);
    } catch (e) {
      debugPrint('Error recording click: $e');
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
}
