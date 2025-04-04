import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:neusenews/models/article.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class NewsCard extends StatefulWidget {
  final Article article;
  final Function() onReadMore;
  final String? sourceTag;

  const NewsCard({
    super.key,
    required this.article,
    required this.onReadMore,
    this.sourceTag,
  });

  @override
  _NewsCardState createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'News article about ${widget.article.title}',
      hint: 'Double tap to read the full article',
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Image box with overlaid title
            Stack(
              children: [
                // Featured image
                Hero(
                  tag:
                      "${widget.article.category ?? 'news'}_${widget.article.url.hashCode}_image",
                  child: CachedNetworkImage(
                    imageUrl: widget.article.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    memCacheWidth: 800, // Optimize for device resolution
                    memCacheHeight: 400,
                    fadeInDuration: const Duration(milliseconds: 300),
                    placeholder:
                        (context, url) => Container(
                          height: 150,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          height: 150,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, size: 40),
                        ),
                  ),
                ),

                // Title overlay (covers bottom half of image)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withAlpha(204),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Article title on the image
                        Text(
                          widget.article.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Publication date
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _formatDate(widget.article.publishDate),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Actions row at the bottom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Share button
                  TextButton.icon(
                    onPressed: () {
                      try {
                        Share.share(
                          '${widget.article.title}\n\nRead more: ${widget.article.url}',
                          subject: widget.article.title,
                        );
                      } catch (e) {
                        debugPrint('Error: $e');
                        // Show user-friendly error message
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Something went wrong. Please try again later.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: EdgeInsets.zero,
                    ),
                  ),

                  // Read More button
                  TextButton(
                    onPressed: () {
                      try {
                        _trackArticleOpen(widget.article);
                        widget.onReadMore();
                      } catch (e) {
                        debugPrint('Error: $e');
                        // Show user-friendly error message
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Something went wrong. Please try again later.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFd2982a),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('READ MORE'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to format the date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hr ago';
    } else if (difference.inDays <= 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }

    final month =
        [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ][date.month - 1];

    return '$month ${date.day}';
  }

  // Add to NewsCard's _openArticle or onReadMore handler:
  void _trackArticleOpen(Article article) {
    try {
      FirebaseAnalytics.instance.logSelectContent(
        contentType: 'article',
        itemId: article.guid ?? article.url,
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong. Please try again later.'),
          ),
        );
      }
    }
  }
}
