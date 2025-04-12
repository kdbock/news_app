import 'package:cloud_firestore/cloud_firestore.dart';

class AdView {
  final String adId;
  final String userId;
  final DateTime viewedAt;

  AdView({required this.adId, required this.userId, required this.viewedAt});

  factory AdView.fromFirestore(Map<String, dynamic> data) {
    return AdView(
      adId: data['adId'] ?? '',
      userId: data['userId'] ?? '',
      viewedAt: (data['viewedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adId': adId,
      'userId': userId,
      'viewedAt': Timestamp.fromDate(viewedAt),
    };
  }
}
