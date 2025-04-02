import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:neusenews/models/article.dart';
import 'package:transparent_image/transparent_image.dart';

class NewsCard extends StatelessWidget {
  final Article article;
  final VoidCallback onReadMore;
  final String? sourceTag; // Add this parameter

  const NewsCard({
    super.key,
    required this.article,
    required this.onReadMore,
    this.sourceTag, // Optional source tag
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Ensures nothing overflows the card
      child: Column(
        children: [
          // Image box with overlaid title
          Stack(
            children: [
              // Featured image
              Hero(
                tag: article.imageUrl,
                child: FadeInImage.memoryNetwork(
                  placeholder: kTransparentImage,
                  image: article.imageUrl,
                  fit: BoxFit.cover,
                  height: 150,
                  width: double.infinity,
                  fadeInDuration: const Duration(milliseconds: 300),
                  imageErrorBuilder:
                      (context, error, stackTrace) => Container(
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
                        Colors.black.withAlpha(
                          204,
                        ), // Changed from withOpacity(0.8)
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Source tag if provided (now on the image)
                      if (sourceTag != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: _getSourceColor(sourceTag!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            sourceTag!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      // Article title on the image
                      Text(
                        article.title,
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
                          _formatDate(article.publishDate),
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
                    Share.share(
                      '${article.title}\n\nRead more: ${article.url}', // Changed from article.link
                      subject: article.title,
                    );
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
                  onPressed: onReadMore,
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

  // Helper method to get a color for each source
  Color _getSourceColor(String source) {
    switch (source) {
      case 'Local News':
        return Colors.blue;
      case 'NC Politics':
        return Colors.red;
      case 'Sports':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
