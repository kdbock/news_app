import 'package:flutter/material.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/widgets/components/section_header.dart';

class DashboardSponsoredArticleWidget extends StatelessWidget {
  final List<Article> articles;
  final Function(Article) onArticleTapped;
  final VoidCallback onSeeAllPressed;

  const DashboardSponsoredArticleWidget({
    super.key,
    required this.articles,
    required this.onArticleTapped,
    required this.onSeeAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Sponsored', onSeeAllPressed: onSeeAllPressed),
        const SizedBox(height: 8),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return _buildSponsoredArticleCard(context, article);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSponsoredArticleCard(BuildContext context, Article article) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFd2982a), // Gold border for sponsored articles
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => onArticleTapped(article),
        child: SizedBox(
          width: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Article image section
              article.imageUrl.isNotEmpty
                  ? Image.network(
                    article.imageUrl,
                    height: 96,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                  : Container(height: 96, color: Colors.grey[300]),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  article.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d2c31), // Dark gray titles
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
