import 'package:flutter/material.dart';
import 'package:neusenews/features/advertising/models/ad.dart';
import 'package:neusenews/features/advertising/services/ad_service.dart';
import 'package:neusenews/features/advertising/models/ad_type.dart';
import 'package:neusenews/features/advertising/models/ad_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:neusenews/di/service_locator.dart';
import 'package:neusenews/features/advertising/repositories/ad_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdBanner extends StatefulWidget {
  final AdType adType;
  final double height;
  final EdgeInsets padding;
  final BorderRadius borderRadius;

  const AdBanner({
    super.key,
    required this.adType,
    this.height = 120,
    this.padding = EdgeInsets.zero,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  final AdService _adService = AdService(
    repository: serviceLocator<AdRepository>(),
    auth: serviceLocator<FirebaseAuth>(),
  );

  Ad? _ad;
  bool _isLoading = true;
  bool _hasAttemptedLoad = false;

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
    if (_hasAttemptedLoad) return;
    _hasAttemptedLoad = true;

    try {
      debugPrint(
        '[AdBanner] Loading ads from Firestore for type: ${widget.adType}',
      );

      // Query for banner ads (type 4)
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('ads')
              .where('type', isEqualTo: widget.adType.index)
              .limit(5)
              .get();

      debugPrint('[AdBanner] Found ${snapshot.docs.length} banner ads');

      // If no specific banner ads found, try any active ad as fallback
      if (snapshot.docs.isEmpty) {
        snapshot =
            await FirebaseFirestore.instance
                .collection('ads')
                .where('status', whereIn: [AdStatus.active.index, 'active'])
                .limit(5)
                .get();

        debugPrint(
          '[AdBanner] Found ${snapshot.docs.length} active ads as fallback',
        );
      }

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        debugPrint('[AdBanner] No ads available to display');
        return;
      }

      // Output sample data for debugging
      if (snapshot.docs.isNotEmpty) {
        final sampleData = snapshot.docs.first.data() as Map<String, dynamic>;
        debugPrint('[AdBanner] Sample ad data: ${sampleData.keys.toList()}');
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
          debugPrint('[AdBanner] Recorded impression for ad: ${ad.id}');
        }
      }
    } catch (e, stack) {
      debugPrint('[AdBanner] Error loading ad: $e');
      debugPrint('[AdBanner] Stack trace: $stack');
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
      return Padding(
        padding: widget.padding,
        child: Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: widget.borderRadius,
          ),
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
      // Return placeholder with proper styling
      return Padding(
        padding: widget.padding,
        child: Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: widget.borderRadius,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business_center, size: 32, color: Colors.grey[500]),
              const SizedBox(height: 8),
              Text(
                'Advertisement',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final ad = _ad!;
    debugPrint('[AdBanner] Building UI for ad: ${ad.id} - ${ad.headline}');

    return Padding(
      padding: widget.padding,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            try {
              debugPrint('[AdBanner] Ad clicked: ${ad.id}');

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
                  debugPrint('[AdBanner] Could not launch URL: $url');
                }
              }
            } catch (e) {
              debugPrint('[AdBanner] Error handling ad click: $e');
            }
          },
          borderRadius: widget.borderRadius,
          child: Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: widget.borderRadius,
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Ad image
                  if (ad.imageUrl.isNotEmpty &&
                      !ad.imageUrl.contains('placeholder.com'))
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: widget.borderRadius.topLeft,
                        bottomLeft: widget.borderRadius.bottomLeft,
                      ),
                      child: Image.network(
                        ad.imageUrl,
                        width: widget.height * 0.85,
                        height: widget.height,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, _) {
                          debugPrint('[AdBanner] Image error: $error');
                          return Container(
                            width: widget.height * 0.85,
                            height: widget.height,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      ),
                    ),

                  // Ad content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Sponsored tag
                          Row(
                            children: [
                              Text(
                                'SPONSORED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const Spacer(),
                              if (ad.businessName.isNotEmpty)
                                Text(
                                  ad.businessName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Headline
                          Text(
                            ad.headline,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),

                          // Description if available
                          if (ad.description.isNotEmpty)
                            Expanded(
                              child: Text(
                                ad.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[800],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
