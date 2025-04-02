import 'package:flutter/material.dart';
import 'package:neusenews/services/news_service.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/widgets/news_card.dart';
import 'package:neusenews/widgets/in_feed_ad_banner.dart';
import 'package:neusenews/models/ad.dart';
import 'package:neusenews/widgets/app_drawer.dart';

class CategoryScreen extends StatefulWidget {
  final String category;
  final String url;
  final Color categoryColor;
  final bool showAppBar;
  final bool showBottomNav;

  const CategoryScreen({
    super.key,
    required this.category,
    required this.url,
    this.categoryColor = const Color(0xFFd2982a),
    this.showAppBar = true,
    this.showBottomNav = true,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final NewsService _newsService = NewsService();
  List<Article> _articles = [];
  bool _isLoading = true;

  static const int _pageSize = 10;
  int _currentPage = 0;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _articles = [];
        _isLoading = true;
        _hasMoreData = true;
      });
    }

    if (!_hasMoreData) return;

    try {
      final articles = await _newsService.fetchNewsByUrl(
        widget.url,
        skip: _currentPage * _pageSize,
        take: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (articles.length < _pageSize) {
            _hasMoreData = false;
          }
          _articles.addAll(articles);
          _currentPage++;
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
    final body = RefreshIndicator(
      onRefresh: () => _loadArticles(refresh: true),
      child:
          _articles.isEmpty && _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _articles.isEmpty
              ? const Center(child: Text('No articles found'))
              : NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent &&
                      !_isLoading &&
                      _hasMoreData) {
                    _loadArticles();
                    return true;
                  }
                  return false;
                },
                child: ListView.builder(
                  itemCount: _articles.length + (_hasMoreData ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _articles.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    // Show ad every 5 articles
                    if (index > 0 && index % 6 == 0) {
                      return const InFeedAdBanner(adType: AdType.inFeedNews);
                    }

                    // Direct implementation for a single article
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
                      sourceTag: widget.category,
                    );
                  },
                ),
              ),
    );

    return Scaffold(
      appBar:
          widget.showAppBar
              ? AppBar(
                title: Text(widget.category),
                backgroundColor: widget.categoryColor,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      // Search implementation
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      // Notification implementation
                    },
                  ),
                ],
              )
              : null,
      drawer: widget.showAppBar ? const AppDrawer() : null,
      body: body,
      bottomNavigationBar:
          widget.showBottomNav
              ? BottomNavigationBar(
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
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.newspaper),
                    label: 'News',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.cloud),
                    label: 'Weather',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_month),
                    label: 'Calendar',
                  ),
                ],
              )
              : null,
    );
  }
}
