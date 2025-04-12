import 'package:flutter/material.dart';
import 'package:neusenews/models/event.dart';
import 'package:intl/intl.dart';
import 'package:neusenews/providers/news_provider.dart';
import 'package:neusenews/models/article.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  List<Article> _relatedArticles = [];
  bool _isLoadingRelated = true;

  @override
  void initState() {
    super.initState();

    // Load related articles after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRelatedArticles();
    });
  }

  Future<void> _loadRelatedArticles() async {
    if (!mounted) return;

    setState(() {
      _isLoadingRelated = true;
    });

    try {
      final event = ModalRoute.of(context)!.settings.arguments as Event;
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);

      // Get articles that might be related to this event's location or title
      // This is a simple implementation - you might want to improve this logic
      final articles =
          newsProvider.localNews
              .where((article) {
                return article.title.contains(event.location) ||
                    article.content.contains(event.title);
              })
              .take(3)
              .toList();

      if (mounted) {
        setState(() {
          _relatedArticles = articles;
          _isLoadingRelated = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRelated = false;
        });
        debugPrint('Error loading related articles: $e');
      }
    }
  }

  void _shareEvent(Event event) async {
    final String shareText =
        '${event.title}\n'
        'Date: ${DateFormat('MMMM d, yyyy').format(event.eventDate)}\n'
        'Time: ${event.startTime}\n'
        'Location: ${event.location}\n'
        'Organized by: ${event.organizer}';

    await Share.share(shareText, subject: event.title);
  }

  @override
  Widget build(BuildContext context) {
    final event = ModalRoute.of(context)!.settings.arguments as Event;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareEvent(event),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image
            if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 200,
                child: Image.network(
                  event.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.event,
                            size: 64,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                ),
              )
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: Center(
                  child: Icon(Icons.event, size: 64, color: Colors.grey[400]),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2d2c31),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Organizer information
                  Row(
                    children: [
                      const Icon(Icons.business, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        event.organizer,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2d2c31),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Date and time
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat(
                          'EEEE, MMMM d, yyyy',
                        ).format(event.eventDate),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2d2c31),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Time
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.startTime +
                            (event.endTime != null
                                ? ' - ${event.endTime}'
                                : ''),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2d2c31),
                        ),
                      ),
                    ],
                  ),

                  // Location
                  if (event.location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2d2c31),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const Divider(height: 32),

                  // Description
                  const Text(
                    'About this Event',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2d2c31),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Color(0xFF2d2c31),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // RSVP button if applicable
                  if (!event.isSponsored)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // RSVP functionality here
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('RSVP Successful!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFd2982a),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'RSVP TO THIS EVENT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                  // Related articles section
                  if (_relatedArticles.isNotEmpty || _isLoadingRelated) ...[
                    const Divider(height: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'Related Articles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2d2c31),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_isLoadingRelated)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: CircularProgressIndicator(
                            color: Color(0xFFd2982a),
                          ),
                        ),
                      )
                    else
                      ..._relatedArticles
                          .map(_buildRelatedArticleItem)
                          ,
                  ],

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedArticleItem(Article article) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/article', arguments: article);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 60,
                child:
                    article.imageUrl.isNotEmpty
                        ? Image.network(
                          article.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.article,
                                  color: Colors.white70,
                                ),
                              ),
                        )
                        : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.article,
                            color: Colors.white70,
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 12),

            // Article title and date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(article.publishDate),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
