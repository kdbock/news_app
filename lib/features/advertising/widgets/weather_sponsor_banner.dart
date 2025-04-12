import 'package:flutter/material.dart';
import 'package:neusenews/features/advertising/models/ad.dart';
import 'package:neusenews/features/advertising/services/ad_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:neusenews/features/advertising/models/ad_type.dart';
import 'package:neusenews/di/service_locator.dart';
import 'package:neusenews/features/advertising/repositories/ad_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TitleSponsorBanner extends StatefulWidget {
  const TitleSponsorBanner({super.key});

  @override
  State<TitleSponsorBanner> createState() => TitleSponsorBannerState();
}

class TitleSponsorBannerState extends State<TitleSponsorBanner> {
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Ad>>(
      stream: _adService.getActiveAdsByType(AdType.weather),
      builder: (context, snapshot) {
        // Show placeholder during loading to maintain layout
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder();
        }

        // Handle errors or empty data with placeholder
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          debugPrint('Weather ad error or empty: ${snapshot.error}');
          return _buildPlaceholder();
        }

        // Get ad from the available ones (use a timestamp-based approach)
        final ads = snapshot.data!;
        final adIndex = DateTime.now().millisecondsSinceEpoch % ads.length;
        final ad = ads[adIndex];

        try {
          // Record impression
          _adService.recordImpression(ad.id!);
        } catch (e) {
          debugPrint('Failed to record ad impression: $e');
        }

        return _buildAdCard(ad);
      },
    );
  }

  Widget _buildAdCard(Ad ad) {
    return Container(
      margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: GestureDetector(
        onTap: () async {
          try {
            // Record click
            await _adService.recordClick(ad.id!);

            // Open link
            final Uri url = Uri.parse(ad.linkUrl);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
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
                            (context, error, stack) => Container(
                              height: 120,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      ad.headline,
                      style: const TextStyle(fontSize: 16.0),
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
  }

  // Add a placeholder that takes up space but doesn't show as empty
  Widget _buildPlaceholder() {
    return Container(
      margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      height: 60, // Minimal height to not disrupt layout
      child: Card(
        elevation: 1,
        child: Center(
          child: Text(
            'Weather Information',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      ),
    );
  }
}
