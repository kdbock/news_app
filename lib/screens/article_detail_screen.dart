import 'package:flutter/material.dart';
import 'package:news_app/models/article.dart';
import 'package:intl/intl.dart';
import 'package:news_app/screens/web_view_screen.dart';

class ArticleDetailScreen extends StatelessWidget {
  // Constructor must match exactly
  const ArticleDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final article = ModalRoute.of(context)!.settings.arguments as Article;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          article.title,
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              article.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Image.asset(
                    'assets/images/Default.jpeg',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${article.author} • ${DateFormat('MMM d, y').format(article.publishDate)}",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Text(article.excerpt),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => WebViewScreen(
                                url: article.link,
                                title: article.title,
                              ),
                        ),
                      );
                    },
                    child: const Text("Read Full Article"),
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
