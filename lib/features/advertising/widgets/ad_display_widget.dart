import 'package:flutter/material.dart';
import '../models/ad.dart';
import '../services/ad_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AdDisplayWidget extends StatelessWidget {
  final Ad ad;
  final AdDisplayType displayType;
  final AdService adService;
  final BorderRadius? borderRadius;
  
  const AdDisplayWidget({
    super.key,
    required this.ad,
    required this.displayType,
    required this.adService,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    // Record impression on build
    Future.microtask(() => adService.recordImpression(ad.id!));
    
    return GestureDetector(
      onTap: _handleAdTap,
      child: _buildAdByType(context),
    );
  }
  
  Widget _buildAdByType(BuildContext context) {
    switch (displayType) {
      case AdDisplayType.banner:
        return _buildBannerAd(context);
      case AdDisplayType.inFeed:
        return _buildInFeedAd(context);
      case AdDisplayType.sponsor:
        return _buildSponsorAd(context);
      case AdDisplayType.weatherSponsor:
        return _buildWeatherSponsorAd(context);
    }
  }
  
  // Extract the repeated UI patterns into helper methods
  Widget _buildBannerAd(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdHeader('ADVERTISEMENT'),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildAdImage(80, 80),
              ),
              Expanded(
                child: _buildAdContent(),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Add this method to handle in-feed ads
  Widget _buildInFeedAd(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdHeader('IN-FEED AD'),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: _buildAdContent(),
          ),
        ],
      ),
    );
  }

  // Add this method to handle sponsor ads
  Widget _buildSponsorAd(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdHeader('SPONSORED'),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildAdImage(80, 80),
              ),
              Expanded(
                child: _buildAdContent(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Add this method to handle weather sponsor ads
  Widget _buildWeatherSponsorAd(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdHeader('WEATHER SPONSOR'),
          Padding(
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
                const SizedBox(height: 4.0),
                Text(
                  ad.description,
                  style: const TextStyle(fontSize: 14.0),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Common components extracted
  Widget _buildAdHeader(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      color: Colors.grey[200],
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
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
    );
  }
  
  Widget _buildAdImage(double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.0),
      child: Image.network(
        ad.imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.image, size: 40),
        ),
      ),
    );
  }
  
  Widget _buildAdContent() {
    return Padding(
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
          const SizedBox(height: 4.0),
          Text(
            ad.description,
            style: const TextStyle(fontSize: 14.0),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Future<void> _handleAdTap() async {
    try {
      await adService.recordClick(ad.id!);
      
      final Uri url = Uri.parse(ad.linkUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint('Error handling ad click: $e');
    }
  }
}

enum AdDisplayType {
  banner,
  inFeed,
  sponsor,
  weatherSponsor,
}