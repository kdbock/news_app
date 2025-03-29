import 'package:flutter/material.dart';
import 'package:neusenews/services/news_service.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/widgets/news_card.dart';

class CategoryScreen extends StatefulWidget {
  final String category;
  final String url;
  final Color categoryColor;

  const CategoryScreen({
    super.key,
    required this.category,
    required this.url,
    required this.categoryColor,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final NewsService _newsService = NewsService();
  List<Article> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);

    try {
      final articles = await _newsService.fetchNewsByUrl(widget.url);

      if (mounted) {
        setState(() {
          _articles = articles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ${widget.category}: $e')),
        );
      }
    }
  }

  void _onArticleTap(Article article) {
    // Navigate to article detail page
    Navigator.pushNamed(context, '/article', arguments: article);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category,
          style: const TextStyle(
            color: Color(0xFF2d2c31),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFFd2982a)),
        elevation: 1,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFd2982a)),
              )
              : RefreshIndicator(
                onRefresh: _loadArticles,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      color: widget.categoryColor.withOpacity(0.1),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: widget.categoryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_articles.length} articles in ${widget.category}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Article list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8.0),
                        itemCount: _articles.length,
                        itemBuilder: (context, index) {
                          final article = _articles[index];
                          return NewsCard(
                            article: article,
                            onReadMore: () => _onArticleTap(article),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
