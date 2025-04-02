import 'package:flutter/material.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/models/ad.dart';
import 'package:neusenews/widgets/in_feed_ad_banner.dart';
import 'package:neusenews/widgets/app_drawer.dart';
import 'package:neusenews/widgets/news_card.dart';
import 'package:neusenews/services/news_service.dart';

class NewsDetailScreen extends StatefulWidget {
  final String category;

  const NewsDetailScreen({super.key, required this.category});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final NewsService _newsService = NewsService();
  List<Article> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final articles = await _newsService.fetchNewsByUrl(
        getCategoryUrl(widget.category),
      );
      if (mounted) {
        setState(() {
          _articles = articles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading articles: $e')));
      }
    }
  }

  String getCategoryUrl(String category) {
    switch (category.toLowerCase()) {
      case 'sports':
        return 'https://www.neusenewssports.com/news-1?format=rss';
      case 'politics':
        return 'https://www.ncpoliticalnews.com/news?format=rss';
      case 'local news':
        return 'https://www.neusenews.com/index?format=rss';
      default:
        return 'https://www.neusenews.com/index?format=rss';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        backgroundColor: const Color(0xFFd2982a),
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadArticles,
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _articles.isEmpty
                ? const Center(child: Text('No articles found'))
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            _articles.length +
                            _articles.length ~/ 5, // Add an ad every 5 articles
                        itemBuilder: (context, index) {
                          // Show an ad every 5 items
                          if (index > 0 && index % 6 == 0) {
                            return const InFeedAdBanner(
                              adType: AdType.inFeedNews,
                            );
                          }

                          // Adjust the article index to account for ads
                          final articleIndex = index - index ~/ 6;
                          return NewsCard(
                            article: _articles[articleIndex],
                            onReadMore: () {
                              Navigator.pushNamed(
                                context,
                                '/article',
                                arguments: _articles[articleIndex],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Set to News tab
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
            case 3: // Calendar
              Navigator.pushReplacementNamed(context, '/calendar');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'News'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Weather'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
        ],
      ),
    );
  }
}
