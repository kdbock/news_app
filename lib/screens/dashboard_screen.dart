import 'dart:developer'; // For logging
import 'package:flutter/material.dart';
import 'package:neusenews/services/news_service.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/widgets/news_card_mini.dart';
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
import 'package:url_launcher/url_launcher.dart';
import 'package:neusenews/widgets/app_drawer.dart';
import 'package:neusenews/widgets/title_sponsor_banner.dart';
import 'package:neusenews/widgets/in_feed_ad_banner.dart';
import 'package:neusenews/models/ad.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDashboardData();

    // Add this Firebase auth listener
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      log(
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
      log('Error checking user roles: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      log('Starting to load dashboard data...');
      List<dynamic> results = await Future.wait([
        _newsService.fetchLocalNews(),
        _newsService.fetchSports(),
        _newsService.fetchColumns(),
        _newsService.fetchClassifieds(),
        _newsService.fetchObituaries(),
        _newsService.fetchPublicNotices(),
        _newsService.fetchNewsByUrl(
          'https://www.ncpoliticalnews.com/news?format=rss',
        ),
        _weatherService.getForecast(),
        _eventService.getUpcomingEvents(),
        _fetchSponsoredArticles(),
      ]);

      // Add these debug lines:
      final events = results[8] as List<Event>;
      log('Loaded ${events.length} total events');
      log('Sponsored events: ${events.where((e) => e.isSponsored).length}');

      log('Successfully fetched all data.');

      if (mounted) {
        setState(() {
          _localNews = results[0] as List<Article>;
          _sportsNews = results[1] as List<Article>;
          _columnsNews = results[2] as List<Article>;
          _classifiedsNews = results[3] as List<Article>;
          _obituariesNews = results[4] as List<Article>;
          _publicNoticesNews = results[5] as List<Article>;
          _politicsNews = results[6] as List<Article>;
          _forecasts = results[7] as List<weather_forecast.WeatherForecast>;
          _upcomingEvents = results[8] as List<Event>;
          _sponsoredArticles = results[9] as List<Article>;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      log('Error loading dashboard data: $e');
      log('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  // Update this method to properly fetch and process sponsored articles
  Future<List<Article>> _fetchSponsoredArticles() async {
    try {
      log('Fetching published sponsored articles...');

      // 1. First check if any sponsored articles exist at all
      final allArticles =
          await FirebaseFirestore.instance
              .collection('sponsored_articles')
              .get();

      log('Total sponsored articles in database: ${allArticles.docs.length}');

      if (allArticles.docs.isEmpty) {
        log('No sponsored articles found in the database');
        return [];
      }

      // 2. Now fetch published ones with better error detection
      final snapshot =
          await FirebaseFirestore.instance
              .collection('sponsored_articles')
              .where('status', isEqualTo: 'published')
              .get();

      log(
        'Found ${snapshot.docs.length} published sponsored articles in Firestore',
      );

      if (snapshot.docs.isEmpty) {
        log(
          'No PUBLISHED sponsored articles found - check if any articles have status="published"',
        );
        return [];
      }

      // 3. Process each document with better error handling
      List<Article> articles = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          log('Processing article ID: ${doc.id}, Title: ${data['title']}');

          // Handle potential null publishedAt date
          DateTime publishDate;
          try {
            publishDate = data['publishedAt']?.toDate() ?? DateTime.now();
            log('Publish date: $publishDate');
          } catch (dateError) {
            log(
              'Error parsing publishedAt date: $dateError, using current date instead',
            );
            publishDate = DateTime.now();
          }

          final article = Article(
            id: doc.id,
            title: data['title'] ?? 'Sponsored Article',
            excerpt:
                data['content'] != null &&
                        data['content'].toString().length > 150
                    ? '${data['content'].toString().substring(0, 150)}...'
                    : data['content']?.toString() ?? '',
            content: data['content']?.toString() ?? '',
            imageUrl: data['headerImageUrl'] ?? '',
            publishDate: publishDate,
            author: data['authorName'] ?? 'Sponsor',
            url: data['ctaLink'] ?? '',
            linkText: data['ctaText'] ?? 'Learn More',
            isSponsored: true,
            source: data['companyName'] ?? 'Sponsored Content',
          );

          articles.add(article);
        } catch (docError) {
          log('Error processing document ${doc.id}: $docError');
          // Continue to next document instead of failing entire list
        }
      }

      log('Successfully processed ${articles.length} sponsored articles');
      return articles;
    } catch (e) {
      log('Error fetching sponsored articles: $e');
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
                      Container(key: _sectionKeys['latestNews']),
                      _buildSectionHeader(
                        'Latest News',
                        onSeeAllPressed: () {
                          if (widget.onCategorySelected != null) {
                            widget.onCategorySelected!('localnews');
                          } else {
                            _navigateToScreen(
                              const local_news.LocalNewsScreen(),
                            );
                          }
                        },
                      ),
                      _buildNewsSlider(_localNews),

                      // Weather section
                      Container(key: _sectionKeys['weather']),
                      _buildSectionHeader(
                        'This Week\'s Weather',
                        onSeeAllPressed: () {
                          if (widget.onCategorySelected != null) {
                            widget.onCategorySelected!('weather');
                          } else {
                            _navigateToScreen(const weather.WeatherScreen());
                          }
                        },
                      ),
                      _buildWeatherPreview(),

                      // Sponsored Events section
                      Container(key: _sectionKeys['sponsoredEvents']),
                      _buildSectionHeader(
                        'Sponsored Events',
                        onSeeAllPressed: () {
                          if (widget.onCategorySelected != null) {
                            widget.onCategorySelected!('calendar');
                          } else {
                            _navigateToScreen(const calendar.CalendarScreen());
                          }
                        },
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
                      Container(key: _sectionKeys['sports']),
                      _buildSectionHeader(
                        'Sports',
                        onSeeAllPressed: () {
                          if (widget.onCategorySelected != null) {
                            widget.onCategorySelected!('sports');
                          } else {
                            _navigateToScreen(const sports.SportsScreen());
                          }
                        },
                      ),
                      _buildNewsSlider(_sportsNews),

                      // Politics News section
                      Container(key: _sectionKeys['politics']),
                      _buildSectionHeader(
                        'Politics',
                        onSeeAllPressed: () {
                          if (widget.onCategorySelected != null) {
                            widget.onCategorySelected!('politics');
                          } else {
                            _navigateToScreen(const politics.PoliticsScreen());
                          }
                        },
                      ),
                      _buildNewsSlider(_politicsNews),

                      // Columns News section
                      Container(key: _sectionKeys['columns']),
                      _buildSectionHeader(
                        'Columns',
                        onSeeAllPressed: () {
                          if (widget.onCategorySelected != null) {
                            widget.onCategorySelected!('columns');
                          } else {
                            _navigateToScreen(const columns.ColumnsScreen());
                          }
                        },
                      ),
                      _buildNewsSlider(_columnsNews),

                      // Classifieds News section
                      Container(key: _sectionKeys['classifieds']),
                      _buildSectionHeader(
                        'Classifieds',
                        onSeeAllPressed: () {
                          if (widget.onCategorySelected != null) {
                            widget.onCategorySelected!('classifieds');
                          } else {
                            _navigateToScreen(
                              const classifieds.ClassifiedsScreen(),
                            );
                          }
                        },
                      ),
                      _buildNewsSlider(_classifiedsNews),

                      // Obituaries News section
                      Container(key: _sectionKeys['obituaries']),
                      _buildSectionHeader(
                        'Obituaries',
                        onSeeAllPressed: () {
                          if (widget.onCategorySelected != null) {
                            widget.onCategorySelected!('obituaries');
                          } else {
                            _navigateToScreen(
                              const obituaries.ObituariesScreen(),
                            );
                          }
                        },
                      ),
                      _buildNewsSlider(_obituariesNews),

                      // Public Notices News section
                      Container(key: _sectionKeys['publicNotices']),
                      _buildSectionHeader(
                        'Public Notices',
                        onSeeAllPressed: () {
                          if (widget.onCategorySelected != null) {
                            widget.onCategorySelected!('publicnotices');
                          } else {
                            _navigateToScreen(
                              const public_notices.PublicNoticesScreen(),
                            );
                          }
                        },
                      ),
                      _buildNewsSlider(_publicNoticesNews),

                      const SizedBox(height: 20),
                    ],
                  ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFd2982a),
        elevation: 8.0,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          // Navigate to appropriate screen based on selected tab
          switch (index) {
            case 0: // Home tab
              // Already on home screen, just reset scroll
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
              break;
            case 1: // News tab
              if (widget.onCategorySelected != null) {
                widget.onCategorySelected!('localnews');
              } else {
                _navigateToScreen(const local_news.LocalNewsScreen());
              }
              break;
            case 2: // Weather tab
              if (widget.onCategorySelected != null) {
                widget.onCategorySelected!('weather');
              } else {
                _navigateToScreen(const weather.WeatherScreen());
              }
              break;
            case 3: // Calendar tab
              if (widget.onCategorySelected != null) {
                widget.onCategorySelected!('calendar');
              } else {
                _navigateToScreen(const calendar.CalendarScreen());
              }
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
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

  // Helper method for navigation
  void _navigateToScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Widget _buildNewsSlider(List<Article> articles) {
    // Return early if no articles
    if (articles.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No news available')),
      );
    }

    // Create a combined list of articles and ads
    final itemCount =
        articles.length + (articles.length > 3 ? articles.length ~/ 4 : 0);

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // Show an ad every 4 items (after position 3, 7, 11, etc.)
          if (index > 0 && index % 5 == 0 && index ~/ 5 < 3) {
            // Limit to max 3 ads
            return Container(
              width: 140,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: const InFeedAdBanner(adType: AdType.inFeedDashboard),
            );
          }

          // Adjust article index for ads
          final articleIndex = index - (index ~/ 5);
          if (articleIndex >= articles.length) return const SizedBox.shrink();

          final article = articles[articleIndex];

          return Container(
            width: 140,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Stack(
              children: [
                NewsCardMini(
                  article: article,
                  onTap: () => _openArticle(article),
                ),
                if (article.isSponsored)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
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
                  ),
              ],
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
    return SizedBox(
      height: 120,
      child:
          _forecasts.isEmpty
              ? Center(
                child: Text(
                  'Weather data unavailable',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
              : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _forecasts.length,
                itemBuilder: (context, index) {
                  final forecast = _forecasts[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            forecast.day,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _buildWeatherIcon(forecast.condition),
                          const SizedBox(height: 8),
                          Text('${forecast.temp.round()}°F'),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildWeatherIcon(String condition) {
    return Icon(
      _getWeatherIcon(condition),
      color: const Color(0xFFd2982a),
      size: 24,
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
}
