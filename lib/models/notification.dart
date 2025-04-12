import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  breakingNews,
  adApproved,
  adRejected,
  articleApproved,
  articleRejected,
  eventApproved,
  eventRejected,
  weather,
  accountUpdate,
  general
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final String? imageUrl;
  final String? targetRoute;
  final Map<String, dynamic>? parameters;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.imageUrl,
    this.targetRoute,
    this.parameters,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: NotificationType.values[data['type'] ?? 0],
      imageUrl: data['imageUrl'],
      targetRoute: data['targetRoute'],
      parameters: data['parameters'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.index,
      'imageUrl': imageUrl,
      'targetRoute': targetRoute,
      'parameters': parameters,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    String? imageUrl,
    String? targetRoute,
    Map<String, dynamic>? parameters,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      targetRoute: targetRoute ?? this.targetRoute,
      parameters: parameters ?? this.parameters,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}