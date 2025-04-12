import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/services/news_service.dart';
import 'package:neusenews/widgets/app_drawer.dart';
import 'package:neusenews/widgets/bottom_nav_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class NewsScreen extends StatefulWidget {
  final bool showAppBar;
  final bool showBottomNav;

  const NewsScreen({
    super.key,
    this.showAppBar = true,
    this.showBottomNav = true,
  });

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  final NewsService _newsService = NewsService();
  List<Article> _articles = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isOffline = false;

  // For infinite scrolling and pagination
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  final int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();
  List<Article> _allCombinedArticles = [];

  // For tab controller
  late TabController _tabController;
  final List<String> _tabs = ['All News', 'Local', 'Sports', 'Politics'];
  Map<String, List<Article>> _categorizedArticles = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);

    _checkConnectivity();
    _loadArticles();

    // Add scroll listener for infinite scrolling
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        // Reset page state when tab changes
        _currentPage = 0;
        _hasMoreData = true;
        _filterArticlesByTab(_tabController.index);
      });
    }
  }

  void _filterArticlesByTab(int tabIndex) {
    if (_allCombinedArticles.isEmpty) return;

    setState(() {
      if (tabIndex == 0) {
        // All News tab
        _articles = _allCombinedArticles.take(_pageSize).toList();
      } else if (_categorizedArticles.containsKey(_tabs[tabIndex])) {
        // Specific category tab
        _articles =
            _categorizedArticles[_tabs[tabIndex]]!.take(_pageSize).toList();
      }
    });
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData && !_isLoading) {
        _loadMoreArticles();
      }
    }
  }

  Future<void> _loadArticles({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _hasMoreData = true;
        _articles = [];
        _categorizedArticles = {};
      });
    }

    setState(() => _isLoading = true);

    try {
      await _checkConnectivity();

      if (_isOffline) {
        setState(() {
          _errorMessage = 'You are offline. Please check your connection.';
          _isLoading = false;
        });
        return;
      }

      // Fetch from all three RSS sources
      final localNews = await _newsService.fetchNewsByUrl(
        'https://www.neusenews.com/index?format=rss',
        skip: 0,
        take: _pageSize * 2, // Fetch more to populate categories
      );

      final sportsNews = await _newsService.fetchNewsByUrl(
        'https://www.neusenewssports.com/news-1?format=rss',
        skip: 0,
        take: _pageSize * 2,
      );

      final politicalNews = await _newsService.fetchNewsByUrl(
        'https://www.ncpoliticalnews.com/news?format=rss',
        skip: 0,
        take: _pageSize * 2,
      );

      // Categorize articles
      _categorizedArticles = {
        'Local': localNews,
        'Sports': sportsNews,
        'Politics': politicalNews,
      };

      // Combine all articles
      final List<Article> combinedArticles = [];
      combinedArticles.addAll(localNews);
      combinedArticles.addAll(sportsNews);
      combinedArticles.addAll(politicalNews);

      // Sort by publish date (newest first)
      combinedArticles.sort((a, b) => b.publishDate.compareTo(a.publishDate));

      // Remove duplicates
      final uniqueArticles = _removeDuplicates(combinedArticles);

      if (mounted) {
        setState(() {
          _allCombinedArticles = uniqueArticles;
          _articles = uniqueArticles.take(_pageSize).toList();
          _isLoading = false;
          _errorMessage = null;
          _currentPage++;

          // If we got fewer articles than expected, there's no more data
          if (uniqueArticles.length <= _pageSize) {
            _hasMoreData = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading news: $e';
        });
      }
    }
  }

  Future<void> _loadMoreArticles() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final currentTabIndex = _tabController.index;
      final List<Article> sourceList;

      if (currentTabIndex == 0) {
        sourceList = _allCombinedArticles;
      } else if (_categorizedArticles.containsKey(_tabs[currentTabIndex])) {
        sourceList = _categorizedArticles[_tabs[currentTabIndex]]!;
      } else {
        sourceList = [];
      }

      final startIndex = _currentPage * _pageSize;
      if (startIndex >= sourceList.length) {
        // We've already loaded all available articles
        setState(() {
          _hasMoreData = false;
          _isLoadingMore = false;
        });
        return;
      }

      final endIndex =
          (startIndex + _pageSize) > sourceList.length
              ? sourceList.length
              : (startIndex + _pageSize);

      final moreArticles = sourceList.sublist(startIndex, endIndex);

      if (mounted) {
        setState(() {
          _articles.addAll(moreArticles);
          _currentPage++;
          _isLoadingMore = false;

          if (moreArticles.length < _pageSize ||
              endIndex >= sourceList.length) {
            _hasMoreData = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more articles: $e')),
        );
      }
    }
  }

  // Helper method to remove duplicate articles
  List<Article> _removeDuplicates(List<Article> articles) {
    final ids = <String>{};
    final uniqueArticles = <Article>[];

    for (final article in articles) {
      if (ids.add(article.id)) {
        uniqueArticles.add(article);
      }
    }

    return uniqueArticles;
  }

  // Get color based on article source/category
  Color _getCategoryColor(Article article) {
    if (article.source.toLowerCase().contains('sports')) {
      return Colors.green;
    } else if (article.source.toLowerCase().contains('politic')) {
      return Colors.blue;
    } else {
      return const Color(0xFFd2982a); // Gold for local news
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          widget.showAppBar
              ? AppBar(
                title: const Text(
                  'NEWS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                centerTitle: true,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2d2c31),
                elevation: 0,
                bottom: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFFd2982a),
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: const Color(0xFFd2982a),
                  indicatorWeight: 3.0,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                  isScrollable: true,
                ),
              )
              : null,
      drawer: widget.showAppBar ? const AppDrawer() : null,
      body:
          _isLoading
              ? _buildLoadingShimmer()
              : _errorMessage != null
              ? _buildErrorState()
              : _buildArticleList(),
      bottomNavigationBar:
          widget.showBottomNav
              ? AppBottomNavBar(
                currentIndex: 1, // News is selected
                onTap: (index) {
                  // Add this navigation logic
                  switch (index) {
                    case 0: // Home
                      Navigator.pushReplacementNamed(context, '/dashboard');
                      break;
                    case 1: // News - already here
                      break;
                    case 2: // Weather
                      Navigator.pushReplacementNamed(context, '/weather');
                      break;
                    case 3: // Calendar
                      Navigator.pushReplacementNamed(context, '/calendar');
                      break;
                  }
                },
              )
              : null,
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 24,
                  width: double.infinity,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(height: 16, width: 200, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isOffline ? Icons.wifi_off : Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Something went wrong',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadArticles(refresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFd2982a),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleList() {
    return RefreshIndicator(
      onRefresh: () => _loadArticles(refresh: true),
      color: const Color(0xFFd2982a),
      child:
          _articles.isEmpty
              ? Center(
                child: Text(
                  'No articles available',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
              )
              : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _articles.length + (_hasMoreData ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _articles.length) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          color: const Color(0xFFd2982a),
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  }

                  final article = _articles[index];
                  final categoryColor = _getCategoryColor(article);

                  // Featured article (first item)
                  if (index == 0 && _tabController.index == 0) {
                    return _buildFeaturedArticleCard(article);
                  }

                  // Determine layout style
                  if (index % 3 == 0) {
                    return _buildLargeArticleCard(article, categoryColor);
                  } else {
                    return _buildCompactArticleCard(article, categoryColor);
                  }
                },
              ),
    );
  }

  Widget _buildFeaturedArticleCard(Article article) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/article', arguments: article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured tag and image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: article.imageUrl,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFd2982a),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          height: 240,
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 48,
                          ),
                        ),
                  ),
                ),
                // Featured badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFd2982a),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'FEATURED',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Category tag
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(article),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      article.source,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Gradient overlay for text readability
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 150,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                // Title
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Content
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author and date
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 16,
                        color: Color(0xFF2d2c31),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        article.author,
                        style: const TextStyle(
                          color: Color(0xFF2d2c31),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat.yMMMd().format(article.publishDate),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Excerpt
                  Text(
                    article.excerpt,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: Color(0xFF2d2c31),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2d2c31),
                          side: const BorderSide(color: Color(0xFF2d2c31)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            () => Navigator.pushNamed(
                              context,
                              '/article',
                              arguments: article,
                            ),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Read More'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFd2982a),
                          foregroundColor: Colors.white,
                        ),
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

  Widget _buildLargeArticleCard(Article article, Color categoryColor) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/article', arguments: article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and category
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: article.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFd2982a),
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                          ),
                        ),
                  ),
                ),
                // Category tag
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      article.source,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2d2c31),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Author and date
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          article.author,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat.MMMd().format(article.publishDate),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Excerpt
                  Text(
                    article.excerpt,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Read More link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Read More',
                        style: TextStyle(
                          color: categoryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.arrow_forward, size: 16, color: categoryColor),
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

  Widget _buildCompactArticleCard(Article article, Color categoryColor) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/article', arguments: article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with category indicator
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: article.imageUrl,
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          height: 120,
                          width: 120,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFd2982a),
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          height: 120,
                          width: 120,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                          ),
                        ),
                  ),
                  // Category indicator strip
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 4, color: categoryColor),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2d2c31),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Source and date
                    Text(
                      article.source,
                      style: TextStyle(
                        fontSize: 12,
                        color: categoryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Date
                    Text(
                      DateFormat.yMMMd().format(article.publishDate),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    // Read more link
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        'Read More',
                        style: TextStyle(
                          fontSize: 12,
                          color: categoryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
