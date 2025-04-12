import 'package:cloud_firestore/cloud_firestore.dart';
import 'ad_type.dart';
import 'ad_status.dart';

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
  final String? rejectionReason;

  const Ad({
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
    this.rejectionReason,
  });

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
      'rejectionReason': rejectionReason,
    };
  }

  static Ad fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Ad(
      id: doc.id,
      businessId: data['businessId'] as String,
      businessName: data['businessName'] as String,
      headline: data['headline'] as String,
      description: data['description'] as String,
      imageUrl: data['imageUrl'] as String? ?? '',
      linkUrl: data['linkUrl'] as String,
      type: AdType.values[data['type'] as int],
      status: AdStatus.values[data['status'] as int],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      impressions: data['impressions'] as int? ?? 0,
      clicks: data['clicks'] as int? ?? 0,
      ctr: (data['ctr'] as num?)?.toDouble() ?? 0.0,
      cost: (data['cost'] as num).toDouble(),
      rejectionReason: data['rejectionReason'] as String?,
    );
  }
}
