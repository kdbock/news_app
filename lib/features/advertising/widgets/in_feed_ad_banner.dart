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
      debugPrint(
        '[InFeedAdBanner] Loading ads from Firestore for type: ${widget.adType}',
      );
      debugPrint('[InFeedAdBanner] Type index: ${widget.adType.index}');

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
        status: adStatus, // Use the fixed status handling
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
      return SizedBox(
        height: 128, // Reduced by another 20% from 160
        width: 220,
        child: Center(
          child: SizedBox(
            height: 16, // Also reduced
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_ad == null) {
      debugPrint('[InFeedAdBanner] No ad to display');
      return const SizedBox.shrink();
    }

    final ad = _ad!;
    debugPrint(
      '[InFeedAdBanner] Building UI for ad: ${ad.id} - ${ad.headline}',
    );

    return SizedBox(
      height: 128, // Reduced by another 20% from 160
      width: 220,
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
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                debugPrint('Could not launch URL: $url');
              }
            }
          } catch (e) {
            debugPrint('Error handling ad click: $e');
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ad sponsor label
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
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
                    style: const TextStyle(fontSize: 10.0, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Ad image - constrainted to fixed dimensions
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ad.imageUrl,
                height: 70, // Reduced by another 20% from 88
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, _) {
                  return Container(
                    height: 70, // Match the reduced height
                    width: double.infinity,
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
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Headline
                    Text(
                      ad.headline,
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Description
                    if (ad.description.isNotEmpty)
                      Text(
                        ad.description,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey[800],
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
      ),
    );
  }
}
