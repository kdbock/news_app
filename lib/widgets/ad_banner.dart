import 'package:flutter/material.dart' hide debugPrint;
import 'package:neusenews/models/ad.dart';
import 'package:neusenews/services/ad_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' as flutter_foundation;

class AdBanner extends StatefulWidget {
  final AdType adType;
  final Widget Function(BuildContext, dynamic)? errorBuilder;
  final Function(Ad)? onLoaded;
  final Function(String)? onError;

  const AdBanner({
    super.key, // Fixed super parameter
    required this.adType,
    this.errorBuilder,
    this.onLoaded,
    this.onError,
  });

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  final AdService _adService = AdService();

  @override
  Widget build(BuildContext context) {
    flutter_foundation.debugPrint(
      "Building AdBanner with type: ${widget.adType}",
    );

    return FutureBuilder<List<Ad>>(
      future: _adService.getActiveAdsByTypeOnce(widget.adType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingPlaceholder();
        }

        if (snapshot.hasError) {
          if (widget.onError != null) {
            widget.onError!(snapshot.error.toString());
          }
          if (widget.errorBuilder != null) {
            return widget.errorBuilder!(context, snapshot.error);
          }
          return _buildErrorPlaceholder();
        }

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final ads = snapshot.data!;
          final ad = ads[DateTime.now().millisecond % ads.length];

          if (widget.onLoaded != null) {
            widget.onLoaded!(ad);
          }

          try {
            _adService.recordImpression(ad.id!);
          } catch (e) {
            flutter_foundation.debugPrint("Failed to record impression: $e");
          }

          return _buildAdContent(ad);
        }

        if (widget.errorBuilder != null) {
          return widget.errorBuilder!(context, "No ads available");
        }
        return _buildEmptyPlaceholder();
      },
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      height: 90,
      color: Colors.grey[100],
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      height: 90,
      color: Colors.grey[200],
      child: Center(
        child: Text(
          'Ad temporarily unavailable',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      height: 90,
      color: Colors.grey[100],
      child: Center(
        child: Text(
          'No sponsored content available',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildAdContent(Ad ad) {
    return GestureDetector(
      onTap: () async {
        try {
          await _adService.recordClick(ad.id!);

          final Uri url = Uri.parse(ad.linkUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          }
        } catch (e) {
          flutter_foundation.debugPrint("Error handling ad click: $e");
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: Image.network(
                  ad.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 80),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 4.0),
                    Text(
                      ad.headline,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      ad.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.0),
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
}

extension AdServiceExtension on AdService {
  void recordImpression(String adId) {
    try {
      FirebaseFirestore.instance.collection('ads').doc(adId).update({
        'impressions': FieldValue.increment(1),
      });
    } catch (e) {
      flutter_foundation.debugPrint("Error recording impression: $e");
    }
  }

  Future<void> recordClick(String adId) async {
    try {
      await FirebaseFirestore.instance.collection('ads').doc(adId).update({
        'clicks': FieldValue.increment(1),
      });
    } catch (e) {
      flutter_foundation.debugPrint("Error recording click: $e");
    }
  }

  Future<List<Ad>> getActiveAdsByTypeOnce(AdType adType) async {
    try {
      final now = DateTime.now();

      final snapshot =
          await FirebaseFirestore.instance
              .collection('ads')
              .where('type', isEqualTo: adType.toString())
              .where('status', isEqualTo: 'active')
              .where('startDate', isLessThanOrEqualTo: now)
              .where('endDate', isGreaterThanOrEqualTo: now)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Ad(
          id: doc.id,
          businessId: data['businessId'],
          businessName: data['businessName'] ?? '',
          type: AdType.values.firstWhere(
            (e) => e.toString() == data['type'],
            orElse: () => AdType.titleSponsor,
          ),
          headline: data['headline'] ?? '',
          description: data['description'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          linkUrl: data['linkUrl'] ?? '',
          status: data['status'],
          startDate:
              (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          endDate:
              (data['endDate'] as Timestamp?)?.toDate() ??
              DateTime.now().add(const Duration(days: 30)),
          cost: (data['cost'] as num?)?.toDouble() ?? 0.0,
          isActive: data['isActive'] ?? true,
        );
      }).toList();
    } catch (e) {
      flutter_foundation.debugPrint("Error fetching ads: $e");
      return <Ad>[];
    }
  }
}
