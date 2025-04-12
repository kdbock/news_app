import 'package:flutter/material.dart';
import 'package:neusenews/features/advertising/models/ad.dart';
import 'package:neusenews/features/advertising/services/ad_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:neusenews/features/advertising/models/ad_type.dart';
import 'package:neusenews/di/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neusenews/features/advertising/repositories/ad_repository.dart';

class TitleSponsorBanner extends StatefulWidget {
  const TitleSponsorBanner({super.key});

  @override
  State<TitleSponsorBanner> createState() => _TitleSponsorBannerState();
}

class _TitleSponsorBannerState extends State<TitleSponsorBanner> {
  final AdService _adService = AdService(
    repository: serviceLocator<AdRepository>(),
    auth: FirebaseAuth.instance,
  );

  @override
  Widget build(BuildContext context) {
    debugPrint('Building TitleSponsorBanner');
    return StreamBuilder<List<Ad>>(
      stream: _adService.getActiveAdsByType(AdType.titleSponsor),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          debugPrint('TitleSponsor error or empty: ${snapshot.error}');
          return _buildPlaceholder();
        }

        // Get a random ad from the available ones
        final ads = snapshot.data!;
        final adIndex = DateTime.now().millisecondsSinceEpoch % ads.length;
        final ad = ads[adIndex];

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
                  await launchUrl(url, mode: LaunchMode.externalApplication);
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
                          'SPONSOR',
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
                          child: Text(
                            ad.headline,
                            style: const TextStyle(fontSize: 14.0),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      height: 40,
      child: Card(
        elevation: 1,
        child: Center(
          child: Text(
            'Sponsored Content',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      ),
    );
  }
}
