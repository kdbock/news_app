import 'package:flutter/material.dart';
import 'package:neusenews/models/ad.dart';
import 'package:neusenews/services/ad_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class InFeedAdBanner extends StatefulWidget {
  final AdType adType;

  const InFeedAdBanner({super.key, required this.adType});

  @override
  State<InFeedAdBanner> createState() => _InFeedAdBannerState();
}

class _InFeedAdBannerState extends State<InFeedAdBanner> {
  final AdService _adService = AdService();
  final _random = Random();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Ad>>(
      stream: _adService.getActiveAdsByType(widget.adType),
      builder: (context, snapshot) {
        // Debug information - remove in production
        print("Building InFeedAdBanner for type: ${widget.adType}");
        print("Connection state: ${snapshot.connectionState}");
        if (snapshot.hasError) print("Error: ${snapshot.error}");

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          print("No ads available for type ${widget.adType}");
          return const SizedBox(height: 0);
        }

        // Get a random ad from the available ones
        final ads = snapshot.data!;
        print("Found ${ads.length} ads for type ${widget.adType}");
        final ad = ads[_random.nextInt(ads.length)];

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
                          child: Image.network(
                            ad.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print("Error loading ad image: $error");
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, size: 40),
                              );
                            },
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
