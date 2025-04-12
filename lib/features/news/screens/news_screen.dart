import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/services/news_service.dart';
import 'package:neusenews/widgets/bottom_nav_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:neusenews/features/advertising/widgets/news_feed_ad_banner.dart';
import 'package:neusenews/widgets/news_search_delegate.dart';

class NewsScreen extends StatefulWidget {
  final bool showAppBar;
  final bool showBottomNav;
  final String? initialTab; // New parameter

  const NewsScreen({
    super.key,
    this.showAppBar = true,
    this.showBottomNav = true,
    this.initialTab, // Add this parameter
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
  final List<String> _tabs = [
    'All News',
    'Local News',
    'State News',
    'Sports',
    'Politics',
    'Columns',
    'Matters of Record',
    'Obituaries',
    'Public Notice',
    'Classifieds',
  ];
  Map<String, List<Article>> _categorizedArticles = {};

  @override
  void initState() {
    super.initState();

    // Clear all caches to ensure fresh data
    _newsService.clearAllCaches(); // Add this line

    // Initialize tab controller
    _tabController = TabController(length: _tabs.length, vsync: this);

    // Set initial tab if specified
    if (widget.initialTab != null) {
      final initialTabIndex = _tabs.indexWhere(
        (tab) =>
            tab == widget.initialTab ||
            tab.toLowerCase() == widget.initialTab!.toLowerCase(),
      );

      if (initialTabIndex >= 0) {
        _tabController.animateTo(initialTabIndex);
      }
    }

    _tabController.addListener(_handleTabChange);
    _checkConnectivity();
    _loadArticles();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get any arguments passed during navigation
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is String) {
      // Find the matching tab
      final tabIndex = _tabs.indexWhere(
        (tab) => tab.toLowerCase() == args.toLowerCase(),
      );

      if (tabIndex >= 0 && _tabController.index != tabIndex) {
        // Switch to the selected tab
        _tabController.animateTo(tabIndex);
      }
    }
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
    // Force a refresh to bypass cache
    refresh = true; // Add this line temporarily

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

      // Define RSS feed URLs for each category
      final Map<String, String> rssFeeds = {
        'Local News':
            'https://www.neusenews.com/index/category/Local+News?format=rss',
        'State News':
            'https://www.neusenews.com/index/category/NC+News?format=rss',
        'Sports': 'https://www.neusenewssports.com/news-1?format=rss',
        'Politics': 'https://www.ncpoliticalnews.com/news?format=rss',
        'Columns':
            'https://www.neusenews.com/index/category/Columns?format=rss',
        'Matters of Record':
            'https://www.neusenews.com/index/category/Matters+of+Record?format=rss',
        'Obituaries':
            'https://www.neusenews.com/index/category/Obituaries?format=rss',
        'Public Notice':
            'https://www.neusenews.com/index/category/Public+Notices?format=rss',
        'Classifieds':
            'https://www.neusenews.com/index/category/Classifieds?format=rss',
      };

      // Initialize categorized articles map
      _categorizedArticles = {};

      // Fetch articles for each category
      final List<Article> allArticles = [];

      // Fetch from all feeds
      for (final entry in rssFeeds.entries) {
        final category = entry.key;
        final feedUrl = entry.value;

        try {
          final articles = await _newsService.fetchNewsByUrl(
            feedUrl,
            skip: 0,
            take: _pageSize * 2, // Fetch more to populate categories
          );

          // Store in category map
          _categorizedArticles[category] = articles;

          // Add to combined list
          allArticles.addAll(articles);
        } catch (e) {
          debugPrint('Error fetching $category feed: $e');
          // Continue with other feeds if one fails
          _categorizedArticles[category] = [];
        }
      }

      // Sort all articles by publish date (newest first)
      allArticles.sort((a, b) => b.publishDate.compareTo(a.publishDate));

      // Remove duplicates
      final uniqueArticles = _removeDuplicates(allArticles);

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
    final source = article.source.toLowerCase();

    // Check source name for matches
    if (source.contains('sports')) {
      return Colors.green[700]!;
    } else if (source.contains('politic')) {
      return Colors.blue[700]!;
    } else if (source.contains('state') || source.contains('nc news')) {
      return Colors.purple[700]!;
    } else if (source.contains('obituaries')) {
      return Colors.grey[700]!;
    } else if (source.contains('columns')) {
      return Colors.teal[700]!;
    } else if (source.contains('matters of record')) {
      return Colors.indigo[700]!;
    } else if (source.contains('public notice')) {
      return Colors.amber[800]!;
    } else if (source.contains('classifieds')) {
      return Colors.brown[600]!;
    } else {
      // Default for Local News
      return const Color(0xFFd2982a);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          widget.showAppBar
              ? AppBar(
                // Replace hamburger menu with back button
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                title: const Text('News'),
                backgroundColor: const Color(0xFFd2982a),
                foregroundColor: Colors.white,
                elevation: 0,
                bottom: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  indicatorColor: Colors.white,
                  indicatorWeight: 3.0,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                  isScrollable: true,
                ),
                // Add search icon in the app bar
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _showSearchDialog(context),
                  ),
                ],
              )
              : null,
      body:
          _isLoading
              ? _buildLoadingShimmer()
              : _errorMessage != null
              ? _buildErrorState()
              : _buildArticleList(),
      bottomNavigationBar:
          widget.showBottomNav
              ? AppBottomNavBar(
                currentIndex: 1,
                onTap: (index) {
                  switch (index) {
                    case 0: // Home
                      Navigator.pushReplacementNamed(context, '/');
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

  void _showSearchDialog(BuildContext context) {
    // Prepare data for search delegate
    // First prepare map of categorized articles to access as needed
    final Map<String, List<Article>> articlesMap = {};

    // Get the local news articles from _categorizedArticles
    final localNews = _categorizedArticles['Local News'] ?? [];
    final sportsNews = _categorizedArticles['Sports'] ?? [];
    final columnsNews = _categorizedArticles['Columns'] ?? [];
    final obituariesNews = _categorizedArticles['Obituaries'] ?? [];

    // Show search delegate
    showSearch(
      context: context,
      delegate: NewsSearchDelegate(
        localNews,
        sportsNews,
        columnsNews,
        obituariesNews,
      ),
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
                // Add 1 for loading indicator + additional spots for ads
                itemCount: _calculateListItemCount(),
                itemBuilder: (context, index) {
                  // Show loading indicator at the end if more data is available
                  if (index == _calculateListItemCount() - 1 && _hasMoreData) {
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

                  // Determine if this position should be an ad
                  // Insert ad after every 4 articles (index 4, 9, 14, etc.)
                  // Account for featured article at index 0
                  final adFrequency = 4;
                  final adjustedIndex = index;

                  if ((adjustedIndex + 1) % (adFrequency + 1) == 0 &&
                      adjustedIndex > 0) {
                    // This position should be an ad
                    return _buildInFeedAd();
                  }

                  // Calculate actual article index (accounting for ads)
                  final articleIndex = _getArticleIndexFromListIndex(index);
                  if (articleIndex >= _articles.length) {
                    // Safety check in case calculations are off
                    return const SizedBox.shrink();
                  }

                  final article = _articles[articleIndex];
                  final categoryColor = _getCategoryColor(article);

                  // Featured article (first item)
                  if (articleIndex == 0 && _tabController.index == 0) {
                    return _buildFeaturedArticleCard(article);
                  }

                  // Determine layout style
                  if (articleIndex % 3 == 0) {
                    return _buildLargeArticleCard(article, categoryColor);
                  } else {
                    return _buildCompactArticleCard(article, categoryColor);
                  }
                },
              ),
    );
  }

  // Add these helper methods for ad insertion
  int _calculateListItemCount() {
    if (_articles.isEmpty) return 0;

    // Base article count
    int count = _articles.length;

    // Add spots for ads (1 ad for every 4 articles)
    count += (_articles.length - 1) ~/ 4;

    // Add 1 for loading indicator if needed
    if (_hasMoreData) count++;

    return count;
  }

  int _getArticleIndexFromListIndex(int listIndex) {
    // Every 5th position (after the first 4 items) is an ad
    // So we need to adjust for that
    return listIndex - (listIndex ~/ 5);
  }

  Widget _buildInFeedAd() {
    return const NewsFeedAdBanner();
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
