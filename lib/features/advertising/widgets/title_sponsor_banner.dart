import 'package:flutter/material.dart';
import 'package:neusenews/features/advertising/models/ad.dart';
import 'package:neusenews/features/advertising/models/ad_type.dart';
import 'package:neusenews/features/advertising/models/ad_status.dart';
import 'package:neusenews/features/advertising/services/ad_service.dart';
// Added import
import 'package:neusenews/di/service_locator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TitleSponsorBanner extends StatefulWidget {
  const TitleSponsorBanner({super.key});

  @override
  State<TitleSponsorBanner> createState() => _TitleSponsorBannerState();
}

class _TitleSponsorBannerState extends State<TitleSponsorBanner> {
  List<Ad>? _sponsorAds;
  bool _isLoading = true;
  late final AdService _adService;

  @override
  void initState() {
    super.initState();
    // Fix: Simplify the initialization to avoid syntax errors
    _adService = serviceLocator<AdService>();
    _loadAds();
  }

  Future<void> _loadAds() async {
    try {
      debugPrint('[TitleSponsorBanner] Loading ads from Firestore');

      // Try a more flexible query - only filter by type
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('ads')
              .where('type', isEqualTo: AdType.titleSponsor.index)
              .limit(3)
              .get();

      debugPrint(
        '[TitleSponsorBanner] Found ${snapshot.docs.length} ads in Firestore',
      );

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _sponsorAds = [];
          });
          debugPrint('[TitleSponsorBanner] No ads found in query results');
        }
        return;
      }

      // Add debug output to see exact field structures
      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      debugPrint(
        '[TitleSponsorBanner] Ad data structure: ${data.keys.toList()}',
      );
      debugPrint(
        '[TitleSponsorBanner] Type field: ${data['type']} (${data['type'].runtimeType})',
      );
      debugPrint(
        '[TitleSponsorBanner] Status field: ${data['status']} (${data['status'].runtimeType})',
      );

      // Convert to Ad objects with more flexible field handling
      final List<Ad> ads =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            debugPrint(
              '[TitleSponsorBanner] Processing ad: ${doc.id} - ${data['headline']}',
            );

            // Handle type field more flexibly
            AdType adType;
            if (data.containsKey('type')) {
              final typeValue = data['type'];
              if (typeValue is int &&
                  typeValue >= 0 &&
                  typeValue < AdType.values.length) {
                adType = AdType.values[typeValue];
              } else {
                adType = AdType.titleSponsor; // Default
              }
            } else if (data.containsKey('adType')) {
              final typeValue = data['adType'];
              if (typeValue is int &&
                  typeValue >= 0 &&
                  typeValue < AdType.values.length) {
                adType = AdType.values[typeValue];
              } else {
                adType = AdType.titleSponsor; // Default
              }
            } else {
              adType = AdType.titleSponsor; // Default
            }

            // Handle status field more flexibly
            AdStatus adStatus;
            if (data.containsKey('status')) {
              final statusValue = data['status'];
              if (statusValue is int &&
                  statusValue >= 0 &&
                  statusValue < AdStatus.values.length) {
                adStatus = AdStatus.values[statusValue];
              } else if (statusValue is String) {
                adStatus = _getStatusFromString(statusValue);
              } else {
                adStatus = AdStatus.active; // Default
              }
            } else {
              adStatus = AdStatus.active; // Default
            }

            return Ad(
              id: doc.id,
              headline: data['headline'] ?? '',
              description: data['description'] ?? '',
              imageUrl: data['imageUrl'] ?? '',
              linkUrl: data['linkUrl'] ?? '',
              businessName: data['businessName'] ?? '',
              businessId: data['businessId'] ?? '',
              cost: (data['cost'] ?? 0.0).toDouble(),
              type: adType,
              status: adStatus,
              startDate:
                  (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              endDate:
                  (data['endDate'] as Timestamp?)?.toDate() ??
                  DateTime.now().add(const Duration(days: 30)),
            );
          }).toList();

      if (mounted) {
        debugPrint('[TitleSponsorBanner] Setting state with ${ads.length} ads');
        setState(() {
          _sponsorAds = ads;
          _isLoading = false;
        });

        // Record impressions
        for (final ad in ads) {
          debugPrint(
            '[TitleSponsorBanner] Recording impression for ad: ${ad.id}',
          );
          if (ad.id != null) {
            _adService.recordImpression(ad.id!);
          }
        }
      }
    } catch (e, stackTrace) {
      // Add stack trace to see exactly where the error occurs
      debugPrint('[TitleSponsorBanner] Error loading title sponsor ads: $e');
      debugPrint('[TitleSponsorBanner] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  AdStatus _getStatusFromString(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'active':
        return AdStatus.active;
      case 'pending':
        return AdStatus.pending;
      case 'expired':
        return AdStatus.expired;
      // Remove the completed and draft cases which don't exist in your AdStatus enum
      default:
        return AdStatus.active; // Default fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'Building TitleSponsorBanner UI, loading: $_isLoading, has ads: ${_sponsorAds?.isNotEmpty}',
    );

    if (_isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Return empty container if no ads
    if (_sponsorAds == null || _sponsorAds!.isEmpty) {
      debugPrint('No sponsor ads to display');
      return const SizedBox.shrink();
    }

    // Get first ad to display
    final ad = _sponsorAds!.first;
    debugPrint(
      'Displaying ad: ${ad.id} - ${ad.headline} - Link: ${ad.linkUrl}',
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        // Replace GestureDetector with InkWell for better visual feedback
        onTap: () async {
          try {
            debugPrint('Ad clicked - attempting to handle URL: ${ad.linkUrl}');

            // Record click
            if (ad.id != null) {
              _adService.recordClick(ad.id!);
            }

            // Check if this is an internal or external link
            final urlString = ad.linkUrl.trim();
            if (urlString.isEmpty) {
              debugPrint('Error: Ad link URL is empty');
              return;
            }

            // Handle internal navigation link
            if (urlString == 'advertising_options' ||
                urlString.contains('advertising_options') ||
                urlString.startsWith('app://')) {
              debugPrint('Navigating to internal screen: advertising_options');

              // Try correct route name variations
              try {
                // Option 1: Try with correct case
                Navigator.of(context).pushNamed('/advertising-options');
              } catch (e) {
                debugPrint('Failed first navigation attempt: $e');
                try {
                  // Option 2: Try with fallback route
                  Navigator.of(context).pushNamed('/advertise');
                } catch (e2) {
                  // Final fallback - find the most likely advertising related screen
                  final routes = [
                    '/ad_options',
                    '/advertising',
                    '/advertise-with-us',
                    '/advertisers',
                  ];

                  for (final route in routes) {
                    try {
                      Navigator.of(context).pushNamed(route);
                      return; // If navigation succeeds, exit the function
                    } catch (_) {
                      // Try next route
                      continue;
                    }
                  }

                  // If all attempts fail, show a snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not find advertising options screen. Please check the app menu.',
                      ),
                    ),
                  );
                }
              }
              return;
            }

            // Handle external URL (existing code)
            final urlToLaunch =
                urlString.startsWith('http') ? urlString : 'https://$urlString';

            final Uri url = Uri.parse(urlToLaunch);
            debugPrint('Launching external URL: $url');

            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
              debugPrint('Could not launch URL: $url');
            }
          } catch (e) {
            debugPrint('Error handling ad click: $e');
          }
        },
        child: Card(
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sponsored label - keep as is
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 2.0,
                ),
                color: Colors.grey[200],
                child: Row(
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
              ),

              // Main ad content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start, // Align to top
                children: [
                  // Image - keep as is
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image.network(
                        ad.imageUrl,
                        width: 100,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stack) => Container(
                              width: 100,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ad.headline,
                            style: const TextStyle(fontSize: 14.0),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            ad.description,
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
