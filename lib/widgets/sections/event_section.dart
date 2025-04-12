import 'package:flutter/material.dart';
import 'package:neusenews/models/event.dart';
import 'package:intl/intl.dart';

class EventSection extends StatelessWidget {
  final List<Event> events;
  final Function(Event) onEventTapped;
  final Function(Event) onRsvpTapped;
  final VoidCallback onAddEventTapped;

  const EventSection({
    super.key,
    required this.events,
    required this.onEventTapped,
    required this.onRsvpTapped,
    required this.onAddEventTapped,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210, // Adjusted height to match other sections
      child: events.isEmpty ? _buildEmptyState() : _buildEventList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.grey.shade50,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, color: Colors.grey[400], size: 40),
          const SizedBox(height: 12),
          Text(
            'No upcoming events in your area',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAddEventTapped,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('ADD YOUR EVENT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFd2982a),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];

        // Determine if event is happening today
        final isToday = DateUtils.isSameDay(event.eventDate, DateTime.now());

        // Determine if event is happening this week
        final isThisWeek =
            event.eventDate.difference(DateTime.now()).inDays < 7 && !isToday;

        return EventCard(
          event: event,
          isToday: isToday,
          isThisWeek: isThisWeek,
          onTap: () => onEventTapped(event),
          onRsvpTap: () => onRsvpTapped(event),
        );
      },
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  final bool isToday;
  final bool isThisWeek;
  final VoidCallback onTap;
  final VoidCallback onRsvpTap;

  const EventCard({
    super.key,
    required this.event,
    required this.isToday,
    required this.isThisWeek,
    required this.onTap,
    required this.onRsvpTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      clipBehavior: Clip.antiAlias, // This ensures the image doesn't overflow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isToday
                  ? Colors.red
                  : event.isSponsored
                  ? const Color(0xFFd2982a)
                  : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        splashColor: const Color(0xFFd2982a).withOpacity(0.1),
        child: SizedBox(
          width: 220, // Width consistent with news_card_mini
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event image at top
              Stack(
                children: [
                  // Image
                  SizedBox(
                    height: 96,
                    width: double.infinity,
                    child:
                        event.imageUrl != null && event.imageUrl!.isNotEmpty
                            ? Image.network(
                              event.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback image if URL is invalid
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.event,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            )
                            : Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.event,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                  ),

                  // Gradient overlay for text visibility
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Event date badge
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Text(
                      _formatEventDate(event.eventDate),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Sponsored or Today badge
                  if (event.isSponsored || isToday)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isToday ? Colors.red : const Color(0xFFd2982a),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isToday ? 'TODAY' : 'SPONSORED',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Event details
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with ellipsis
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Location
                    if (event.location.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    // Time
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.startTime ??
                              DateFormat('h:mm a').format(event.eventDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Format event date in a readable format
  String _formatEventDate(DateTime date) {
    final today = DateTime.now();
    final tomorrow = DateTime(today.year, today.month, today.day + 1);

    if (DateUtils.isSameDay(date, today)) {
      return 'Today';
    } else if (DateUtils.isSameDay(date, tomorrow)) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM d').format(date); // e.g., "Oct 15"
    }
  }
}
