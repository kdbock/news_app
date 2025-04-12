import 'package:flutter/foundation.dart';
import 'package:neusenews/models/event.dart';
import 'package:neusenews/services/event_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventsProvider extends ChangeNotifier {
  final EventService _eventService;

  EventsProvider({required EventService eventService})
    : _eventService = eventService;

  List<Event> _upcomingEvents = [];
  List<Event> _sponsoredEvents = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Event> get upcomingEvents => _upcomingEvents;
  List<Event> get sponsoredEvents => _sponsoredEvents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all events (both upcoming and sponsored)
  Future<void> loadEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load sponsored events from Firebase
      QuerySnapshot sponsoredSnapshot =
          await FirebaseFirestore.instance
              .collection('events')
              .where('isSponsored', isEqualTo: true)
              .orderBy('startDate')
              .limit(10)
              .get();
      _sponsoredEvents =
          sponsoredSnapshot.docs
              .map((doc) => Event.fromFirestore(doc))
              .toList();

      // Load upcoming events
      QuerySnapshot upcomingSnapshot =
          await FirebaseFirestore.instance
              .collection('events')
              .where( 'eventDate', isGreaterThan: Timestamp.fromDate(DateTime.now()), )


              .orderBy('eventDate')
              .limit(25)
              .get();
      _upcomingEvents =
          upcomingSnapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();

      debugPrint(
        'Events loaded successfully. Sponsored: ${_sponsoredEvents.length}, Upcoming: ${_upcomingEvents.length}',
      );
    } catch (e) {
      debugPrint('Error loading events: $e');
      _errorMessage = 'Failed to load events';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load upcoming events
  Future<void> loadUpcomingEvents({bool notify = true}) async {
    if (notify) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _upcomingEvents = await _eventService.getUpcomingEvents();
    } catch (e) {
      debugPrint('Error loading upcoming events: $e');
      _errorMessage = 'Failed to load upcoming events';
    } finally {
      if (notify) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Load sponsored events
  Future<void> loadSponsoredEvents({bool notify = true}) async {
    if (notify) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _sponsoredEvents = await _eventService.getSponsoredEvents();
    } catch (e) {
      debugPrint('Error loading sponsored events: $e');
      _errorMessage = 'Failed to load sponsored events';
    } finally {
      if (notify) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
