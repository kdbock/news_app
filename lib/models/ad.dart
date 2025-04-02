import 'package:cloud_firestore/cloud_firestore.dart';

enum AdType {
  titleSponsor, // 0
  inFeedDashboard, // 1
  inFeedNews, // 2
  weather, // 3
}

enum AdStatus {
  pending, // 0
  active, // 1
  rejected, // 2
  expired, // 3
  deleted, // 4
}

class Ad {
  final String? id;
  final String businessId;
  final String businessName;
  final String headline;
  final String description;
  final String imageUrl;
  final String linkUrl;
  final AdType type;
  final AdStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final int impressions;
  final int clicks;
  final double ctr;
  final double cost;

  Ad({
    this.id,
    required this.businessId,
    required this.businessName,
    required this.headline,
    required this.description,
    this.imageUrl = '',
    required this.linkUrl,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.impressions = 0,
    this.clicks = 0,
    this.ctr = 0.0,
    required this.cost,
  });

  Ad copyWith({
    String? id,
    String? businessId,
    String? businessName,
    String? headline,
    String? description,
    String? imageUrl,
    String? linkUrl,
    AdType? type,
    AdStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? impressions,
    int? clicks,
    double? ctr,
    double? cost,
  }) {
    return Ad(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      headline: headline ?? this.headline,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      type: type ?? this.type,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      ctr: ctr ?? this.ctr,
      cost: cost ?? this.cost,
    );
  }

  factory Ad.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Ad(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      businessName: data['businessName'] ?? '',
      headline: data['headline'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      linkUrl: data['linkUrl'] ?? '',
      type: AdType.values[data['type'] ?? 0],
      status: AdStatus.values[data['status'] ?? 0],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      impressions: (data['impressions'] as num?)?.toInt() ?? 0,
      clicks: (data['clicks'] as num?)?.toInt() ?? 0,
      ctr: (data['ctr'] as num?)?.toDouble() ?? 0.0,
      cost: (data['cost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'businessName': businessName,
      'headline': headline,
      'description': description,
      'imageUrl': imageUrl,
      'linkUrl': linkUrl,
      'type': type.index,
      'status': status.index,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'impressions': impressions,
      'clicks': clicks,
      'ctr': ctr,
      'cost': cost,
      'createdAt': Timestamp.now(),
    };
  }
}
