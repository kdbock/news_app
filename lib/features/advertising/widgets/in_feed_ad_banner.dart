import 'package:flutter/material.dart';
import 'package:neusenews/features/advertising/models/ad.dart'; // Updated path
import 'package:neusenews/features/advertising/services/ad_service.dart'; // Updated path
import 'package:neusenews/features/advertising/models/ad_type.dart'; // Added import
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:neusenews/di/service_locator.dart';
import 'package:neusenews/features/advertising/repositories/ad_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Ad>>(
      stream: _adService.getActiveAdsByType(widget.adType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return const SizedBox(height: 0);
        }

        // Get a random ad from the available ones
        final ads = snapshot.data!;
        final ad = ads[Random().nextInt(ads.length)];

        // Record impression
        _adService.recordImpression(ad.id!);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0),
          child: GestureDetector(
            onTap: () async {
              // Record click
              await _adService.recordClick(ad.id!);

              // Open link
              final Uri url = Uri.parse(ad.linkUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            child: Card(
              elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child:
                              ad.imageUrl.startsWith('http')
                                  ? Image.network(
                                    ad.imageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Image.asset(
                                              'assets/images/Default.jpeg',
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            ),
                                  )
                                  : Image.asset(
                                    ad.imageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ad.headline,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.0,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              ad.description,
                              style: const TextStyle(fontSize: 13.0),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12.0),
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
