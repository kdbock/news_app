import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:neusenews/features/advertising/models/ad_view.dart';

import '../models/ad.dart';
import '../models/ad_type.dart';
import '../models/ad_status.dart';

class AdRepositoryException implements Exception {
  final String message;
  final dynamic originalError;

  AdRepositoryException(this.message, [this.originalError]);

  @override
  String toString() =>
      originalError != null ? '$message: $originalError' : message;
}

class AdRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  static const String _collectionPath = 'ads';

  AdRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  // Create a new ad
  Future<String> createAd(Ad ad) async {
    try {
      final docRef = await _firestore
          .collection(_collectionPath)
          .add(ad.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating ad: $e');
      throw AdRepositoryException('Failed to create advertisement', e);
    }
  }

  // Get a single ad by ID
  Future<Ad?> getAd(String adId) async {
    try {
      final docSnapshot =
          await _firestore.collection(_collectionPath).doc(adId).get();
      if (!docSnapshot.exists) return null;
      return Ad.fromFirestore(docSnapshot);
    } catch (e) {
      debugPrint('Error getting ad $adId: $e');
      throw AdRepositoryException('Failed to get advertisement', e);
    }
  }

  // Update an existing ad
  Future<void> updateAd(Ad ad) async {
    if (ad.id == null) {
      throw AdRepositoryException('Cannot update ad without ID');
    }

    try {
      await _firestore
          .collection(_collectionPath)
          .doc(ad.id)
          .update(ad.toFirestore());
    } catch (e) {
      debugPrint('Error updating ad ${ad.id}: $e');
      throw AdRepositoryException('Failed to update advertisement', e);
    }
  }

  // Upload ad image
  Future<String> uploadAdImage(String adId, File imageFile) async {
    try {
      // Generate a unique filename
      final fileExtension = imageFile.path.split('.').last;
      final fileName =
          'ads/${adId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      // Upload file to Firebase Storage
      final storageRef = _storage.ref().child(fileName);
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update the ad document with the image URL
      await _firestore.collection(_collectionPath).doc(adId).update({
        'imageUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image for ad $adId: $e');
      throw AdRepositoryException('Failed to upload advertisement image', e);
    }
  }

  // Optimize the query to prevent Firestore issues
  Stream<List<Ad>> getActiveAdsByType(AdType type) {
    debugPrint('Querying for ads of type: ${type.name} (index: ${type.index})');

    return _firestore
        .collection(_collectionPath)
        .where('type', isEqualTo: type.index)
        .where('status', isEqualTo: AdStatus.active.index)
        .snapshots()
        .map((snapshot) {
          debugPrint('Got ${snapshot.docs.length} ads for type ${type.name}');
          final now = DateTime.now();
          return snapshot.docs
              .map((doc) => Ad.fromFirestore(doc))
              .where(
                (ad) => ad.startDate.isBefore(now) && ad.endDate.isAfter(now),
              )
              .toList();
        })
        .handleError((error) {
          debugPrint('Error in Firestore query: $error');
          return <Ad>[];
        });
  }

  // Simplify the getActiveAdsByTypeOnce query to prevent potential Firestore issues
  Future<List<Ad>> getActiveAdsByTypeOnce(AdType type) async {
    try {
      // Simplified query that doesn't use timestamp comparisons
      final snapshot =
          await _firestore
              .collection(_collectionPath)
              .where('type', isEqualTo: type.index)
              .where('status', isEqualTo: AdStatus.active.index)
              .get();

      debugPrint('Found ${snapshot.docs.length} ads of type ${type.name}');

      final List<Ad> ads = [];
      for (var doc in snapshot.docs) {
        final ad = Ad.fromFirestore(doc);

        // Filter date range in memory instead of in query
        final now = DateTime.now();
        if (ad.startDate.isBefore(now) && ad.endDate.isAfter(now)) {
          ads.add(ad);
        }
      }

      debugPrint('Returning ${ads.length} active ads after date filtering');
      return ads;
    } catch (e) {
      debugPrint('Error fetching ads: $e');
      // Return empty list instead of throwing to prevent crashes
      return [];
    }
  }

  // Record impression
  Future<void> recordImpression(String adId) async {
    try {
      await _firestore.collection(_collectionPath).doc(adId).update({
        'impressions': FieldValue.increment(1),
      });

      // Update CTR
      await _updateCTR(adId);
    } catch (e) {
      debugPrint('Error recording impression: $e');
      // Don't throw here - non-critical operation
    }
  }

  // Record click
  Future<void> recordClick(String adId) async {
    try {
      await _firestore.collection(_collectionPath).doc(adId).update({
        'clicks': FieldValue.increment(1),
      });

      // Update CTR
      await _updateCTR(adId);
    } catch (e) {
      debugPrint('Error recording click: $e');
      // Don't throw here - non-critical operation
    }
  }

  // Update click-through rate
  Future<void> _updateCTR(String adId) async {
    try {
      // Get current impressions and clicks
      final doc = await _firestore.collection(_collectionPath).doc(adId).get();
      final data = doc.data();

      if (data == null) return;

      final int impressions = (data['impressions'] as num?)?.toInt() ?? 0;
      final int clicks = (data['clicks'] as num?)?.toInt() ?? 0;

      // Calculate and update CTR if impressions > 0
      if (impressions > 0) {
        final double ctr = (clicks / impressions) * 100;
        await _firestore.collection(_collectionPath).doc(adId).update({
          'ctr': ctr,
        });
      }
    } catch (e) {
      debugPrint('Error updating CTR: $e');
    }
  }

  // Update ad status
  Future<void> updateAdStatus(
    String adId,
    AdStatus status, {
    String? rejectionReason,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status.index,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (rejectionReason != null && status == AdStatus.rejected) {
        updates['rejectionReason'] = rejectionReason;
      }

      await _firestore.collection(_collectionPath).doc(adId).update(updates);
    } catch (e) {
      debugPrint('Error updating ad status: $e');
      throw AdRepositoryException('Failed to update advertisement status', e);
    }
  }

  // Get ads for approval (pending status)
  Future<List<Ad>> getPendingAds() async {
    try {
      final snapshot =
          await _firestore
              .collection(_collectionPath)
              .where('status', isEqualTo: AdStatus.pending.index)
              .orderBy('startDate', descending: false)
              .get();

      final List<Ad> ads = [];
      for (var doc in snapshot.docs) {
        final Ad ad = Ad.fromFirestore(doc);
        ads.add(ad);
      }
      return ads;
    } catch (e) {
      debugPrint('Error fetching pending ads: $e');
      throw AdRepositoryException('Failed to fetch pending advertisements', e);
    }
  }

  // Delete an ad
  Future<void> deleteAd(String adId) async {
    try {
      await _firestore.collection(_collectionPath).doc(adId).delete();
    } catch (e) {
      debugPrint('Error deleting ad: $e');
      throw AdRepositoryException('Failed to delete advertisement', e);
    }
  }

  // Get ads for a business
  Future<List<Ad>> getBusinessAds(String businessId) async {
    try {
      final snapshot =
          await _firestore
              .collection(_collectionPath)
              .where('businessId', isEqualTo: businessId)
              .orderBy('startDate', descending: true)
              .get();

      final List<Ad> ads = [];
      for (var doc in snapshot.docs) {
        final Ad ad = Ad.fromFirestore(doc);
        ads.add(ad);
      }
      return ads;
    } catch (e) {
      debugPrint('Error fetching business ads: $e');
      throw AdRepositoryException('Failed to fetch business advertisements', e);
    }
  }

  // Replace the addDebugAdsIfEmpty method with this optimized version:

  Future<void> addDebugAdsIfEmpty() async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 1));
      final endDate = now.add(const Duration(days: 30));

      // First check if we already have active ads of each type
      final weatherAdsCount = await _firestore
          .collection(_collectionPath)
          .where('type', isEqualTo: AdType.weather.index)
          .where('status', isEqualTo: AdStatus.active.index)
          .count()
          .get()
          .then((snapshot) => snapshot.count);

      if (weatherAdsCount == 0) {
        // Use a local image path instead of remote URL to avoid network issues
        await _firestore.collection(_collectionPath).add({
          'businessId': 'debug-business',
          'businessName': 'Weather Sponsor',
          'headline': 'Local Weather Brought To You By Us',
          'description': 'Click here to learn about our services',
          'linkUrl': 'https://example.com',
          'type': AdType.weather.index,
          'status': AdStatus.active.index,
          'startDate': Timestamp.fromDate(startDate),
          'endDate': Timestamp.fromDate(endDate),
          'imageUrl': 'assets/images/weather/Default.jpeg',
          'cost': 199.0,
          'impressions': 0,
          'clicks': 0,
          'ctr': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('Debug weather ad created');
      }

      // Similarly create other ad types only if needed
      // This approach avoids creating duplicate ads on every app restart
    } catch (e) {
      debugPrint('Error creating debug ads: $e');
    }
  }

  // Methods to add to your AdRepository class:

  Future<List<String>> getUserInterests(String userId) async {
    // In a real implementation, you would query a user's interests
    // For now, return some default interests
    return ['local news', 'sports', 'community'];
  }

  Future<List<AdView>> fetchRecentlyViewedAdsByUser(
    String userId,
    AdType type,
  ) async {
    // This would fetch from Firestore or another database
    // For now, return an empty list
    return [];
  }

  Future<List<AdView>> getRecentlyViewedAdsByUser(
    String userId,
    AdType type,
  ) async {
    try {
      // In a real implementation, you would query Firestore
      // For now, return empty list since we don't have actual view tracking yet
      return [];

      /* 
      // Real implementation would look like this:
      final snapshot = await FirebaseFirestore.instance
          .collection('adViews')
          .where('userId', isEqualTo: userId)
          .where('adType', isEqualTo: type.index)
          .orderBy('viewedAt', descending: true)
          .limit(100)
          .get();
      
      return snapshot.docs.map((doc) => AdView.fromFirestore(doc.data())).toList();
      */
    } catch (e) {
      debugPrint('Error fetching ad views: $e');
      return [];
    }
  }
}
