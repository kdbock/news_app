import 'package:flutter/material.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/services/news_service.dart';
import 'package:neusenews/widgets/app_drawer.dart';

class BaseCategoryScreen extends StatefulWidget {
  final String category;
  final String url;
  final Color categoryColor;
  final bool showAppBar;
  final bool showBottomNav;

  const BaseCategoryScreen({
    super.key,
    required this.category,
    required this.url,
    required this.categoryColor,
    this.showAppBar = true,
    this.showBottomNav = true,
  });

  @override
  State<BaseCategoryScreen> createState() => _BaseCategoryScreenState();
}

class _BaseCategoryScreenState extends State<BaseCategoryScreen> {
  final NewsService _newsService = NewsService();
  List<Article> _articles = [];
  bool _isLoading = true;
  bool _isOffline = false;
  String? _errorMessage;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Fix the fetchNewsByUrl call with proper parameters
      final articles = await _newsService.fetchNewsByUrl(
        widget.url,
        cacheKey: 'category_${widget.category}',
        forceRefresh: refresh,
        skip: 0,
        take: _pageSize,
      );

      if (mounted) {
        setState(() {
          _articles = articles;
          _isLoading = false;
          _isOffline = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Unable to load articles. Please check your connection.';
          _isOffline = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = _buildContent();

    return Scaffold(
      appBar: widget.showAppBar ? _buildAppBar() : null,
      drawer: widget.showAppBar ? const AppDrawer() : null,
      body: RefreshIndicator(
        onRefresh: () => _loadArticles(refresh: true),
        child: content,
      ),
      bottomNavigationBar: widget.showBottomNav ? _buildBottomNav() : null,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(widget.category),
      backgroundColor: widget.categoryColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // Implement search functionality
          },
        ),
      ],
    );
  }

  BottomNavigationBar _buildBottomNav() {
    return BottomNavigationBar(
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
    );
  }

  Widget _buildContent() {
    if (_isLoading && _articles.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: 5,
        itemBuilder:
            (context, index) => Container(
              height: 100,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
      );
    }

    return ListView.builder(
      itemCount: _articles.length,
      itemBuilder: (context, index) {
        return _buildArticleCard(_articles[index]);
      },
    );
  }

  Future<List<Article>> Function({int skip, int take, bool forceRefresh})
  _getFetcherForCategory() {
    switch (widget.category.toLowerCase()) {
      case 'localnews':
        return _newsService.fetchLocalNews;
      case 'sports':
        return _newsService.fetchSports;
      case 'politics':
        return _newsService.fetchPolitics;
      case 'columns':
        return _newsService.fetchColumns;
      case 'obituaries':
        return _newsService.fetchObituaries;
      case 'publicnotices':
        return _newsService.fetchPublicNotices;
      case 'classifieds':
        return _newsService.fetchClassifieds;
      default:
        return _newsService.fetchLocalNews;
    }
  }

  Widget _buildArticleCard(Article article) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/article', arguments: article);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl.isNotEmpty)
              SizedBox(
                height: 180,
                width: double.infinity,
                child: Image.network(
                  article.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        color: Colors.grey[300],
                        height: 180,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 50),
                        ),
                      ),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (article.excerpt.isNotEmpty)
                    Text(
                      article.excerpt,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        article.author,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatDate(article.publishDate),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  void _openArticle(Article article) {
    Navigator.pushNamed(context, '/article', arguments: article);
  }
}
