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

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final Timestamp timestamp = data['eventDate'] as Timestamp;

    return Event(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      location: data['location'] as String,
      startTime: data['startTime'] as String,
      endTime: data.containsKey('endTime') ? data['endTime'] as String : null,
      organizer: data['organizer'] as String,
      isSponsored: data['isSponsored'] as bool,
      eventDate: timestamp.toDate(),
      imageUrl:
          data.containsKey('imageUrl') ? data['imageUrl'] as String : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'startTime': startTime,
      'endTime': endTime,
      'organizer': organizer,
      'isSponsored': isSponsored,
      'eventDate': Timestamp.fromDate(eventDate),
      'imageUrl': imageUrl,
    };
  }
}
