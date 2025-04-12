import 'package:flutter/material.dart';
import 'package:neusenews/features/advertising/models/ad.dart';
import 'package:neusenews/features/advertising/services/ad_service.dart';
import 'package:neusenews/features/advertising/models/ad_type.dart';
import 'package:neusenews/features/advertising/models/ad_status.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:neusenews/di/service_locator.dart';
import 'package:neusenews/features/advertising/repositories/ad_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsFeedAdBanner extends StatefulWidget {
  const NewsFeedAdBanner({super.key});

  @override
  State<NewsFeedAdBanner> createState() => _NewsFeedAdBannerState();
}

class _NewsFeedAdBannerState extends State<NewsFeedAdBanner> {
  final AdService _adService = AdService(
    repository: serviceLocator<AdRepository>(),
    auth: serviceLocator<FirebaseAuth>(),
  );

  Ad? _ad;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  // Helper method to convert string status to AdStatus enum
  AdStatus _getStatusFromString(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'active':
        return AdStatus.active;
      case 'pending':
        return AdStatus.pending;
      case 'expired':
        return AdStatus.expired;
      default:
        return AdStatus.active;
    }
  }

  Future<void> _loadAd() async {
    try {
      debugPrint('[NewsFeedAdBanner] Loading ads from Firestore');

      // First try the specific query for type 2 (inFeedNews)
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('ads')
              .where('type', isEqualTo: AdType.inFeedNews.index)
              .limit(5)
              .get();

      debugPrint('[NewsFeedAdBanner] Found ${snapshot.docs.length} type 2 ads');

      // If no ads found with type 2, fall back to any active ad
      if (snapshot.docs.isEmpty) {
        debugPrint(
          '[NewsFeedAdBanner] No type 2 ads found, trying any active ad',
        );

        // Try to get any active ad (check both integer and string status)
        snapshot =
            await FirebaseFirestore.instance
                .collection('ads')
                .where('status', whereIn: [AdStatus.active.index, 'active'])
                .limit(5)
                .get();

        debugPrint(
          '[NewsFeedAdBanner] Found ${snapshot.docs.length} active ads as fallback',
        );
      }

      if (snapshot.docs.isEmpty) {
        // Still no ads found, try one final query without filters
        snapshot =
            await FirebaseFirestore.instance.collection('ads').limit(5).get();

        debugPrint(
          '[NewsFeedAdBanner] Last attempt found ${snapshot.docs.length} total ads',
        );
      }

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        debugPrint('[NewsFeedAdBanner] No ads available in the database');
        return;
      }

      // DEBUG: Print the first document to see its structure
      if (snapshot.docs.isNotEmpty) {
        final firstDoc = snapshot.docs.first;
        final data = firstDoc.data() as Map<String, dynamic>;
        debugPrint(
          '[NewsFeedAdBanner] Sample ad data: type=${data['type']}, id=${firstDoc.id}',
        );
        debugPrint(
          '[NewsFeedAdBanner] Available fields: ${data.keys.toList()}',
        );
      }

      // Pick a random ad from the results
      final randomIndex = Random().nextInt(snapshot.docs.length);
      final doc = snapshot.docs[randomIndex];
      final data = doc.data() as Map<String, dynamic>;

      // Fix the status field handling to support both int and string values
      AdStatus adStatus;
      if (data['status'] is int) {
        adStatus = AdStatus.values[data['status'] as int];
      } else if (data['status'] is String) {
        adStatus = _getStatusFromString(data['status'] as String);
      } else {
        adStatus = AdStatus.active; // Default
      }

      // Extract ad data with flexible field handling
      final Ad ad = Ad(
        id: doc.id,
        headline: data['headline'] ?? '',
        description: data['description'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
        linkUrl: data['linkUrl'] ?? '',
        businessName: data['businessName'] ?? '',
        businessId: data['businessId'] ?? '',
        cost: (data['cost'] ?? 0.0).toDouble(),
        type:
            data['type'] is int
                ? AdType.values[data['type']]
                : AdType.inFeedNews,
        status: adStatus,
        startDate:
            (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        endDate:
            (data['endDate'] as Timestamp?)?.toDate() ??
            DateTime.now().add(const Duration(days: 30)),
      );

      if (mounted) {
        setState(() {
          _ad = ad;
          _isLoading = false;
        });

        // Record impression
        if (ad.id != null) {
          _adService.recordImpression(ad.id!);
          debugPrint(
            '[NewsFeedAdBanner] Successfully loaded ad: ${ad.id} - ${ad.headline}',
          );
        }
      }
    } catch (e, stack) {
      debugPrint('[NewsFeedAdBanner] Error loading ad: $e');
      debugPrint('[NewsFeedAdBanner] Stack trace: $stack');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFd2982a),
            ),
          ),
        ),
      );
    }

    if (_ad == null) {
      debugPrint('[NewsFeedAdBanner] No ad to display');
      return const SizedBox.shrink();
    }

    final ad = _ad!;
    debugPrint(
      '[NewsFeedAdBanner] Building UI for ad: ${ad.id} - ${ad.headline}',
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            try {
              // Record click
              if (ad.id != null) {
                _adService.recordClick(ad.id!);
              }

              // Handle links
              final urlString = ad.linkUrl.trim();
              if (urlString.isEmpty) return;

              if (urlString == 'advertising_options' ||
                  urlString.contains('advertising_options') ||
                  urlString.startsWith('app://')) {
                Navigator.of(context).pushNamed('/advertising-options');
              } else {
                final urlToLaunch =
                    urlString.startsWith('http')
                        ? urlString
                        : 'https://$urlString';

                final Uri url = Uri.parse(urlToLaunch);
                if (!await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                )) {
                  debugPrint('[NewsFeedAdBanner] Could not launch URL: $url');
                }
              }
            } catch (e) {
              debugPrint('[NewsFeedAdBanner] Error handling ad click: $e');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ad header with sponsored tag and business name
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'SPONSORED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      ad.businessName,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Main content area
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ad image (using same dimensions as news card images)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          ad.imageUrl.isNotEmpty &&
                                  !ad.imageUrl.contains('placeholder.com')
                              ? Image.network(
                                ad.imageUrl,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, _) {
                                  debugPrint(
                                    '[NewsFeedAdBanner] Image error: $error',
                                  );
                                  return _buildPlaceholderImage();
                                },
                              )
                              : _buildPlaceholderImage(),
                    ),

                    const SizedBox(width: 12),

                    // Ad text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Headline
                          Text(
                            ad.headline,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2d2c31),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 8),

                          // Description
                          if (ad.description.isNotEmpty)
                            Text(
                              ad.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                          const SizedBox(height: 12),

                          // Learn more button
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFd2982a),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'Learn More',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_center, size: 40, color: const Color(0xFFd2982a)),
          const SizedBox(height: 8),
          Text(
            'Advertisement',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
