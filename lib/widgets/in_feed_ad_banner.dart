import 'package:flutter/material.dart';
import 'package:neusenews/models/ad.dart';
import 'package:neusenews/services/ad_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:neusenews/constants/layout_constants.dart';

class InFeedAdBanner extends StatefulWidget {
  final AdType adType;

  const InFeedAdBanner({super.key, this.adType = AdType.inFeedDashboard});

  @override
  State<InFeedAdBanner> createState() => _InFeedAdBannerState();
}

class _InFeedAdBannerState extends State<InFeedAdBanner> {
  final AdService _adService = AdService();
  Ad? _selectedAd;
  bool _isLoading = true;
  bool _hasAttemptedLoad = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (_hasAttemptedLoad) return;

    _isLoading = true;
    _hasAttemptedLoad = true;
    if (mounted) setState(() {});

    try {
      // Use take(1) to close the stream after first emission
      final ads =
          await _adService.getActiveAdsByType(widget.adType).take(1).first;

      if (ads.isNotEmpty && mounted) {
        final random = Random();
        final selectedAd = ads[random.nextInt(ads.length)];

        await _adService.recordImpression(selectedAd.id!);

        setState(() {
          _selectedAd = selectedAd;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading in-feed ad: $e');
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
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(LayoutConstants.cardBorderRadius),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_selectedAd == null) {
      return const SizedBox.shrink();
    }

    final ad = _selectedAd!;

    return Card(
      elevation: LayoutConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LayoutConstants.cardBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () async {
          await _adService.recordClick(ad.id!);
          final Uri url = Uri.parse(ad.linkUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ad header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 2.0,
              ),
              color: Colors.grey[200],
              child: Row(
                children: [
                  Text(
                    'SPONSORED',
                    style: LayoutConstants.sponsorLabelStyle.copyWith(
                      color: Theme.of(context).primaryColor,
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

            // Ad image
            Expanded(
              flex: 3,
              child: CachedNetworkImage(
                imageUrl: ad.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 40),
                    ),
              ),
            ),

            // Ad text
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.headline,
                      style: LayoutConstants.headlineStyle,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2.0),
                    Expanded(
                      child: Text(
                        ad.description,
                        style: LayoutConstants.bodyTextStyle,
                        maxLines: 2,
                      ),
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
