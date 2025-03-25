import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:news_app/models/article.dart';
import 'package:news_app/screens/web_view_screen.dart';
import 'package:news_app/screens/article_detail_screen.dart';

class NewsCard extends StatelessWidget {
  final Article article;
  final Function()? onReadMore;

  const NewsCard({super.key, required this.article, this.onReadMore});

  void _shareArticle(Article article) {
    Share.share(
      '${article.title}\n\nRead more: ${article.link}',
      subject: article.title,
    );
  }

  // Modified to use BuildContext parameter
  void _openArticle(BuildContext context) async {
    if (onReadMore != null) {
      onReadMore!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  WebViewScreen(url: article.link, title: article.title),
        ),
      );
    }
  }

  // Removed unused _onArticleTap method

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () => _openArticle(context), // Pass context here
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          children: [
            // Main content row - thumbnail on left, text on right
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail image on left
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: InkWell(
                      onTap: () => _openArticle(context), // Pass context here
                      child: CachedNetworkImage(
                        imageUrl: article.imageUrl,
                        height: 90,
                        width: 90,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Image.asset(
                              'assets/images/Default.jpeg',
                              height: 90,
                              width: 90,
                              fit: BoxFit.cover,
                            ),
                        errorWidget:
                            (context, url, error) => Image.asset(
                              'assets/images/Default.jpeg',
                              height: 90,
                              width: 90,
                              fit: BoxFit.cover,
                            ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12.0), // Spacing between image and text
                  // Content column on right
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title (clickable)
                        InkWell(
                          onTap:
                              () => _openArticle(context), // Pass context here
                          child: Text(
                            article.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2d2c31),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(height: 4.0),

                        // Author and date
                        Text(
                          '${article.author} • ${DateFormat('MMM d, y').format(article.publishDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 4.0),

                        // Excerpt
                        Text(
                          article.excerpt,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Divider between content and actions
            const Divider(height: 1),

            // Actions row at bottom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Share button
                  IconButton(
                    icon: const Icon(
                      Icons.share,
                      color: Color(0xFFd2982a),
                      size: 20,
                    ),
                    onPressed: () => _shareArticle(article),
                  ),

                  // Read more button
                  TextButton(
                    onPressed: () => _openArticle(context), // Pass context here
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFd2982a),
                    ),
                    child: const Text(
                      "Read More",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
