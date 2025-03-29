import 'package:flutter/material.dart';
import 'dart:async';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:neusenews/screens/submit_sponsored_event.dart';
import 'package:neusenews/models/event.dart';
import 'package:neusenews/services/event_service.dart';

class CalendarScreen extends StatefulWidget {
  // Add parameter for selected date
  final DateTime? selectedDate;

  const CalendarScreen({super.key, this.selectedDate});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Add EventService
  final EventService _eventService = EventService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};
  List<Event> _selectedEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize focused day with widget's selectedDate if provided
    _focusedDay = widget.selectedDate ?? DateTime.now();
    _selectedDay = _focusedDay;

    // Load events with error handling during initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents().catchError((error) {
        debugPrint('Error during initial event loading: $error');
        // Show a message to the user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load events: $error'),
              action: SnackBarAction(label: 'RETRY', onPressed: _loadEvents),
            ),
          );
        }
      });
    });
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      debugPrint(
        'Fetching events for ${_focusedDay.year}-${_focusedDay.month}',
      );

      // Use EventService to get events for the month
      final eventMap = await _eventService.getEventsForMonth(_focusedDay);

      if (mounted) {
        setState(() {
          _events = eventMap;
          _isLoading = false;
          _updateSelectedEvents();
        });

        debugPrint(
          'Calendar updated with ${eventMap.length} days containing events',
        );
      }
    } catch (e) {
      debugPrint('Error loading events: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading events: $e'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: 'RETRY', onPressed: _loadEvents),
          ),
        );
      }
    }
  }

  void _updateSelectedEvents() {
    if (_selectedDay != null) {
      final selectedDate = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
      );

      setState(() {
        _selectedEvents = _events[selectedDate] ?? [];
      });
    }
  }

  // Add this method to test your Firebase connection
  void _testFirebaseConnection() async {
    try {
      debugPrint('Testing Firebase connection...');
      // Try to get just one document to test connection
      final testQuery = await FirebaseFirestore.instance
          .collection('events')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));

      debugPrint(
        'Firebase connection successful. Got ${testQuery.docs.length} documents.',
      );

      // Show connection status
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firebase connection successful')),
        );
      }
    } catch (e) {
      debugPrint('Firebase connection test failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase connection failed: $e')),
        );
      }
    }
  }

  // Add a method to create a test event
  void _addTestEvent() async {
    try {
      await _eventService.addTestEvent();
      // Clear EventService cache to ensure fresh data
      _eventService.clearCache();
      // Reload events
      await _loadEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test event created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating test event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating test event: $e')),
        );
      }
    }
  }

  // Add this method to your _CalendarScreenState class

  void _checkDatabaseStructure() async {
    try {
      debugPrint('Checking Firebase database structure...');

      // List all collections in the root of the database
      final FirebaseFirestore db = FirebaseFirestore.instance;

      // Try to access the events collection
      final eventsCollection = await db.collection('events').get();

      debugPrint(
        'Events collection exists: ${eventsCollection.docs.isNotEmpty}',
      );
      debugPrint(
        'Events collection contains ${eventsCollection.size} documents.',
      );

      // If there are documents, check the structure of the first one
      if (eventsCollection.docs.isNotEmpty) {
        final sampleDoc = eventsCollection.docs.first;
        final data = sampleDoc.data();

        debugPrint('Sample document ID: ${sampleDoc.id}');
        debugPrint('Sample document fields:');

        data.forEach((key, value) {
          final valueType = value.runtimeType.toString();
          final valueString =
              (value is Timestamp)
                  ? 'Timestamp(${value.toDate()})'
                  : value.toString();

          debugPrint('- $key: $valueString (Type: $valueType)');
        });

        // Check for required fields
        final requiredFields = [
          'title',
          'description',
          'location',
          'startTime',
          'eventDate',
          'organizer',
          'isSponsored',
        ];

        for (final field in requiredFields) {
          debugPrint('Has "$field": ${data.containsKey(field)}');
        }
      }

      // Show a summary in the UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Database check complete. Found ${eventsCollection.size} events.',
            ),
            action: SnackBarAction(
              label: 'DETAILS',
              onPressed: () => _showDatabaseReport(eventsCollection.docs),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking database structure: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Database check failed: $e')));
      }
    }
  }

  void _showDatabaseReport(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Database Structure Report'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text('Found ${docs.length} events in the database.'),
                  const Divider(),
                  if (docs.isEmpty)
                    const Text(
                      'No events found in database. Try adding one first.',
                    )
                  else
                    ...docs.map((doc) {
                      final data = doc.data();
                      return ExpansionTile(
                        title: Text(data['title'] as String? ?? 'Untitled'),
                        subtitle: Text('ID: ${doc.id}'),
                        children:
                            data.entries.map<Widget>((entry) {
                              String valueText = entry.value.toString();
                              if (entry.value is Timestamp) {
                                valueText =
                                    (entry.value as Timestamp)
                                        .toDate()
                                        .toString();
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '${entry.key}: ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(child: Text(valueText)),
                                  ],
                                ),
                              );
                            }).toList(),
                      );
                    }),
                ],
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFd2982a),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CLOSE'),
              ),
            ],
          ),
    );
  }

  // Implement the rest of your calendar screen here...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Community Calendar',
          style: TextStyle(
            color: Color(0xFF2d2c31),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        // Remove all the debugging icons
        actions: [
          // Keep only the refresh button with a more appropriate icon
          IconButton(
            icon: const Icon(Icons.event_available, color: Color(0xFFd2982a)),
            onPressed: _loadEvents,
            tooltip: 'Refresh Calendar',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFd2982a)),
              )
              : Column(
                children: [
                  // Keep the rest of your calendar UI unchanged
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,

                    // Event loader
                    eventLoader: (day) {
                      final normalizedDate = DateTime(
                        day.year,
                        day.month,
                        day.day,
                      );
                      return _events[normalizedDate] ?? [];
                    },

                    // Selection
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                        _updateSelectedEvents();
                      });
                    },

                    // Format and page changes
                    onFormatChanged:
                        (format) => setState(() => _calendarFormat = format),
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                      _loadEvents();
                    },

                    // Calendar styling to match app theme
                    calendarStyle: const CalendarStyle(
                      // Selected day
                      selectedDecoration: BoxDecoration(
                        color: Color(0xFFd2982a),
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: TextStyle(color: Colors.white),

                      // Today
                      todayDecoration: BoxDecoration(
                        color: Color(0x55d2982a), // semi-transparent gold
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(color: Color(0xFF2d2c31)),

                      // Default day
                      defaultTextStyle: TextStyle(color: Color(0xFF2d2c31)),

                      // Weekend
                      weekendTextStyle: TextStyle(color: Color(0xFF555555)),

                      // Markers (dots for events)
                      markersMaxCount: 3,
                      markerDecoration: BoxDecoration(
                        color: Color(0xFFd2982a),
                        shape: BoxShape.circle,
                      ),
                      markerSize: 6.0,
                      markerMargin: EdgeInsets.symmetric(horizontal: 0.5),

                      // Outside days
                      outsideTextStyle: TextStyle(color: Colors.grey),

                      // Cell margins
                      cellMargin: EdgeInsets.all(6.0),
                    ),

                    // Header styling
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: true,
                      formatButtonDecoration: BoxDecoration(
                        color: Color(0x22d2982a), // very light gold
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                      ),
                      formatButtonTextStyle: TextStyle(
                        color: Color(0xFF2d2c31),
                      ),
                      titleTextStyle: TextStyle(
                        color: Color(0xFF2d2c31),
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: Color(0xFFd2982a),
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: Color(0xFFd2982a),
                      ),
                    ),

                    // Calendar builders for more customization if needed
                    calendarBuilders: CalendarBuilders(
                      // Makes the current day marker more prominent
                      todayBuilder: (context, date, _) {
                        return Container(
                          margin: const EdgeInsets.all(4.0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                date.day == DateTime.now().day
                                    ? const Color(0x33d2982a)
                                    : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFd2982a),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(
                              color: Color(0xFF2d2c31),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                      // Customize the marker appearance
                      markerBuilder: (context, date, events) {
                        if (events.isEmpty) return const SizedBox.shrink();

                        return Positioned(
                          bottom: 1,
                          child: Container(
                            height: 6,
                            width: events.length > 2 ? 18 : events.length * 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFFd2982a),
                              borderRadius: BorderRadius.circular(3.0),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child:
                        _selectedEvents.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.event_busy,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No events scheduled for ${DateFormat('MMMM d, yyyy').format(_selectedDay!)}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: _selectedEvents.length,
                              itemBuilder: (context, index) {
                                final event = _selectedEvents[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 4.0,
                                  ),
                                  child: ListTile(
                                    leading:
                                        event.isSponsored
                                            ? const Icon(
                                              Icons.star,
                                              color: Color(0xFFd2982a),
                                            )
                                            : const Icon(Icons.event),
                                    title: Text(
                                      event.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${event.startTime}${event.endTime != null ? ' - ${event.endTime}' : ''}\n${event.location}',
                                    ),
                                    trailing:
                                        event.isSponsored
                                            ? const Text(
                                              'SPONSORED',
                                              style: TextStyle(
                                                color: Color(0xFFd2982a),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            )
                                            : null,
                                    isThreeLine: true,
                                    onTap: () {
                                      // Show event details
                                      _showEventDetails(event);
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFd2982a),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubmitSponsoredEventScreen(),
            ),
          ).then((_) => _loadEvents());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEventDetails(Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (event.imageUrl != null)
                        Container(
                          width: double.infinity,
                          height: 200,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              event.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          if (event.isSponsored)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFd2982a),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'SPONSORED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat(
                              'EEEE, MMMM d, yyyy',
                            ).format(event.eventDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            event.endTime != null
                                ? '${event.startTime} - ${event.endTime}'
                                : event.startTime,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.location,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Organized by: ${event.organizer}',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFd2982a),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}
