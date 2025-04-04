import 'package:flutter/material.dart';
import 'package:neusenews/models/ad.dart';
import 'package:neusenews/services/ad_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TitleSponsorBanner extends StatefulWidget {
  const TitleSponsorBanner({super.key});

  @override
  State<TitleSponsorBanner> createState() => _TitleSponsorBannerState();
}

class _TitleSponsorBannerState extends State<TitleSponsorBanner> {
  final AdService _adService = AdService();
  // Cache the stream and use distinct to prevent excessive rebuilds
  late final Stream<List<Ad>> _adsStream;

  @override
  void initState() {
    super.initState();

    // Create a cached stream with distinct() to prevent duplicate emissions
    _adsStream = _adService.getActiveAdsByType(AdType.titleSponsor).distinct((
      previous,
      next,
    ) {
      // Only emit if the lists are different
      if (previous.length != next.length) return false;
      // Compare ad IDs to see if the list has changed
      for (int i = 0; i < previous.length; i++) {
        if (previous[i].id != next[i].id) return false;
      }
      return true;
    });

    // Log only once during initialization
    debugPrint('Title sponsor banner initialized');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Ad>>(
      stream: _adsStream,
      builder: (context, snapshot) {
        // Only log state changes, not every rebuild
        if (snapshot.connectionState == ConnectionState.active &&
            snapshot.data == null) {
          debugPrint('Title Sponsor - No ads available');
        }

        if (snapshot.hasError) {
          debugPrint('Title Sponsor Error: ${snapshot.error}');
          return const SizedBox(height: 0);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 60,
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(height: 0);
        }

        // Get a random ad from the available ones
        final ads = snapshot.data!;
        final ad = ads.first;

        // Record impression
        _adService.recordImpression(ad.id!);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: GestureDetector(
            onTap: () async {
              await _adService.recordClick(ad.id!);
              final Uri url = Uri.parse(ad.linkUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
                        Text(
                          'SPONSOR',
                          style: TextStyle(
                            fontSize: 10.0,
                            color: Theme.of(context).primaryColor,
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
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // Ad image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: CachedNetworkImage(
                            imageUrl: ad.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image),
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Ad text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ad.headline,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ad.description,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
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
