import 'package:flutter/material.dart';
import 'package:neusenews/features/advertising/models/ad.dart';
import 'package:neusenews/features/advertising/services/ad_service.dart';
import 'package:neusenews/features/advertising/models/ad_type.dart';
import 'package:neusenews/features/advertising/models/ad_status.dart'; // Import AdStatus
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:neusenews/di/service_locator.dart';
import 'package:neusenews/features/advertising/repositories/ad_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InFeedAdBanner extends StatefulWidget {
  final AdType adType;

  const InFeedAdBanner({super.key, required this.adType});

  @override
  State<InFeedAdBanner> createState() => _InFeedAdBannerState();
}

class _InFeedAdBannerState extends State<InFeedAdBanner> {
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

  Future<void> _loadAd() async {
    try {
      debugPrint(
        '[InFeedAdBanner] Loading ads from Firestore for type: ${widget.adType}',
      );
      debugPrint('[InFeedAdBanner] Type index: ${widget.adType.index}');
      debugPrint(
        '[InFeedAdBanner] Loading ${widget.adType.displayName} (index: ${widget.adType.index})',
      );

      // Query Firestore directly for more control
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('ads')
              .where('type', isEqualTo: widget.adType.index)
              .limit(5)
              .get();

      debugPrint('[InFeedAdBanner] Found ${snapshot.docs.length} matching ads');

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // For debugging, examine the first document
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        debugPrint('[InFeedAdBanner] First ad data: ${data.keys.toList()}');
        debugPrint(
          '[InFeedAdBanner] Type field: ${data['type']} (${data['type'].runtimeType})',
        );
      }

      // Pick a random ad from the results
      final randomIndex = Random().nextInt(snapshot.docs.length);
      final doc = snapshot.docs[randomIndex];
      final data = doc.data() as Map<String, dynamic>;

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
        type: AdType.values[data['type'] ?? 0],
        status: AdStatus.values[data['status'] ?? 0],
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
          debugPrint('[InFeedAdBanner] Recorded impression for ad: ${ad.id}');
        }
      }
    } catch (e, stack) {
      debugPrint('[InFeedAdBanner] Error loading ad: $e');
      debugPrint('[InFeedAdBanner] Stack trace: $stack');
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
      return const SizedBox(height: 100);
    }

    if (_ad == null) {
      debugPrint('[InFeedAdBanner] No ad to display');
      return const SizedBox.shrink(); // No ad to show
    }

    final ad = _ad!;
    debugPrint(
      '[InFeedAdBanner] Building UI for ad: ${ad.id} - ${ad.headline}',
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () async {
            try {
              // Record click
              if (ad.id != null) {
                _adService.recordClick(ad.id!);
              }

              // Check if internal or external link
              final urlString = ad.linkUrl.trim();
              if (urlString.isEmpty) return;

              if (urlString == 'advertising_options' ||
                  urlString.contains('advertising_options') ||
                  urlString.startsWith('app://')) {
                debugPrint(
                  '[InFeedAdBanner] Navigating to advertising options page',
                );

                // Use named route navigation instead of direct class instantiation
                Navigator.of(context).pushNamed('/advertising-options');

                // If the above route doesn't exist, use this fallback approach
                // Navigator.of(context).pushNamed('/advertise');
              } else {
                // Handle external link
                final urlToLaunch =
                    urlString.startsWith('http')
                        ? urlString
                        : 'https://$urlString';

                final Uri url = Uri.parse(urlToLaunch);
                if (!await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                )) {
                  debugPrint('Could not launch URL: $url');
                }
              }
            } catch (e) {
              debugPrint('Error handling ad click: $e');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ad sponsor label
                Row(
                  children: [
                    const Text(
                      'SPONSORED',
                      style: TextStyle(
                        fontSize: 10.0,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      ad.businessName,
                      style: const TextStyle(
                        fontSize: 10.0,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Ad main content
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ad image
                    if (ad.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: Image.network(
                          ad.imageUrl,
                          width: 120,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, _) {
                            debugPrint('[InFeedAdBanner] Image error: $error');
                            return Container(
                              width: 120,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),

                    // Spacing
                    const SizedBox(width: 12),

                    // Ad headline and description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ad.headline,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (ad.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              ad.description,
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
