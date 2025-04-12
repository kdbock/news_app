import 'package:flutter/material.dart';
import 'package:neusenews/features/advertising/models/ad.dart';
import 'package:neusenews/features/advertising/models/ad_type.dart';
import 'package:neusenews/features/advertising/services/ad_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:neusenews/di/service_locator.dart';

class AdBanner extends StatefulWidget {
  final AdType adType;
  final double height;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const AdBanner({
    super.key,
    required this.adType,
    this.height = 100,
    this.padding = const EdgeInsets.all(8.0),
    this.borderRadius = const BorderRadius.all(Radius.circular(4.0)),
  });

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  final AdService _adService = serviceLocator<AdService>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Ad>>(
      stream: _adService.getActiveAdsByType(widget.adType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingPlaceholder();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          debugPrint("Ad error: ${snapshot.error}");
          return _buildEmptyAdSpace();
        }

        final ads = snapshot.data;
        if (ads == null || ads.isEmpty) {
          return const SizedBox.shrink(); // No ad to display
        }

        final ad = ads[0];

        // Record impression
        _adService.recordImpression(ad.id!);

        return _buildAdContent(ad);
      },
    );
  }

  Widget _buildLoadingPlaceholder() {
    return SizedBox(
      height: widget.height,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyAdSpace() {
    return Container(
      height: widget.height,
      padding: widget.padding,
      child: Card(
        child: Center(
          child: Text(
            "Advertisement Space Available",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  Widget _buildAdContent(Ad ad) {
    return GestureDetector(
      onTap: () => _handleAdClick(ad),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: widget.borderRadius),
        child: Container(
          padding: widget.padding,
          child: Row(
            children: [
              _buildAdImage(ad),
              const SizedBox(width: 12.0),
              Expanded(child: _buildAdDetails(ad)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdImage(Ad ad) {
    return ClipRRect(
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
    );
  }

  Widget _buildAdDetails(Ad ad) {
    return Column(
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
              style: const TextStyle(fontSize: 10.0, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          ad.headline,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
        ),
        const SizedBox(height: 4.0),
        Text(
          ad.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.0),
        ),
      ],
    );
  }

  Future<void> _handleAdClick(Ad ad) async {
    try {
      await _adService.recordClick(ad.id!);

      final Uri url = Uri.parse(ad.linkUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint("Error handling ad click: $e");
    }
  }
}
