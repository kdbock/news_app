import '../services/ad_service.dart';
import '../models/ad_type.dart';
import 'package:flutter/material.dart';
import '../../../di/service_locator.dart';

class AdSystemTest {
  static Future<bool> runQuickTest(BuildContext context) async {
    try {
      final adService = serviceLocator<AdService>();
      
      // 1. Get active ads
      final titleSponsorAds = await adService.getActiveAdsByTypeOnce(AdType.titleSponsor);
      debugPrint('Found ${titleSponsorAds.length} active title sponsor ads');
      
      // 2. Get pending ads
      final pendingAds = await adService.getPendingAdsForApproval();
      debugPrint('Found ${pendingAds.length} pending ads');
      
      // 3. Test cost calculation
      final cost = adService.calculateAdCost(AdType.inFeedNews, 4);
      debugPrint('4-week in-feed news ad cost: \$$cost');
      
      return true;
    } catch (e) {
      debugPrint('Ad system test failed: $e');
      return false;
    }
  }
}