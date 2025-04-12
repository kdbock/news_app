import 'package:flutter/material.dart';
import 'package:neusenews/features/advertising/models/ad.dart';
import 'package:neusenews/features/advertising/services/ad_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:neusenews/features/advertising/models/ad_type.dart';
import 'package:neusenews/di/service_locator.dart';
import 'package:neusenews/features/advertising/repositories/ad_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:neusenews/features/advertising/models/ad_status.dart';

class WeatherTitleSponsor extends StatefulWidget {
  const WeatherTitleSponsor({super.key});

  @override
  State<WeatherTitleSponsor> createState() => _WeatherTitleSponsorState();
}

class _WeatherTitleSponsorState extends State<WeatherTitleSponsor> {
  late final AdService _adService;

  @override
  void initState() {
    super.initState();
    _adService = AdService(
      repository: serviceLocator<AdRepository>(),
      auth: FirebaseAuth.instance,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Ad>>(
      stream: _adService.getActiveAdsByType(AdType.titleSponsor),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 0);
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(height: 0);
        }

        final ads = snapshot.data!;
        final ad = ads[DateTime.now().millisecond % ads.length];

        try {
          _adService.recordImpression(ad.id!);
        } catch (e) {
          debugPrint('Failed to record ad impression: $e');
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: GestureDetector(
            onTap: () async {
              try {
                await _adService.recordClick(ad.id!);
                final Uri url = Uri.parse(ad.linkUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              } catch (e) {
                debugPrint('Error handling ad click: $e');
              }
            },
            child: Card(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2.0,
                    ),
                    color: Colors.grey[200],
                    child: Row(
                      children: [
                        const Text(
                          'TITLE SPONSOR',
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
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ad.headline,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                ad.description,
                                style: const TextStyle(fontSize: 14.0),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(4.0),
                            bottomRight: Radius.circular(4.0),
                          ),
                          child:
                              ad.imageUrl.startsWith('http')
                                  ? Image.network(
                                    ad.imageUrl,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Image.asset(
                                              'assets/images/header.png',
                                              height: 100,
                                              fit: BoxFit.contain,
                                            ),
                                  )
                                  : Image.asset(
                                    ad.imageUrl,
                                    height: 100,
                                    fit: BoxFit.cover,
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
      },
    );
  }
}

class WeatherSponsorBanner extends StatefulWidget {
  const WeatherSponsorBanner({super.key});

  @override
  State<WeatherSponsorBanner> createState() => _WeatherSponsorBannerState();
}

class _WeatherSponsorBannerState extends State<WeatherSponsorBanner> {
  final AdService _adService = AdService(
    repository: serviceLocator<AdRepository>(),
    auth: serviceLocator<FirebaseAuth>(),
  );

  Ad? _ad;
  bool _isLoading = true;
  bool _hasAttemptedLoad = false; // Prevent repeated load attempts

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
    if (_hasAttemptedLoad) return; // Prevent multiple load attempts

    _hasAttemptedLoad = true;

    try {
      debugPrint(
        '[WeatherSponsorBanner] Loading weather sponsor ads from Firestore',
      );

      // Only query once
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('ads')
              .where('type', isEqualTo: AdType.weather.index)
              .limit(5)
              .get();

      debugPrint(
        '[WeatherSponsorBanner] Found ${snapshot.docs.length} weather sponsor ads',
      );

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // For debugging, print the first document
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        debugPrint(
          '[WeatherSponsorBanner] First ad data fields: ${data.keys.toList()}',
        );

        if (data.containsKey('type')) {
          debugPrint(
            '[WeatherSponsorBanner] Type: ${data['type']} (${data['type'].runtimeType})',
          );
        }

        if (data.containsKey('status')) {
          debugPrint(
            '[WeatherSponsorBanner] Status: ${data['status']} (${data['status'].runtimeType})',
          );
        }
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
        type: AdType.values[data['type'] ?? 0],
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
            '[WeatherSponsorBanner] Recorded impression for ad: ${ad.id}',
          );
        }
      }
    } catch (e, stack) {
      debugPrint('[WeatherSponsorBanner] Error loading ad: $e');
      debugPrint('[WeatherSponsorBanner] Stack trace: $stack');
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
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          height: 80,
          width: double.infinity,
          child: Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFd2982a),
              ),
            ),
          ),
        ),
      );
    }

    if (_ad == null) {
      debugPrint('[WeatherSponsorBanner] No ad to display');
      return const SizedBox.shrink();
    }

    final ad = _ad!;
    debugPrint(
      '[WeatherSponsorBanner] Building UI for ad: ${ad.id} - ${ad.headline}',
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          try {
            debugPrint('[WeatherSponsorBanner] Ad clicked: ${ad.id}');

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
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                debugPrint('[WeatherSponsorBanner] Could not launch URL: $url');
              }
            }
          } catch (e) {
            debugPrint('[WeatherSponsorBanner] Error handling ad click: $e');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sponsored header
              Row(
                children: [
                  Text(
                    'WEATHER SPONSOR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    ad.businessName,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Main content - horizontal layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Ad image - only if available and not a placeholder
                  if (ad.imageUrl.isNotEmpty &&
                      !ad.imageUrl.contains('placeholder'))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ad.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, _) {
                          debugPrint(
                            '[WeatherSponsorBanner] Image error: $error',
                          );
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.wb_cloudy,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(width: 12),

                  // Ad text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ad.headline,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (ad.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            ad.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
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
            ],
          ),
        ),
      ),
    );
  }
}
