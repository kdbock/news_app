import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:neusenews/models/event.dart';

class EventService {
  // Singleton pattern to ensure only one instance exists
  static final EventService _instance = EventService._internal();

  factory EventService() => _instance;

  EventService._internal();

  // Cache of events to avoid repeated loading
  List<Event> _cachedEvents = [];
  DateTime _lastFetchTime = DateTime(2000); // Initialize to old date

  // Get the Firestore collection reference
  final CollectionReference _eventsCollection = FirebaseFirestore.instance
      .collection('events');

  /// Get upcoming events, optionally filtering by month
  Future<List<Event>> getUpcomingEvents({
    DateTime? focusDate,
    int limit = 10,
  }) async {
    try {
      // If cached events are recent (less than 5 minutes old), return them
      final now = DateTime.now();
      if (_cachedEvents.isNotEmpty &&
          now.difference(_lastFetchTime).inMinutes < 5 &&
          focusDate == null) {
        debugPrint('Returning ${_cachedEvents.length} cached events');
        return _cachedEvents;
      }

      // Get current date at midnight
      final today = DateTime(now.year, now.month, now.day);

      // Create base query
      Query query = _eventsCollection
          .where(
            'eventDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()),
          )
          .orderBy('eventDate');

      // If we're filtering for a specific month
      if (focusDate != null) {
        final monthStart = DateTime(focusDate.year, focusDate.month, 1);
        final monthEnd =
            (focusDate.month < 12)
                ? DateTime(focusDate.year, focusDate.month + 1, 1)
                : DateTime(focusDate.year + 1, 1, 1);

        query = _eventsCollection
            .where(
              'eventDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
            )
            .where('eventDate', isLessThan: Timestamp.fromDate(monthEnd))
            .orderBy('eventDate');
      } else {
        // Apply limit for dashboard views
        query = query.limit(limit);
      }

      // Execute query
      final QuerySnapshot snapshot = await query.get();
      debugPrint('Fetched ${snapshot.docs.length} events from Firestore');

      // Process results
      final List<Event> events = [];
      for (final doc in snapshot.docs) {
        try {
          final event = Event.fromFirestore(doc);
          events.add(event);
        } catch (e) {
          debugPrint('Error processing event ${doc.id}: $e');
        }
      }

      // Cache results if not month-specific
      if (focusDate == null) {
        _cachedEvents = events;
        _lastFetchTime = now;
      }

      return events;
    } catch (e) {
      debugPrint('Error loading upcoming events: $e');
      return [];
    }
  }

  /// Get events for a specific date
  Future<List<Event>> getEventsForDate(DateTime date) async {
    try {
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final QuerySnapshot snapshot =
          await _eventsCollection
              .where(
                'eventDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart),
              )
              .where('eventDate', isLessThan: Timestamp.fromDate(dayEnd))
              .get();

      return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error loading events for date $date: $e');
      return [];
    }
  }

  /// Get events for a specific month
  Future<Map<DateTime, List<Event>>> getEventsForMonth(DateTime month) async {
    final events = await getUpcomingEvents(focusDate: month);

    // Group events by date
    final Map<DateTime, List<Event>> eventMap = {};
    for (final event in events) {
      // Normalize date (remove time component)
      final normalizedDate = DateTime(
        event.eventDate.year,
        event.eventDate.month,
        event.eventDate.day,
      );

      if (eventMap[normalizedDate] != null) {
        eventMap[normalizedDate]!.add(event);
      } else {
        eventMap[normalizedDate] = [event];
      }
    }

    return eventMap;
  }

  /// Add a test event to the database
  Future<void> addTestEvent() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await _eventsCollection.add({
        'title': 'Test Event ${now.hour}:${now.minute}',
        'description': 'This is a test event created for debugging purposes',
        'location': 'Kinston, NC',
        'startTime': '10:00 AM',
        'endTime': '11:00 AM',
        'organizer': 'Calendar Debug Tool',
        'isSponsored': false,
        'eventDate': Timestamp.fromDate(today),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear cache to ensure the new event is loaded next time
      _cachedEvents = [];

      debugPrint('Test event created successfully');
    } catch (e) {
      debugPrint('Error creating test event: $e');
      rethrow;
    }
  }

  /// Clear the cached events to force a reload
  void clearCache() {
    _cachedEvents = [];
    _lastFetchTime = DateTime(2000);
  }

  /// Get sponsored events
  Future<List<Event>> getSponsoredEvents({int limit = 10}) async {
    try {
      // Get current date at midnight
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Query for sponsored events
      final QuerySnapshot snapshot =
          await _eventsCollection
              .where('isSponsored', isEqualTo: true)
              .where(
                'eventDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(today),
              )
              .orderBy('eventDate')
              .limit(limit)
              .get();

      debugPrint(
        'Fetched ${snapshot.docs.length} sponsored events from Firestore',
      );

      // Process results
      final List<Event> events = [];
      for (final doc in snapshot.docs) {
        try {
          final event = Event.fromFirestore(doc);
          events.add(event);
        } catch (e) {
          debugPrint('Error processing sponsored event ${doc.id}: $e');
        }
      }

      return events;
    } catch (e) {
      debugPrint('Error loading sponsored events: $e');
      return [];
    }
  }
}
