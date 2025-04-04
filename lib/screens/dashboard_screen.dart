import 'dart:developer' as dev; // Add prefix for developer tools
import 'package:flutter/material.dart';
import 'package:neusenews/services/news_service.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/services/weather_service.dart';
import 'package:neusenews/models/weather_forecast.dart' as weather_forecast;
import 'package:neusenews/widgets/news_search_delegate.dart'
    as news_search_delegate;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neusenews/models/event.dart';
import 'package:intl/intl.dart';
import 'package:neusenews/services/event_service.dart';
import 'package:neusenews/widgets/webview_screen.dart';
import 'package:provider/provider.dart';
import 'package:neusenews/providers/auth_provider.dart' as app_auth;
import 'package:neusenews/widgets/app_drawer.dart';
import 'package:neusenews/widgets/title_sponsor_banner.dart';
import 'package:neusenews/widgets/in_feed_ad_banner.dart';
import 'package:neusenews/models/ad.dart';
import 'package:neusenews/widgets/app_bottom_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON encoding and decoding
import 'package:dart_rss/dart_rss.dart'; // For parsing RSS feeds
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math'; // Keep this without prefix
import 'package:neusenews/constants/layout_constants.dart'; // Add this import

// Import screens with aliases to avoid ambiguous references
import 'package:neusenews/features/weather/screens/weather_screen.dart'
    as weather;
import 'package:neusenews/features/news/screens/local_news_screen.dart'
    as local_news;
import 'package:neusenews/features/news/screens/politics_screen.dart'
    as politics;
import 'package:neusenews/features/news/screens/sports_screen.dart' as sports;
import 'package:neusenews/features/news/screens/obituaries_screen.dart'
    as obituaries;
import 'package:neusenews/features/news/screens/columns_screen.dart' as columns;
import 'package:neusenews/features/news/screens/public_notices_screen.dart'
    as public_notices;
import 'package:neusenews/features/news/screens/classifieds_screen.dart'
    as classifieds;
import 'package:neusenews/features/events/screens/calendar_screen.dart'
    as calendar;
import 'package:neusenews/features/news/screens/news_screen.dart';

// Add at the top of the file after imports:
extension IterableExtensions<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class DashboardScreen extends StatefulWidget {
  final Function(String)? onCategorySelected;

  const DashboardScreen({super.key, this.onCategorySelected});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final NewsService _newsService = NewsService();
  final WeatherService _weatherService = WeatherService();
  final EventService _eventService = EventService();
  List<Article> _localNews = [];
  List<Article> _sportsNews = [];
  List<Article> _columnsNews = [];
  List<Article> _classifiedsNews = [];
  List<Article> _obituariesNews = [];
  List<Article> _publicNoticesNews = [];
  List<Article> _politicsNews = [];
  List<weather_forecast.WeatherForecast> _forecasts = [];
  List<Event> _upcomingEvents = [];
  List<Article> _sponsoredArticles = [];
  bool _isLoading = true;

  // Add selected tab index
  int _selectedIndex = 0;

  // Add these scroll controllers for jump links
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {
    'latestNews': GlobalKey(),
    'weather': GlobalKey(),
    'sponsoredEvents': GlobalKey(),
    'sponsoredArticles': GlobalKey(),
    'sports': GlobalKey(),
    'politics': GlobalKey(),
    'columns': GlobalKey(),
    'classifieds': GlobalKey(),
    'obituaries': GlobalKey(),
    'publicNotices': GlobalKey(),
  };

  // Add this at the top of _DashboardScreenState class
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ignore: unused_field
  final bool _isAdmin = false;

  // Add to _DashboardScreenState:
  bool _mounted = true;

  // Replace flags with a set to track which sections have been loaded
  final Set<String> _loadedSections = {};

  @override
  void initState() {
    super.initState();
    _setupConnectivity();
    _loadDashboardData();

    // Add this Firebase auth listener
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      dev.log(
        "Auth state changed: User ${user != null ? 'logged in' : 'logged out'}",
      );
      _checkUserRoles(); // Add this method to update user roles
    });

    // Refresh user data when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<app_auth.AuthProvider>(
        context,
        listen: false,
      ).refreshUserData();
      _checkUserRoles(); // Check user roles explicitly here too
    });
  }

  // Define the _checkUserRoles method
  Future<void> _checkUserRoles() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          // The data variable is unused but we'll keep it for future use
          // final data = userDoc.data()!;
          setState(() {});
        }
      }
    } catch (e) {
      dev.log('Error checking user roles: $e');
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _setupConnectivity() async {
    // Initial connectivity check
    var connectivityResult = await Connectivity().checkConnectivity();
    _handleConnectivityChange(connectivityResult);

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
  }

  // Replace the _handleConnectivityChange method with this safer version:
  void _handleConnectivityChange(ConnectivityResult result) {
    final hasConnection = result != ConnectivityResult.none;

    if (!hasConnection && mounted) {
      // Capture context in a local variable before the setState
      final currentContext = context;

      setState(() {});

      // Now safely use the captured context
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(
          content: Text(
            'No internet connection. Some features may be limited.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } else if (hasConnection) {
      // Refresh data if connection is restored
      _loadDashboardData(forceRefresh: true);
    }
  }

  // Update the _loadDashboardData method to handle each feed separately

  Future<void> _loadDashboardData({bool forceRefresh = false}) async {
    if (!_mounted) return;
    setState(() => _isLoading = true);

    try {
      // Load each feed type with its own error handling
      // This prevents one bad feed from breaking everything

      // Start with basic feeds
      final forecasts = await _weatherService.getForecast();
      final events = await _eventService.getUpcomingEvents();

      // Start loading articles feeds in parallel but handle errors separately
      List<Article> sportsNews = [];
      List<Article> columnsNews = [];
      List<Article> classifiedsNews = [];
      List<Article> obituariesNews = [];
      List<Article> publicNoticesNews = [];
      List<Article> politicsNews = [];
      List<Article> sponsoredArticles = [];
      List<Article> localNews = [];

      try {
        sportsNews = await _newsService.fetchSports();
      } catch (e) {
        debugPrint('Error loading sports news: $e');
      }

      try {
        columnsNews = await _newsService.fetchColumns();
      } catch (e) {
        debugPrint('Error loading columns news: $e');
      }

      try {
        classifiedsNews = await _newsService.fetchClassifieds();
      } catch (e) {
        debugPrint('Error loading classifieds: $e');
      }

      try {
        obituariesNews = await _newsService.fetchObituaries();
      } catch (e) {
        debugPrint('Error loading obituaries: $e');
      }

      try {
        publicNoticesNews = await _newsService.fetchPublicNotices();
      } catch (e) {
        debugPrint('Error loading public notices: $e');
      }

      try {
        politicsNews = await _newsService.fetchNewsByUrl(
          'https://www.ncpoliticalnews.com/news?format=rss',
        );
      } catch (e) {
        debugPrint('Error loading politics news: $e');
      }

      try {
        localNews = await _newsService.fetchLocalNews();
      } catch (e) {
        debugPrint('Error loading local news: $e');
      }

      try {
        sponsoredArticles = await _fetchSponsoredArticles();
      } catch (e) {
        debugPrint('Error loading sponsored articles: $e');
      }

      if (_mounted) {
        setState(() {
          _sportsNews = sportsNews;
          _columnsNews = columnsNews;
          _classifiedsNews = classifiedsNews;
          _obituariesNews = obituariesNews;
          _publicNoticesNews = publicNoticesNews;
          _politicsNews = politicsNews;
          _forecasts = forecasts;
          _upcomingEvents = events;
          _sponsoredArticles = sponsoredArticles;
          _localNews = localNews;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard data error: $e');
      if (_mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Define the _fetchSponsoredArticles method
  Future<List<Article>> _fetchSponsoredArticles() async {
    try {
      dev.log('Fetching published sponsored articles...');

      // 1. First check if any sponsored articles exist at all
      final allArticles =
          await FirebaseFirestore.instance
              .collection('sponsored_articles')
              .get();

      dev.log(
        'Total sponsored articles in database: ${allArticles.docs.length}',
      );

      if (allArticles.docs.isEmpty) {
        dev.log('No sponsored articles found in the database');
        return [];
      }

      // 2. Now fetch published ones with better error detection
      final snapshot =
          await FirebaseFirestore.instance
              .collection('sponsored_articles')
              .where('status', isEqualTo: 'published')
              .get();

      dev.log(
        'Found ${snapshot.docs.length} published sponsored articles in Firestore',
      );

      if (snapshot.docs.isEmpty) {
        dev.log(
          'No PUBLISHED sponsored articles found - check if any articles have status="published"',
        );
        return [];
      }

      // 3. Process each document with better error handling
      List<Article> articles = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          dev.log('Processing article ID: ${doc.id}, Title: ${data['title']}');

          // Handle potential null publishedAt date
          DateTime publishDate;
          try {
            publishDate = data['publishedAt']?.toDate() ?? DateTime.now();
            dev.log('Publish date: $publishDate');
          } catch (dateError) {
            dev.log(
              'Error parsing publishedAt date: $dateError, using current date instead',
            );
            publishDate = DateTime.now();
          }

          final article = Article(
            guid: doc.id,
            title: data['title'] ?? 'Sponsored Article',
            description:
                data['content'] != null &&
                        data['content'].toString().length > 150
                    ? '${data['content'].toString().substring(0, 150)}...'
                    : data['content']?.toString() ?? '',
            url: data['ctaLink'] ?? '',
            imageUrl: data['headerImageUrl'] ?? '',
            publishDate: publishDate,
            id: doc.id,
            author: data['authorName'] ?? 'Sponsor',
            excerpt:
                data['content'] != null &&
                        data['content'].toString().length > 150
                    ? '${data['content'].toString().substring(0, 150)}...'
                    : data['content']?.toString() ?? '',
            content: data['content']?.toString() ?? '',
            linkText: data['ctaText'] ?? 'Learn More',
            isSponsored: true,
            source: data['companyName'] ?? 'Sponsored Content',
          );

          articles.add(article);
        } catch (docError) {
          dev.log('Error processing document ${doc.id}: $docError');
          // Continue to next document instead of failing entire list
        }
      }

      dev.log('Successfully processed ${articles.length} sponsored articles');
      return articles;
    } catch (e) {
      dev.log('Error fetching sponsored articles: $e');
      // Rethrow to provide better error reporting instead of returning empty list
      throw Exception('Failed to load sponsored articles: $e');
    }
  }

  // Add method to scroll to section
  void _scrollToSection(String section) {
    final key = _sectionKeys[section];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // Add this method below the _scrollToSection method
  Widget _buildJumpLinks() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              _buildJumpLink('Latest', 'latestNews'),
              _buildJumpLink('Weather', 'weather'),
              _buildJumpLink('Events', 'sponsoredEvents'),
              _buildJumpLink('Sponsored', 'sponsoredArticles'),
              _buildJumpLink('Sports', 'sports'),
              _buildJumpLink('Politics', 'politics'),
              _buildJumpLink('Columns', 'columns'),
              _buildJumpLink('Classifieds', 'classifieds'),
              _buildJumpLink('Obituaries', 'obituaries'),
              _buildJumpLink('Notices', 'publicNotices'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJumpLink(String label, String section) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ActionChip(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFd2982a)),
        label: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFd2982a),
            fontWeight: FontWeight.w500,
          ),
        ),
        onPressed: () => _scrollToSection(section),
      ),
    );
  }

  Future<void> _loadLocalNews({bool forceRefresh = false}) async {
    // Check for cached data first
    if (!forceRefresh) {
      final cachedNews = await _getCachedNewsData('localNews');
      if (cachedNews.isNotEmpty) {
        setState(() {
          _localNews = cachedNews;
          _loadedSections.add('localNews');
        });
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final localNews = await _newsService.fetchLocalNews();
      if (_mounted) {
        setState(() {
          _localNews = localNews;
          _loadedSections.add('localNews');
          _isLoading = false;

          // Save to local cache using shared_preferences
          _cacheNewsData('localNews', localNews);
        });
      }
    } catch (e) {
      dev.log('Error loading local news: $e');
      if (_mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Add this method to cache news data using shared_preferences
  Future<void> _cacheNewsData(String key, List<Article> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Convert articles to JSON and save
      final jsonData = articles.map((article) => article.toJson()).toList();
      await prefs.setString('cached_$key', jsonEncode(jsonData));
      dev.log('Cached ${articles.length} articles for $key');
    } catch (e) {
      dev.log('Error caching news data: $e');
    }
  }

  // Add this method to retrieve cached data
  Future<List<Article>> _getCachedNewsData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_$key');
      if (cachedData != null) {
        final jsonList = jsonDecode(cachedData) as List;
        return jsonList.map((json) => Article.fromJson(json)).toList();
      }
    } catch (e) {
      dev.log('Error retrieving cached news: $e');
    }
    return [];
  }

  // Create reusable navigation helper
  void _navigateToCategoryScreen(String category) {
    switch (category) {
      case 'localnews':
        _navigateToScreen(const local_news.LocalNewsScreen());
        break;
      case 'sports':
        _navigateToScreen(const sports.SportsScreen());
        break;
      case 'politics':
        _navigateToScreen(const politics.PoliticsScreen());
        break;
      case 'columns':
        _navigateToScreen(const columns.ColumnsScreen());
        break;
      case 'classifieds':
        _navigateToScreen(const classifieds.ClassifiedsScreen());
        break;
      case 'obituaries':
        _navigateToScreen(const obituaries.ObituariesScreen());
        break;
      case 'publicnotices':
        _navigateToScreen(const public_notices.PublicNoticesScreen());
        break;
      case 'weather':
        _navigateToScreen(const weather.WeatherScreen());
        break;
      case 'calendar':
        _navigateToScreen(const calendar.CalendarScreen());
        break;
      // Add other cases...
    }
  }

  // Create reusable section builder
  Widget _buildNewsSection(
    String title,
    String sectionKey,
    List<Article> articles,
    String category,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(key: _sectionKeys[sectionKey]),
        _buildSectionHeader(
          title,
          onSeeAllPressed: () => _navigateToCategoryScreen(category),
        ),
        _buildNewsSlider(articles),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          controller: _scrollController, // Add this controller
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title sponsor at the top
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: TitleSponsorBanner(),
              ),
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFd2982a)),
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Jump links at the top
                      _buildJumpLinks(),

                      // Latest News section
                      Container(
                        key: _sectionKeys['latestNews'],
                        child: FutureBuilder(
                          // Only load data if not already loaded
                          future:
                              _loadedSections.contains('localNews')
                                  ? null
                                  : _loadLocalNews(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFd2982a),
                                ),
                              );
                            }
                            return _buildNewsSlider(_localNews);
                          },
                        ),
                      ),

                      // Weather section
                      Container(key: _sectionKeys['weather']),
                      _buildWeatherPreview(),

                      // Sponsored Events section
                      Container(key: _sectionKeys['sponsoredEvents']),
                      _buildSectionHeader(
                        'Sponsored Events',
                        onSeeAllPressed:
                            () => _navigateToCategoryScreen('calendar'),
                      ),
                      _buildEventSlider(_upcomingEvents),

                      // Sponsored Articles section
                      Container(key: _sectionKeys['sponsoredArticles']),
                      _buildSectionHeader(
                        'Sponsored Articles',
                        onSeeAllPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const WebViewScreen(
                                    url: 'https://www.neusenews.com/sponsored',
                                    title: 'Sponsored Content',
                                  ),
                            ),
                          );
                        },
                      ),
                      _buildNewsSlider(_sponsoredArticles),

                      // Sports News section
                      _buildNewsSection(
                        'Sports',
                        'sports',
                        _sportsNews,
                        'sports',
                      ),

                      // Politics News section
                      _buildNewsSection(
                        'Politics',
                        'politics',
                        _politicsNews,
                        'politics',
                      ),

                      // Columns News section
                      _buildNewsSection(
                        'Columns',
                        'columns',
                        _columnsNews,
                        'columns',
                      ),

                      // Classifieds News section
                      _buildNewsSection(
                        'Classifieds',
                        'classifieds',
                        _classifiedsNews,
                        'classifieds',
                      ),

                      // Obituaries News section
                      _buildNewsSection(
                        'Obituaries',
                        'obituaries',
                        _obituariesNews,
                        'obituaries',
                      ),

                      // Public Notices News section
                      _buildNewsSection(
                        'Public Notices',
                        'publicNotices',
                        _publicNoticesNews,
                        'publicnotices',
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          switch (index) {
            case 0: // Home
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
              break;
            case 1: // News
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => NewsScreen(
                        sources: const [
                          'https://www.neusenews.com/index?format=rss',
                          'https://www.neusenewssports.com/news-1?format=rss',
                          'https://www.ncpoliticalnews.com/news?format=rss',
                        ],
                        title: 'News',
                      ),
                ),
              );
              break;
            case 2: // Weather
              _navigateToCategoryScreen('weather');
              break;
            case 3: // Events
              _navigateToCategoryScreen('calendar');
              break;
          }
        },
      ),
    );
  }

  // Helper method for navigation
  void _navigateToScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Widget _buildNewsSlider(List<Article> articles) {
    if (articles.isEmpty) {
      return Container(
        height: LayoutConstants.cardHeight,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(LayoutConstants.cardBorderRadius),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.article_outlined, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No news articles available',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pull down to refresh',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final itemCount =
        articles.length + (articles.length > 3 ? articles.length ~/ 4 : 0);

    return SizedBox(
      height: LayoutConstants.cardHeight + LayoutConstants.cardMargin.vertical,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: itemCount,
        cacheExtent: 500,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          // Show an ad every 4 items (after position 3, 7, 11, etc.)
          if (index > 0 && index % 5 == 0 && index ~/ 5 < 3) {
            return Container(
              width: LayoutConstants.cardWidth,
              height: LayoutConstants.cardHeight,
              margin: LayoutConstants.cardMargin,
              child: const InFeedAdBanner(adType: AdType.inFeedDashboard),
            );
          }

          // Adjust article index for ads
          final articleIndex = index - (index ~/ 5);
          if (articleIndex >= articles.length) return const SizedBox.shrink();

          final article = articles[articleIndex];

          return Container(
            width: LayoutConstants.cardWidth,
            height: LayoutConstants.cardHeight,
            margin: LayoutConstants.cardMargin,
            child: ArticleCard(
              article: article,
              onTap: () => _openArticle(article),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAllPressed}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d2c31),
            ),
          ),
          if (onSeeAllPressed != null)
            TextButton(
              onPressed: onSeeAllPressed,
              child: const Text(
                'See All',
                style: TextStyle(color: Color(0xFFd2982a)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeatherPreview() {
    return InkWell(
      onTap: () => _navigateToCategoryScreen('weather'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFd2982a).withAlpha(26),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weather',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d2c31),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Kinston, NC',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (_forecasts.isNotEmpty)
                      Text(
                        _formatTemperature(_forecasts.first.temp),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFd2982a),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _forecasts.isEmpty
                ? Center(
                  child: Text(
                    'Weather data unavailable',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
                : SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _forecasts.length.clamp(0, 5),
                    itemBuilder: (context, index) {
                      final forecast = _forecasts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            Text(
                              forecast.day,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildWeatherIcon(forecast.condition),
                            const SizedBox(height: 4),
                            Text(_formatTemperature(forecast.temp)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String _formatTemperature(double temp) {
    return '${temp.round()}°F';
  }

  Widget _buildWeatherIcon(String condition) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFd2982a).withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getWeatherIcon(condition),
        color: const Color(0xFFd2982a),
        size: 24,
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
      case 'partly cloudy':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
        return Icons.umbrella;
      case 'thunderstorm':
        return Icons.bolt;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.cloud_queue;
      default:
        return Icons.cloud;
    }
  }

  void _openArticle(Article article) {
    Navigator.pushNamed(context, '/article', arguments: article);
  }

  Widget _buildEventSlider(List<Event> events) {
    return SizedBox(
      height: 160, // Adjusted height for the event slider
      child:
          events.isEmpty
              ? const Center(child: Text('No upcoming events'))
              : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side:
                          event.isSponsored
                              ? const BorderSide(
                                color: Color(0xFFd2982a),
                                width: 1.5,
                              )
                              : BorderSide.none,
                    ),
                    child: InkWell(
                      onTap: () => _showEventDetails(event),
                      child: Container(
                        width: 180,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date and sponsor badge row
                            Row(
                              children: [
                                Icon(
                                  Icons.event,
                                  size: 16,
                                  color: const Color(0xFFd2982a),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM d').format(event.eventDate),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                if (event.isSponsored)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFd2982a),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'SPONSORED',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Title with ellipsis
                            Text(
                              event.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Location with icon
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    event.location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Time with icon
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  event.startTime,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  void _showEventDetails(Event event) {
    // Navigate to calendar and pass the event date to focus on
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => calendar.CalendarScreen(selectedDate: event.eventDate),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Image.asset(
        'assets/images/header.png',
        height: 40,
        fit: BoxFit.contain,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearch(),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // Navigate to notifications
          },
        ),
      ],
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFF2d2c31)),
    );
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: news_search_delegate.NewsSearchDelegate(
        _localNews, // Pass the required arguments
        _localNews,
        _sportsNews,
        _columnsNews,
      ),
    );
  }

  // Add these methods to ensure all feeds are loaded
  Future<void> _loadFeed(String feedName, String url, bool forceRefresh) async {
    try {
      final articles = await _newsService.fetchNewsByUrl(url);
      if (_mounted) {
        setState(() {
          switch (feedName) {
            case 'localNews':
              _localNews = articles;
              break;
            case 'sportsNews':
              _sportsNews = articles;
              break;
            case 'politicsNews':
              _politicsNews = articles;
              break;
            case 'columnsNews':
              _columnsNews = articles;
              break;
            case 'obituariesNews':
              _obituariesNews = articles;
              break;
            case 'publicNoticesNews':
              _publicNoticesNews = articles;
              break;
            case 'classifiedsNews':
              _classifiedsNews = articles;
              break;
          }
          _loadedSections.add(feedName);
        });
        _cacheNewsData(feedName, articles);
      }
    } catch (e) {
      debugPrint('Error loading $feedName: $e');
    }
  }
}

// 1. Add better caching for offline support:
Future<List<Article>> fetchNewsByUrl(
  String url, {
  int skip = 0,
  int take = 20,
}) async {
  // Check connectivity first
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    // Return cached data
    return getCachedArticles(url);
  }

  // Fetch new data and cache it
  try {
    final response = await http.get(Uri.parse(url));
    final articles = parseRssFeed(response.body, skip: skip, take: take);
    cacheArticles(url, articles);
    return articles;
  } catch (e) {
    // On error, try to return cached data
    debugPrint('Error fetching RSS: $e');
    return getCachedArticles(url);
  }
}

// Add these helper functions for cache management
Future<List<Article>> getCachedArticles(String url) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey =
        'articles_${Uri.parse(url).host}_${Uri.parse(url).path.replaceAll('/', '_')}';
    final cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      final jsonList = jsonDecode(cachedData) as List;
      return jsonList.map((json) => Article.fromJson(json)).toList();
    }
  } catch (e) {
    debugPrint('Error retrieving cached articles: $e');
  }

  return [];
}

Future<void> cacheArticles(String url, List<Article> articles) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey =
        'articles_${Uri.parse(url).host}_${Uri.parse(url).path.replaceAll('/', '_')}';

    // Convert articles to JSON and save
    final jsonData = articles.map((article) => article.toJson()).toList();
    await prefs.setString(cacheKey, jsonEncode(jsonData));

    // Update cache timestamp
    await prefs.setInt(
      '${cacheKey}_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );

    debugPrint('Cached ${articles.length} articles for $url');
  } catch (e) {
    debugPrint('Error caching articles: $e');
  }
}

// Replace the parseRssFeed function with this enhanced version:

List<Article> parseRssFeed(String xmlData, {int skip = 0, int take = 20}) {
  try {
    // Special handling for the sports feed which has consistent parsing issues
    bool isSportsFeed = xmlData.contains("neusenewssports.com");
    debugPrint('Parsing ${isSportsFeed ? "SPORTS" : "regular"} RSS feed');

    // More aggressive XML cleanup specifically for problematic feeds
    String cleanedXml = xmlData.trim();

    // First, handle XML declaration and comments
    if (cleanedXml.startsWith("<?xml")) {
      // Find where the actual content begins after declaration and comments
      final rssStart = cleanedXml.indexOf("<rss");
      if (rssStart > 0) {
        cleanedXml = cleanedXml.substring(rssStart);
        debugPrint('Removed XML declaration and comments');
      }
    }

    // Detailed debugging for Sports feed
    if (isSportsFeed) {
      debugPrint(
        'Sports feed XML snippet: ${cleanedXml.substring(0, min(200, cleanedXml.length))}',
      );
    }

    try {
      // First parsing attempt
      final feed = RssFeed.parse(cleanedXml);

      // Verify we have items
      if (feed.items.isEmpty) {
        debugPrint('Warning: RSS feed parsed but contains no items');
        return [];
      }

      debugPrint('Successfully parsed feed with ${feed.items.length} items');

      // Process items
      return feed.items
          .skip(skip)
          .take(take)
          .map((item) {
            try {
              // Extract image URL
              String imageUrl = _extractImageUrl(item);
              if (imageUrl.isEmpty) {
                imageUrl = 'assets/images/Default.jpeg';
              }

              return Article(
                title: item.title ?? 'Untitled',
                description: item.description ?? '',
                url: item.link ?? '',
                imageUrl: imageUrl,
                publishDate:
                    item.pubDate != null
                        ? _parseRssDate(item.pubDate!)
                        : DateTime.now(),
                guid: item.guid ?? item.link ?? DateTime.now().toString(),
                author: item.author ?? 'Neuse News',
                content: item.content?.value ?? item.description ?? '',
                // No excerpt field
              );
            } catch (itemError) {
              debugPrint('Error processing RSS item: $itemError');
              return null;
            }
          })
          .where((article) => article != null)
          .cast<Article>()
          .toList();
    } catch (parseError) {
      // First parse attempt failed, try alternate approach for sports feed
      if (isSportsFeed) {
        debugPrint(
          'First parsing attempt failed, trying alternative approach: $parseError',
        );
        return _parseSquarespaceSportsFeed(cleanedXml, skip: skip, take: take);
      }
      rethrow;
    }
  } catch (e) {
    debugPrint('Error parsing RSS feed: $e');
    return [];
  }
}

// Add this helper method to handle the problematic sports feed
List<Article> _parseSquarespaceSportsFeed(
  String xmlData, {
  int skip = 0,
  int take = 20,
}) {
  try {
    // Manually extract items using regex for severely malformed feeds
    final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
    final matches = itemRegex.allMatches(xmlData);

    debugPrint('Found ${matches.length} items using regex fallback');

    if (matches.isEmpty) {
      // Generate fallback content for sports if we can't parse anything
      return _generateFallbackSportsArticles();
    }

    List<Article> articles = [];
    int count = 0;

    for (var match in matches) {
      if (count >= skip + take) break;
      if (count < skip) {
        count++;
        continue;
      }

      try {
        final itemXml = match.group(1) ?? '';

        // Extract the basic fields using regex
        final titleMatch = RegExp(r'<title>(.*?)</title>').firstMatch(itemXml);
        final linkMatch = RegExp(r'<link>(.*?)</link>').firstMatch(itemXml);
        final descMatch = RegExp(
          r'<description>(.*?)</description>',
          dotAll: true,
        ).firstMatch(itemXml);
        final dateMatch = RegExp(
          r'<pubDate>(.*?)</pubDate>',
        ).firstMatch(itemXml);

        // Create article from extracted data
        final article = Article(
          title: titleMatch?.group(1)?.trim() ?? 'Sports Update',
          url: linkMatch?.group(1)?.trim() ?? 'https://www.neusenewssports.com',
          description: _cleanHtml(descMatch?.group(1) ?? ''),
          imageUrl:
              _extractImageFromHtml(descMatch?.group(1) ?? '') ??
              'assets/images/Default.jpeg',
          publishDate: _parseDate(dateMatch?.group(1) ?? ''),
          guid: linkMatch?.group(1)?.trim() ?? DateTime.now().toString(),
          author: 'Neuse Sports',
          content: _cleanHtml(descMatch?.group(1) ?? ''),
        );

        articles.add(article);
        count++;
      } catch (itemError) {
        debugPrint('Error extracting item data: $itemError');
      }
    }

    return articles;
  } catch (e) {
    debugPrint('Error in fallback sports parser: $e');
    return _generateFallbackSportsArticles();
  }
}

// Helper to clean HTML content
String _cleanHtml(String html) {
  return html
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('  ', ' ')
      .trim();
}

// Helper to extract image URL from HTML content
String? _extractImageFromHtml(String html) {
  final imgMatch = RegExp(r'<img[^>]+src="([^">]+)"').firstMatch(html);
  return imgMatch?.group(1);
}

// Helper to parse date with multiple formats
DateTime _parseDate(String dateStr) {
  try {
    return DateTime.parse(dateStr);
  } catch (_) {
    try {
      final formats = [
        'EEE, dd MMM yyyy HH:mm:ss Z',
        'yyyy-MM-dd HH:mm:ss',
        'dd MMM yyyy HH:mm:ss Z',
      ];

      for (final format in formats) {
        try {
          return DateFormat(format).parse(dateStr);
        } catch (_) {
          // Try next format
        }
      }
    } catch (_) {}
    // Return current date if all parsing fails
    return DateTime.now();
  }
}

// Generate fallback content when parsing completely fails
List<Article> _generateFallbackSportsArticles() {
  debugPrint('Generating fallback sports articles');
  return [
    Article(
      title: 'Latest Sports Updates',
      description:
          'Visit Neuse News Sports for the latest local sports coverage.',
      url: 'https://www.neusenewssports.com',
      imageUrl: 'assets/images/Default.jpeg',
      publishDate: DateTime.now(),
      guid: 'fallback-sports-1',
      author: 'Neuse Sports',
      content: 'Visit our website for the latest in local sports coverage.',
    ),
    Article(
      title: 'Local Sports Coverage',
      description: 'Check back soon for updated sports news and scores.',
      url: 'https://www.neusenewssports.com',
      imageUrl: 'assets/images/Default.jpeg',
      publishDate: DateTime.now().subtract(const Duration(days: 1)),
      guid: 'fallback-sports-2',
      author: 'Neuse Sports',
      content: 'Our team is working to bring you the latest sports updates.',
    ),
  ];
}

// Helper method to extract image URL from RSS item
String _extractImageUrl(RssItem item) {
  // Try to get image from media content
  if (item.media != null && item.media!.contents.isNotEmpty) {
    return item.media!.contents.first.url ?? '';
  }

  // Try to get image from description HTML
  final descriptionHtml = item.description ?? '';
  final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
  final match = imgRegex.firstMatch(descriptionHtml);
  if (match != null && match.groupCount >= 1) {
    return match.group(1) ?? '';
  }

  return '';
}

// Add the ArticleCard widget if it doesn't exist yet:
class ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const ArticleCard({
    super.key, // Use super parameter
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 110,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: article.imageUrl,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 40),
                    ),
              ),
            ),
            // Title and details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(article.publishDate),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final formatter = DateFormat('MMM d');
      return formatter.format(date);
    }
  }
}

// Add this function after your existing helper methods

// Helper function to parse RSS dates with proper error handling
DateTime _parseRssDate(String dateStr) {
  try {
    // Try built-in parser first (works for ISO format)
    return DateTime.parse(dateStr);
  } catch (_) {
    try {
      // Handle RFC 822 format (standard RSS date format)
      // Example: "Thu, 03 Apr 2025 04:38:16 +0000"
      final regex = RegExp(
        r'(\w+), (\d+) (\w+) (\d{4}) (\d{2}):(\d{2}):(\d{2}) ([\+\-]\d{4})',
      );
      final match = regex.firstMatch(dateStr);

      if (match != null) {
        final day = int.parse(match.group(2)!);
        final monthStr = match.group(3)!;
        final year = int.parse(match.group(4)!);
        final hour = int.parse(match.group(5)!);
        final minute = int.parse(match.group(6)!);
        final second = int.parse(match.group(7)!);

        // Convert month name to number
        final months = {
          'Jan': 1,
          'Feb': 2,
          'Mar': 3,
          'Apr': 4,
          'May': 5,
          'Jun': 6,
          'Jul': 7,
          'Aug': 8,
          'Sep': 9,
          'Oct': 10,
          'Nov': 11,
          'Dec': 12,
        };

        final month = months[monthStr] ?? 1;

        return DateTime(year, month, day, hour, minute, second);
      }

      // Also try using intl package's DateFormat
      final formats = [
        'EEE, dd MMM yyyy HH:mm:ss Z', // RFC 822
        'yyyy-MM-dd HH:mm:ss', // ISO without T
        'yyyy-MM-ddTHH:mm:ssZ', // ISO with T
      ];

      for (final format in formats) {
        try {
          return DateFormat(format).parse(dateStr);
        } catch (_) {
          // Try next format
        }
      }

      // If all attempts fail, return current date
      debugPrint('All date parsing attempts failed for: $dateStr');
      return DateTime.now();
    } catch (e) {
      debugPrint('Error parsing date "$dateStr": $e');
      return DateTime.now();
    }
  }
}
