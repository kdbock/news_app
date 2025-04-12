import 'package:flutter/material.dart';
import 'package:neusenews/models/event.dart';
import 'package:intl/intl.dart';
import 'package:neusenews/widgets/components/section_header.dart';

class DashboardEventWidget extends StatelessWidget {
  final List<Event> events;
  final Function(Event) onEventTapped;
  final Function(Event) onRsvpTapped;
  final VoidCallback onAddEventTapped;

  const DashboardEventWidget({
    super.key,
    required this.events,
    required this.onEventTapped,
    required this.onRsvpTapped,
    required this.onAddEventTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Events', onSeeAllPressed: onAddEventTapped),
        const SizedBox(height: 8),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isToday = DateUtils.isSameDay(
                event.eventDate,
                DateTime.now(),
              );
              // Define “isThisWeek” if needed
              final isThisWeek =
                  !isToday &&
                  event.eventDate.difference(DateTime.now()).inDays < 7;
              return _buildEventCard(context, event, isToday, isThisWeek);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    Event event,
    bool isToday,
    bool isThisWeek,
  ) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
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
        onTap: () => onEventTapped(event),
        splashColor: const Color(0xFFd2982a).withOpacity(0.1),
        child: SizedBox(
          width: 220, // Consistent with your mini card width
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event image section
              Stack(
                children: [
                  SizedBox(
                    height: 96,
                    width: double.infinity,
                    child:
                        (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                            ? Image.network(event.imageUrl!, fit: BoxFit.cover)
                            : Container(color: Colors.grey[300]),
                  ),
                  // Gradient overlay for text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Sponsored/Today badge
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
                          color:
                              event.isSponsored
                                  ? const Color(0xFFd2982a)
                                  : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.isSponsored ? 'Sponsored' : 'Today',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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
                    // Event title
                    Text(
                      event.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Event location, if provided
                    if (event.location.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    // Event start time
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.startTime,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
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

  String _formatEventDate(DateTime date) {
    final today = DateTime.now();
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    if (DateUtils.isSameDay(date, today)) {
      return 'Today';
    } else if (DateUtils.isSameDay(date, tomorrow)) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}
