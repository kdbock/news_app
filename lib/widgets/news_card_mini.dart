import 'package:flutter/material.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/widgets/webview_screen.dart';

class NewsCardMini extends StatelessWidget {
  final Article article;
  final VoidCallback? onTap;

  const NewsCardMini({super.key, required this.article, this.onTap});

  void _openArticle(BuildContext context) {
    if (onTap != null) {
      onTap!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  WebViewScreen(url: article.url, title: article.title),
        ),
      );
    }
  }

  String _getFirstSentence(String text) {
    if (text.isEmpty) return '';

    final firstSentence = RegExp(
      r'^(.*?[.!?])\s',
      dotAll: true,
    ).firstMatch(text);
    if (firstSentence != null && firstSentence.group(1) != null) {
      return firstSentence.group(1)!;
    }

    return text.length > 80 ? '${text.substring(0, 80)}...' : text;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        final minutes = difference.inMinutes;
        return '$minutes min ago';
      } else {
        return '${difference.inHours} hr ago';
      }
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstSentence = _getFirstSentence(article.excerpt);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.all(8),
      child: SizedBox(
        width: 220, // Consistent with event card width
        height: 210, // Match the event card height (was 300)
        child: GestureDetector(
          onTap: () => _openArticle(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with gradient and title overlay
              Stack(
                children: [
                  // Image with consistent height
                  SizedBox(
                    height: 96, // Same image height as event cards
                    width: double.infinity,
                    child: Image.network(
                      article.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                    ),
                  ),

                  // Darker gradient overlay
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

                  // Title text
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Content area (reduced height to match event cards)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(
                    10.0,
                  ), // Slightly reduced padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author and date (smaller text to fit)
                      Text(
                        '${article.author} • ${_formatDate(article.publishDate)}',
                        style: const TextStyle(
                          fontSize: 10.0, // Reduced from 12
                          fontStyle: FontStyle.italic,
                          color: Color(0xFFd2982a), // Theme gold
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4), // Reduced from 8
                      // Excerpt text with limited lines
                      Expanded(
                        child: Text(
                          firstSentence,
                          style: TextStyle(
                            fontSize: 12.0, // Reduced from 14
                            color: Colors.grey[800],
                            height: 1.2,
                          ),
                          maxLines: 3, // Limit to 3 lines to ensure it fits
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
