import 'package:flutter/material.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/widgets/news_card.dart';
import 'package:neusenews/utils/responsive_layout.dart';

class NewsGridSection extends StatelessWidget {
  final List<Article> articles;
  final Function(Article) onArticleTapped;
  final String sourceTag;
  final int maxItems;

  const NewsGridSection({
    super.key,
    required this.articles,
    required this.onArticleTapped,
    required this.sourceTag,
    this.maxItems = 25,
  });

  @override
  Widget build(BuildContext context) {
    final clampedCount = articles.length.clamp(0, maxItems);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.getGridColumnCount(context),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: clampedCount,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => onArticleTapped(articles[index]),
          child: NewsCard(
            article: articles[index],
            onReadMore: () => onArticleTapped(articles[index]),
            sourceTag: sourceTag,
          ),
        );
      },
    );
  }
}
