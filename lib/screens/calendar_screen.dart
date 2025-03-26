import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:news_app/screens/submit_sponsored_event.dart';
import 'package:news_app/models/event.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};
  List<Event> _selectedEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      // Get events from Firestore
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('events')
              .where(
                'eventDate',
                isGreaterThanOrEqualTo: DateTime(
                  _focusedDay.year,
                  _focusedDay.month,
                  1,
                ),
              )
              .where(
                'eventDate',
                isLessThan: DateTime(
                  _focusedDay.year,
                  _focusedDay.month + 1,
                  1,
                ),
              )
              .get();

      final Map<DateTime, List<Event>> events = {};

      // Process the events
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp timestamp = data['eventDate'] as Timestamp;
        final eventDate = timestamp.toDate();

        // Normalize date (remove time component)
        final normalizedDate = DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
        );

        final event = Event(
          id: doc.id,
          title: data['title'] as String,
          description: data['description'] as String,
          location: data['location'] as String,
          startTime: data['startTime'] as String,
          endTime:
              data.containsKey('endTime') ? data['endTime'] as String : null,
          organizer: data['organizer'] as String,
          isSponsored: data['isSponsored'] as bool,
          eventDate: normalizedDate,
          imageUrl:
              data.containsKey('imageUrl') ? data['imageUrl'] as String : null,
        );

        if (events[normalizedDate] != null) {
          events[normalizedDate]!.add(event);
        } else {
          events[normalizedDate] = [event];
        }
      }

      setState(() {
        _events = events;
        _isLoading = false;
        _updateSelectedEvents();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading events: $e')));
    }
  }

  void _updateSelectedEvents() {
    if (_selectedDay != null) {
      final normalizedDate = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
      );
      setState(() {
        _selectedEvents = _events[normalizedDate] ?? [];
      });
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _events[normalizedDate] ?? [];
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFd2982a)),
            onPressed: _loadEvents,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SubmitSponsoredEventScreen(),
            ),
          ).then((_) => _loadEvents()); // Refresh calendar after returning
        },
        backgroundColor: const Color(0xFFd2982a),
        child: const Icon(Icons.add),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFd2982a)),
              )
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        eventLoader: _getEventsForDay,
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDay, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          if (!isSameDay(_selectedDay, selectedDay)) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                              _updateSelectedEvents();
                            });
                          }
                        },
                        onFormatChanged: (format) {
                          if (_calendarFormat != format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          }
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                          _loadEvents(); // Load events for the new month
                        },
                        calendarStyle: const CalendarStyle(
                          // Today's decoration
                          todayDecoration: BoxDecoration(
                            color: Color(0xFFFFE0B2), // Light amber
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: TextStyle(
                            color: Color(0xFF2d2c31),
                            fontWeight: FontWeight.bold,
                          ),

                          // Selected day decoration
                          selectedDecoration: BoxDecoration(
                            color: Color(0xFFd2982a),
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),

                          // Days with events marker
                          markersMaxCount: 3,
                          markerSize: 8.0,
                          markerDecoration: BoxDecoration(
                            color: Color(0xFFd2982a),
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          titleCentered: true,
                          formatButtonVisible: true,
                          formatButtonDecoration: BoxDecoration(
                            color: Color(0xFFFFE0B2),
                            borderRadius: BorderRadius.all(
                              Radius.circular(16.0),
                            ),
                          ),
                          formatButtonTextStyle: TextStyle(
                            color: Color(0xFF2d2c31),
                          ),
                          titleTextStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Show selected date header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDay == null
                              ? 'No Date Selected'
                              : DateFormat(
                                'EEEE, MMMM d, yyyy',
                              ).format(_selectedDay!),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2d2c31),
                          ),
                        ),
                        Text(
                          '${_selectedEvents.length} ${_selectedEvents.length == 1 ? 'Event' : 'Events'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Events list for selected day
                  Expanded(
                    child:
                        _selectedEvents.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No events on this day',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const SubmitSponsoredEventScreen(),
                                        ),
                                      ).then((_) => _loadEvents());
                                    },
                                    icon: const Icon(Icons.add_circle),
                                    label: const Text('Add Event'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFd2982a),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(8.0),
                              itemCount: _selectedEvents.length,
                              itemBuilder: (context, index) {
                                final event = _selectedEvents[index];
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFE0B2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child:
                                          event.imageUrl != null
                                              ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  event.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return const Icon(
                                                      Icons.event,
                                                      color: Color(0xFFd2982a),
                                                      size: 30,
                                                    );
                                                  },
                                                ),
                                              )
                                              : const Icon(
                                                Icons.event,
                                                color: Color(0xFFd2982a),
                                                size: 30,
                                              ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            event.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (event.isSponsored)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFd2982a),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Sponsored',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              event.endTime != null
                                                  ? '${event.startTime} - ${event.endTime}'
                                                  : event.startTime,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                event.location,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.person, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              'By: ${event.organizer}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (event.description.isNotEmpty)
                                          const SizedBox(height: 8),
                                        if (event.description.isNotEmpty)
                                          Text(
                                            event.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                      ],
                                    ),
                                    onTap: () {
                                      _showEventDetailsDialog(event);
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  void _showEventDetailsDialog(Event event) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (event.imageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.network(
                      event.imageUrl!,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          color: const Color(0xFFFFE0B2),
                          child: const Center(
                            child: Icon(
                              Icons.event,
                              size: 60,
                              color: Color(0xFFd2982a),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE0B2),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.event,
                        size: 60,
                        color: Color(0xFFd2982a),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (event.isSponsored)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFd2982a),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Sponsored',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Icons.calendar_today,
                        DateFormat(
                          'EEEE, MMMM d, yyyy',
                        ).format(event.eventDate),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        Icons.access_time,
                        event.endTime != null
                            ? '${event.startTime} - ${event.endTime}'
                            : event.startTime,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.location_on, event.location),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        Icons.business,
                        'Organized by: ${event.organizer}',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description.isNotEmpty
                            ? event.description
                            : 'No description provided.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                OverflowBar(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Color(0xFFd2982a)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Call a method to add event to user's personal calendar
                        _addToPersonalCalendar(event);
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text('Add to My Calendar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFd2982a),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFd2982a)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  void _addToPersonalCalendar(Event event) {
    // This would be implemented with a platform-specific calendar integration
    // For now, just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event added to your calendar'),
        backgroundColor: Color(0xFFd2982a),
      ),
    );
  }
}
