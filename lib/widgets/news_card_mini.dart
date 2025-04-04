import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/widgets/webview_screen.dart';
import 'package:intl/intl.dart'; // Keep this for date formatting
import 'package:neusenews/constants/layout_constants.dart';

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

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Article: ${article.title}',
      hint: 'Double tap to read article',
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 2.0,
        child: InkWell(
          onTap: () => _openArticle(context),
          child: SizedBox(
            width: 160, // Fixed width for card
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Image - centered, fixed size
                SizedBox(
                  height: 120,
                  width: 160,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl:
                          article
                              .imageUrl, // Remove null check - it's not nullable
                      height: 120,
                      width: 160,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFd2982a),
                                strokeWidth: 2.0,
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Image.asset(
                            'assets/images/Default.jpeg',
                            height: 120,
                            width: 160,
                            fit: BoxFit.cover,
                          ),
                    ),
                  ),
                ),

                // Title in fixed height container
                Container(
                  height: 60,
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        article.title, // Remove null check - it's not nullable
                        style: const TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2d2c31),
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const ArticleCard({super.key, required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: LayoutConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LayoutConstants.cardBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero, // Container provides margin
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 2.0,
              ),
              color: Colors.grey[200],
              child: Row(
                children: [
                  Text(
                    article.category?.toUpperCase() ?? 'NEWS',
                    style: TextStyle(
                      fontSize: 10.0,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(article.publishDate),
                    style: const TextStyle(fontSize: 10.0, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Article image
            Expanded(
              flex: 3,
              child: CachedNetworkImage(
                imageUrl: article.imageUrl ?? '',
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 40),
                    ),
              ),
            ),

            // Article text
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title ?? 'Untitled Article',
                      style: LayoutConstants.headlineStyle,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2.0),
                    Expanded(
                      child: Text(
                        article.description ?? '',
                        style: LayoutConstants.bodyTextStyle,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date != null) {
      // Your existing date formatting logic
      return DateFormat('yMMMd').format(date); // Example formatting
    }
    return 'Unknown Date'; // Default return value for null dates
  }
}
