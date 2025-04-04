import 'package:flutter/material.dart';
import 'package:neusenews/models/ad.dart';
import 'package:neusenews/services/ad_service.dart';
import 'package:neusenews/services/analytics_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WeatherSponsorBanner extends StatefulWidget {
  const WeatherSponsorBanner({super.key});

  @override
  State<WeatherSponsorBanner> createState() => _WeatherSponsorBannerState();
}

class _WeatherSponsorBannerState extends State<WeatherSponsorBanner> {
  final AdService _adService = AdService();
  final AnalyticsService _analytics = AnalyticsService();

  // Cache weather icons to reduce network requests
  final Map<String, ImageProvider> _iconCache = {};

  static const String _defaultZip = '28501'; // Kinston, NC

  ImageProvider getWeatherIcon(String iconCode) {
    if (_iconCache.containsKey(iconCode)) {
      return _iconCache[iconCode]!;
    }

    final imageProvider = CachedNetworkImageProvider(
      'https://openweathermap.org/img/wn/$iconCode@2x.png',
    );
    _iconCache[iconCode] = imageProvider;
    return imageProvider;
  }

  Future<Map<String, dynamic>> getWeatherBundle(String zipCode) async {
    try {
      return {'current': {}, 'forecast': []};
    } catch (e) {
      _analytics.logEvent('weather_api_error', {'error': e.toString()});
      return _getFallbackData();
    }
  }

  Map<String, dynamic> _getFallbackData() {
    return {
      'current': {'temp': 75, 'condition': 'Clear', 'icon': '01d'},
      'forecast': [],
    };
  }

  Future<String> getCurrentZipCode() async {
    return _defaultZip;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Ad>>(
      stream: _adService.getActiveAdsByType(AdType.weather),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 0);
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildNoAdPlaceholder();
        }

        final ads = snapshot.data!;
        final ad = ads[DateTime.now().millisecond % ads.length];

        _adService.recordImpression(ad.id!);

        return Container(
          margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
          child: GestureDetector(
            onTap: () async {
              await _adService.recordClick(ad.id!);

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
                          child: CachedNetworkImage(
                            imageUrl: ad.imageUrl,
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  width: double.infinity,
                                  height: 120,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            errorWidget:
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

  Widget _buildNoAdPlaceholder() {
    return const SizedBox(height: 0);
  }
}
