import 'package:flutter/material.dart';
import 'package:neusenews/models/ad.dart';
import 'package:neusenews/services/ad_service.dart';
import 'package:url_launcher/url_launcher.dart';

class WeatherSponsorBanner extends StatefulWidget {
  const WeatherSponsorBanner({super.key});

  @override
  State<WeatherSponsorBanner> createState() => _WeatherSponsorBannerState();
}

class _WeatherSponsorBannerState extends State<WeatherSponsorBanner> {
  final AdService _adService = AdService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Ad>>(
      stream: _adService.getActiveAdsByType(AdType.weather),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 0);
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(height: 0);
        }

        // Get a random ad from the available ones
        final ads = snapshot.data!;
        final ad = ads[DateTime.now().millisecond % ads.length];

        // Record impression
        _adService.recordImpression(ad.id!);

        return Container(
          margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
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
                          'WEATHER SPONSOR',
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
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: Image.network(
                            ad.imageUrl,
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  width: double.infinity,
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 40),
                                ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          ad.headline,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          ad.description,
                          style: const TextStyle(fontSize: 14.0),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
