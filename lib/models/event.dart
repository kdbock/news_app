import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final String startTime;
  final String? endTime;
  final String organizer;
  final bool isSponsored;
  final DateTime eventDate;
  final String? imageUrl;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    this.endTime,
    required this.organizer,
    required this.isSponsored,
    required this.eventDate,
    this.imageUrl,
  });

  @override
  String toString() => title;

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Safely convert Timestamp to DateTime
    DateTime eventDate;
    if (data['eventDate'] is Timestamp) {
      eventDate = (data['eventDate'] as Timestamp).toDate();
    } else {
      // Fallback if eventDate is missing or not a timestamp
      eventDate = DateTime.now();
    }

    return Event(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled Event',
      description: data['description'] as String? ?? 'No description provided',
      location: data['location'] as String? ?? 'Location not specified',
      startTime: data['startTime'] as String? ?? 'TBD',
      endTime: data['endTime'] as String?,
      organizer: data['organizer'] as String? ?? 'Community Member',
      isSponsored: data['isSponsored'] as bool? ?? false,
      eventDate: eventDate,
      imageUrl: data['imageUrl'] as String?,
    );
  }
}
