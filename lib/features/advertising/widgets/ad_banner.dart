import 'package:flutter/material.dart';
import 'package:neusenews/features/advertising/models/ad.dart';
import 'package:neusenews/features/advertising/models/ad_type.dart';
import 'package:neusenews/features/advertising/services/ad_service.dart';
import 'package:neusenews/features/advertising/repositories/ad_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neusenews/di/service_locator.dart';

class AdBanner extends StatefulWidget {
  final AdType adType;

  const AdBanner({super.key, required this.adType});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  final AdService _adService = AdService(
    repository: serviceLocator<AdRepository>(),
    auth: FirebaseAuth.instance,
  );

  @override
  Widget build(BuildContext context) {
    debugPrint("Building AdBanner with type: ${widget.adType}");

    return FutureBuilder<List<Ad>>(
      future: _adService.getActiveAdsByTypeOnce(widget.adType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 100, // Provide a minimum height
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          debugPrint("Ad error: ${snapshot.error}");
          return Container(
            height: 100, // Provide a minimum height
            padding: const EdgeInsets.all(8.0),
            child: const Card(
              child: Center(
                child: Text(
                  "Advertisement Space Available",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          );
        }

        final ads = snapshot.data;
        if (ads == null || ads.isEmpty) {
          return const SizedBox(height: 0); // No ad to display
        }

        final ad = ads[0];

        try {
          _adService.recordImpression(ad.id!);
        } catch (e) {
          debugPrint("Failed to record impression: $e");
        }

        return GestureDetector(
          onTap: () async {
            try {
              await _adService.recordClick(ad.id!);

              final Uri url = Uri.parse(ad.linkUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            } catch (e) {
              debugPrint("Error handling ad click: $e");
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
      },
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
      debugPrint("Error recording impression: $e");
    }
  }

  Future<void> recordClick(String adId) async {
    try {
      await FirebaseFirestore.instance.collection('ads').doc(adId).update({
        'clicks': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint("Error recording click: $e");
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

      final ads =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return Ad(
              id: doc.id,
              businessId: data['businessId'] ?? '',
              businessName: data['businessName'] ?? '',
              type: AdType.values.firstWhere(
                (e) => e.toString() == data['type'],
                orElse: () => AdType.titleSponsor,
              ),
              headline: data['headline'] ?? '',
              description: data['description'] ?? '',
              imageUrl: data['imageUrl'] ?? '',
              linkUrl: data['linkUrl'] ?? '',
              status: data['status'] ?? 'inactive',
              startDate:
                  (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              endDate:
                  (data['endDate'] as Timestamp?)?.toDate() ??
                  DateTime.now().add(const Duration(days: 30)),
              cost: (data['cost'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList();

      return ads;
    } catch (e) {
      debugPrint("Error fetching ads: $e");
      return [];
    }
  }
}
