import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum AdType { titleSponsor, inFeedDashboard, inFeedNews, weather }

enum AdStatus { pending, active, expired, rejected, deleted }

class Ad {
  final String? id;
  final String? businessId;
  final String businessName;
  final String headline;
  final String description;
  final String linkUrl;
  final String imageUrl;
  final AdType type;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? status;
  final double cost; // Changed to non-nullable with default
  final int impressions; // Added for analytics
  final int clicks; // Added for analytics
  final double ctr; // Added for analytics

  Ad({
    this.id,
    this.businessId,
    required this.businessName,
    required this.headline,
    required this.description,
    required this.linkUrl,
    required this.imageUrl,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.status,
    this.cost = 0.0, // Default value avoids null issues
    this.impressions = 0,
    this.clicks = 0,
    this.ctr = 0.0,
  });

  // Add copyWith method for updating ad properties
  Ad copyWith({
    String? id,
    String? businessId,
    String? businessName,
    String? headline,
    String? description,
    String? linkUrl,
    String? imageUrl,
    AdType? type,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? status,
    double? cost,
    int? impressions,
    int? clicks,
    double? ctr,
  }) {
    return Ad(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      headline: headline ?? this.headline,
      description: description ?? this.description,
      linkUrl: linkUrl ?? this.linkUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      cost: cost ?? this.cost,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      ctr: ctr ?? this.ctr,
    );
  }

  // Add toFirestore method for Firestore serialization
  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'businessName': businessName,
      'headline': headline,
      'description': description,
      'linkUrl': linkUrl,
      'imageUrl': imageUrl,
      'type': type.toString(),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'status': status ?? 'pending',
      'cost': cost,
      'impressions': impressions,
      'clicks': clicks,
      'ctr': ctr,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Ad.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle different type formats (string or integer)
    AdType adType;
    final typeValue = data['type'];

    if (typeValue is int) {
      // If type is stored as an integer index
      if (typeValue >= 0 && typeValue < AdType.values.length) {
        adType = AdType.values[typeValue];
      } else {
        adType =
            AdType.titleSponsor; // Default to titleSponsor instead of banner
      }
    } else {
      // This part is already handled correctly
      try {
        adType = AdType.values.firstWhere(
          (e) =>
              e.toString().split('.').last == typeValue ||
              e.toString() == typeValue,
          orElse: () => AdType.titleSponsor,
        );
      } catch (_) {
        adType = AdType.titleSponsor;
      }
    }

    // Fix the status field - convert int to string if needed
    String? status;
    dynamic statusValue = data['status'];
    if (statusValue is int) {
      // Convert int status to string
      status = statusValue.toString();
    } else if (statusValue is String) {
      status = statusValue;
    } else {
      status = null; // Handle null case
    }

    // Cast other potentially problematic fields
    final businessId = data['businessId']?.toString();
    final businessName = data['businessName']?.toString() ?? '';
    final headline = data['headline']?.toString() ?? '';
    final description = data['description']?.toString() ?? '';
    final imageUrl = data['imageUrl']?.toString() ?? '';
    final linkUrl = data['linkUrl']?.toString() ?? '';

    // Use the imported debugPrint
    if (typeValue is! int) {
      debugPrint('Ad ${doc.id}: Non-integer type value: $typeValue');
    }

    return Ad(
      id: doc.id,
      businessId: businessId,
      businessName: businessName,
      headline: headline,
      description: description,
      imageUrl: imageUrl,
      linkUrl: linkUrl,
      type: adType,
      isActive: data['isActive'] ?? false,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate:
          (data['endDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      status: status,
      cost: (data['cost'] is num) ? (data['cost'] as num).toDouble() : 0.0,
      impressions:
          (data['impressions'] is num)
              ? (data['impressions'] as num).toInt()
              : 0,
      clicks: (data['clicks'] is num) ? (data['clicks'] as num).toInt() : 0,
      ctr: (data['ctr'] is num) ? (data['ctr'] as num).toDouble() : 0.0,
    );
  }

  // Helper for converting AdType enum to string representation
  static String adTypeToString(AdType type) {
    switch (type) {
      case AdType.titleSponsor:
        return 'titleSponsor';
      case AdType.inFeedDashboard:
        return 'inFeedDashboard';
      case AdType.inFeedNews:
        return 'inFeedNews';
      case AdType.weather:
        return 'weather';
    }
  }

  // Helper methods for AdStatus
  static String getStatusString(AdStatus status) {
    switch (status) {
      case AdStatus.pending:
        return 'pending';
      case AdStatus.active:
        return 'active';
      case AdStatus.expired:
        return 'expired';
      case AdStatus.rejected:
        return 'rejected';
      case AdStatus.deleted:
        return 'deleted';
    }
  }

  static AdStatus getStatusFromString(String? statusStr) {
    switch (statusStr) {
      case 'active':
        return AdStatus.active;
      case 'pending':
        return AdStatus.pending;
      case 'expired':
        return AdStatus.expired;
      case 'rejected':
        return AdStatus.rejected;
      case 'deleted':
        return AdStatus.deleted;
      default:
        return AdStatus.pending;
    }
  }

  // Debug helper method instead of loose code at file level
  static void debugAdTypes() {
    debugPrint('AdType.titleSponsor value: ${AdType.titleSponsor.toString()}');
  }
}
