import '../repositories/ad_repository.dart';
import '../models/ad.dart'; // Ensure AdStatus is defined in this file or imported
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/ad_status.dart'; // Import AdStatus

class AdLifecycleService {
  final AdRepository _repository;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  AdLifecycleService({
    required AdRepository repository,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _repository = repository,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  // Handle expiring ads
  Future<void> handleExpiringAds() async {
    try {
      final now = DateTime.now();
      final expirationThreshold = now.add(const Duration(days: 3));

      // Find ads that are about to expire
      final snapshot =
          await _firestore
              .collection('ads')
              .where('status', isEqualTo: AdStatus.active.index)
              .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
              .where(
                'endDate',
                isLessThanOrEqualTo: Timestamp.fromDate(expirationThreshold),
              )
              .get();

      for (var doc in snapshot.docs) {
        final ad = Ad.fromFirestore(doc);
        // Schedule notification
        await scheduleRenewalNotification(ad.id!);
            }

      // Mark expired ads
      final expiredSnapshot =
          await _firestore
              .collection('ads')
              .where('status', isEqualTo: AdStatus.active.index)
              .where('endDate', isLessThan: Timestamp.fromDate(now))
              .get();

      for (var doc in expiredSnapshot.docs) {
        await _repository.updateAdStatus(doc.id, AdStatus.expired);
      }
    } catch (e) {
      debugPrint('Error handling expiring ads: $e');
    }
  }

  // Schedule renewal notification
  Future<void> scheduleRenewalNotification(String adId) async {
    try {
      // Use Cloud Functions to send notification
      await _functions.httpsCallable('sendAdRenewalNotification').call({
        'adId': adId,
      });
    } catch (e) {
      debugPrint('Error scheduling renewal notification: $e');
    }
  }

  // Renew ad (extend expiration)
  Future<void> renewAd(String adId, Duration extension) async {
    try {
      final adDoc = await _firestore.collection('ads').doc(adId).get();
      final ad = Ad.fromFirestore(adDoc);

      // Calculate new end date
      final newEndDate = ad.endDate.add(extension);

      // Update the ad
      await _firestore.collection('ads').doc(adId).update({
        'endDate': Timestamp.fromDate(newEndDate),
        'status': AdStatus.active.index,
      });
    } catch (e) {
      debugPrint('Error renewing ad: $e');
      rethrow;
    }
  }
}
