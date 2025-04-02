import 'package:flutter/material.dart';
import 'package:neusenews/widgets/app_drawer.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/services/news_service.dart';
import 'package:neusenews/widgets/news_card.dart';
import 'package:neusenews/widgets/in_feed_ad_banner.dart';
import 'package:neusenews/models/ad.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

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
      final articles = await _newsService.fetchLocalNews();

      if (mounted) {
        setState(() {
          _articles = articles;
          _isLoading = false;
        });
      }
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
        title: const Text('News'),
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
                : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _articles.length + _articles.length ~/ 5,
                  itemBuilder: (context, index) {
                    // Show an ad every 5 items
                    if (index > 0 && index % 6 == 0) {
                      return const InFeedAdBanner(adType: AdType.inFeedNews);
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
      ),
      bottomNavigationBar: BottomNavigationBar(
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
