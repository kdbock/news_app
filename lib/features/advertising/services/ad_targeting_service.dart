import '../models/ad.dart';
import '../models/ad_type.dart';
import '../models/ad_status.dart'; // Ensure this file contains the AdStatus enum

class AdTargetingService {
  Future<List<Ad>> getPersonalizedAdsForUser(String userId, AdType type) async {
    final userInterests = await _getUserInterests(userId);
    return _matchAdsToInterests(userInterests, type);
  }

  Future<List<String>> _getUserInterests(String userId) async {
    // Simulate fetching user interests from a database or API
    return ['sports', 'technology', 'local news'];
  }

  Future<List<Ad>> _matchAdsToInterests(List<String> interests, AdType type) async {
    // Simulate fetching ads that match the user's interests and ad type
    return [
      Ad(
        id: '1',
        businessId: 'business1',
        businessName: 'Tech Corp',
        headline: 'Innovative Tech Solutions',
        description: 'Discover the latest in technology.',
        imageUrl: 'https://example.com/tech.jpg',
        linkUrl: 'https://example.com',
        type: type,
        status: AdStatus.active,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        cost: 100.0,
      ),
    ];
  }
}
