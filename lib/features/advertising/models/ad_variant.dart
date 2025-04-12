import 'package:neusenews/features/advertising/models/ad.dart';
// Ensure AdType is defined here
// Added import for AdStatus

class AdVariant extends Ad {
  final String variantId;
  final String testGroupId;

  AdVariant({
    required this.variantId,
    required this.testGroupId,
    required super.businessId,
    required super.businessName,
    required super.headline,
    required super.description,
    required super.linkUrl,
    required super.type,
    required super.status,
    required super.startDate,
    required super.endDate,
    super.cost = 0.0,
    super.imageUrl,
    super.impressions,
    super.clicks,
    super.ctr,
    super.rejectionReason,
  });
}

// Test different headlines, images, or CTAs