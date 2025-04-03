import 'package:flutter/material.dart';
import 'package:neusenews/widgets/app_drawer.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/services/news_service.dart';
import 'package:neusenews/widgets/news_card.dart';
import 'package:neusenews/widgets/app_bottom_navigation.dart';
import 'package:neusenews/constants/app_colors.dart';

class NewsScreen extends StatefulWidget {
  final List<String> sources;
  final String title;

  const NewsScreen({
    super.key,
    this.sources = const ['https://www.neusenews.com/index?format=rss'],
    this.title = 'News',
  });

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
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
      List<Article> allArticles = [];

      // Fetch articles from all sources
      for (String source in widget.sources) {
        final articles = await _newsService.fetchNewsByUrl(source);
        allArticles.addAll(articles);
      }

      // Sort by publish date (newest first)
      allArticles.sort((a, b) => b.publishDate.compareTo(a.publishDate));

      setState(() {
        _articles = allArticles;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading news: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadArticles,
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
                : _articles.isEmpty
                ? const Center(child: Text('No news available'))
                : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _articles.length,
                  itemBuilder: (context, index) {
                    final article = _articles[index];
                    return NewsCard(
                      article: article,
                      onReadMore: () {
                        Navigator.pushNamed(
                          context,
                          '/article',
                          arguments: article,
                        );
                      },
                    );
                  },
                ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 1, // News tab is active
        onTap: (index) {
          switch (index) {
            case 0: // Home
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1: // News
              // Already on news page
              break;
            case 2: // Weather
              Navigator.pushReplacementNamed(context, '/weather');
              break;
            case 3: // Events
              Navigator.pushReplacementNamed(context, '/calendar');
              break;
          }
        },
      ),
    );
  }
}
