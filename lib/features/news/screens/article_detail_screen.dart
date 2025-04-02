import 'package:flutter/material.dart';
import 'package:neusenews/models/article.dart';
import 'package:intl/intl.dart';
import 'package:neusenews/widgets/webview_screen.dart';
import 'package:share_plus/share_plus.dart';

class ArticleDetailScreen extends StatelessWidget {
  const ArticleDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final article = ModalRoute.of(context)!.settings.arguments as Article;
    final formattedContent = article.formattedContent;
    // Create paragraphs from the formatted content
    final paragraphs = formattedContent.split('\n\n');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          article.title,
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
        actions: [
          // Share button
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFFd2982a)),
            onPressed: () {
              Share.share(
                '${article.title}\n\nRead more: ${article.url}', // Changed from article.link
                subject: article.title,
              );
            },
          ),
          // Open in browser button
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Color(0xFFd2982a)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => WebViewScreen(
                        url: article.url, // Changed from article.link
                        title: article.title,
                      ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured image
            Hero(
              tag: 'article-${article.url}', // Changed from article.link
              child: Image.network(
                article.imageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Image.asset(
                      'assets/images/Default.jpeg',
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Article title
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2d2c31),
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Author and date
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${article.author} • ${DateFormat('MMMM d, yyyy').format(article.publishDate)}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // Article content in paragraphs
                  ...paragraphs.map(
                    (paragraph) => Column(
                      children: [
                        Text(
                          paragraph,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6, // Line height for better readability
                            color: Color(0xFF2d2c31),
                          ),
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 16), // Space between paragraphs
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // "Read article on website" button (full width)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => WebViewScreen(
                                  url: article.url, // Changed from article.link
                                  title: article.title,
                                ),
                          ),
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
                        'READ ARTICLE ON WEBSITE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
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
