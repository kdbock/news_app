import 'package:flutter/material.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/widgets/news_card_mini.dart';

class NewsSection extends StatelessWidget {
  final List<Article> articles;
  final Function(Article) onArticleTapped;
  final String categoryKey;

  const NewsSection({
    super.key,
    required this.articles,
    required this.onArticleTapped,
    required this.categoryKey,
  });

  @override
  Widget build(BuildContext context) {
    // Return early if no articles
    if (articles.isEmpty) {
      return const SizedBox(
        height: 210, // Match event section height
        child: Center(child: Text('No news available')),
      );
    }

    return SizedBox(
      height: 210, // Match event section height (was 200)
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];

          return SizedBox(
            width: 220, // Fixed width to match event cards
            child: NewsCardMini(
              article: article,
              onTap: () => onArticleTapped(article),
            ),
          );
        },
      ),
    );
  }
}

class NewsArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const NewsArticleCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Stack(
        children: [
          NewsCardMini(article: article, onTap: onTap),
          if (article.isSponsored)
            Positioned(top: 8, right: 8, child: _buildSponsoredBadge()),
        ],
      ),
    );
  }

  Widget _buildSponsoredBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFd2982a),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'SPONSORED',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
