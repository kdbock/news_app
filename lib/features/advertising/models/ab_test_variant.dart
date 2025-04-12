import 'package:flutter/foundation.dart';

enum VariantType { headline, image, cta, description }

class AbTestVariant {
  final String id;
  final String adId;
  final VariantType variantType;
  final String originalContent;
  final String variantContent;
  final int impressions;
  final int clicks;
  final double ctr;
  final bool isActive;
  
  AbTestVariant({
    required this.id,
    required this.adId,
    required this.variantType,
    required this.originalContent,
    required this.variantContent,
    this.impressions = 0,
    this.clicks = 0,
    this.ctr = 0.0,
    this.isActive = true,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'adId': adId,
      'variantType': describeEnum(variantType),
      'originalContent': originalContent,
      'variantContent': variantContent,
      'impressions': impressions,
      'clicks': clicks,
      'ctr': ctr,
      'isActive': isActive,
    };
  }
}