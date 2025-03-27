import 'dart:developer'; // For logging instead of print
import 'package:flutter/material.dart';
import 'package:news_app/services/news_service.dart';
import 'package:news_app/models/article.dart';
import 'package:news_app/widgets/news_card_mini.dart';
import 'package:news_app/services/weather_service.dart';
import 'package:news_app/models/weather_forecast.dart' as weather_forecast;
import 'package:news_app/screens/weather_screen.dart';
import 'package:news_app/screens/home_screen.dart';
import 'package:news_app/widgets/news_search_delegate.dart'
    as news_search_delegate;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app/screens/local_news_screen.dart';
import 'package:news_app/screens/politics_screen.dart';
import 'package:news_app/screens/sports_screen.dart';
import 'package:news_app/screens/obituaries_screen.dart';
import 'package:news_app/screens/columns_screen.dart';
import 'package:news_app/screens/public_notices_screen.dart';
import 'package:news_app/screens/classifieds_screen.dart';
import 'package:news_app/screens/submit_news_tip.dart';
import 'package:news_app/screens/submit_sponsored_event.dart';
import 'package:news_app/screens/submit_sponsored_article.dart';
import 'package:news_app/screens/profile_screen.dart';
import 'package:news_app/screens/settings_screen.dart';
import 'package:news_app/screens/calendar_screen.dart';
import 'package:news_app/models/event.dart';
import 'package:intl/intl.dart';
import 'package:news_app/services/event_service.dart';
import 'package:news_app/widgets/webview_screen.dart';
import 'package:news_app/screens/admin_review_screen.dart';
import 'package:provider/provider.dart';
import 'package:news_app/providers/auth_provider.dart' as app_auth;
import 'package:url_launcher/url_launcher.dart'; // Import for launchUrl
import 'package:news_app/widgets/app_drawer.dart'; // Add this import

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

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

  // PageController to manage the tab content
  late PageController _pageController;

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

  // Add these variables to the _DashboardScreenState class:
  bool _isAdmin = false;
  bool _isContributor = false;
  bool _isInvestor = false;

  // Define the _checkUserRoles method
  Future<void> _checkUserRoles() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          setState(() {
            _isAdmin = data['isAdmin'] ?? false;
            _isContributor = data['isContributor'] ?? false;
            _isInvestor = data['isInvestor'] ?? false;
          });
        }
      }
    } catch (e) {
      log('Error checking user roles: $e');
    }
  }

  // Add this at the top of _DashboardScreenState class
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _pageController = PageController(initialPage: 0);

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

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      List<dynamic> results = [];

      try {
        // Load data in parallel for better performance
        results = await Future.wait([
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
          _fetchSponsoredArticles(), // This might throw an exception
        ]);
      } catch (e) {
        log('Error in one of the data fetches: $e');
        // Continue with the function, we'll handle missing data
      }

      if (mounted) {
        setState(() {
          // Safely cast the results, handling possible missing data
          _localNews = results.isNotEmpty ? results[0] as List<Article> : [];
          _sportsNews = results.length > 1 ? results[1] as List<Article> : [];
          _columnsNews = results.length > 2 ? results[2] as List<Article> : [];
          _classifiedsNews =
              results.length > 3 ? results[3] as List<Article> : [];
          _obituariesNews =
              results.length > 4 ? results[4] as List<Article> : [];
          _publicNoticesNews =
              results.length > 5 ? results[5] as List<Article> : [];
          _politicsNews = results.length > 6 ? results[6] as List<Article> : [];
          _forecasts =
              results.length > 7
                  ? results[7] as List<weather_forecast.WeatherForecast>
                  : [];
          _upcomingEvents = results.length > 8 ? results[8] as List<Event> : [];

          // Handle sponsored articles separately since it's most likely to fail
          _sponsoredArticles =
              results.length > 9 ? results[9] as List<Article> : [];

          _isLoading = false;
        });

        // Add debugging for sponsored articles
        log(
          'Loaded ${_sponsoredArticles.length} sponsored articles for display',
        );
        if (_sponsoredArticles.isNotEmpty) {
          log('First sponsored article: ${_sponsoredArticles.first.title}');
        }
      }
    } catch (e) {
      log('Error loading dashboard data: $e');
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
            color: Colors.black.withAlpha(25), // Replace withAlpha
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

  // Add this method right after the _buildJumpLinks method
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

  // Rest of your existing methods...

  void _onDrawerOpen() async {
    log("Drawer opened - refreshing user roles");

    // Refresh both auth provider data and local role state
    if (mounted) {
      await Provider.of<app_auth.AuthProvider>(
        context,
        listen: false,
      ).refreshUserData();

      await _checkUserRoles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: const AppDrawer(), // Replace the previous drawer code with this
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFd2982a)),
              )
              : PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                children: [
                  _buildDashboardContent(),
                  const HomeScreen(),
                  WeatherTab(
                    weatherService: _weatherService,
                    forecasts: _forecasts,
                  ),
                  const CalendarScreen(),
                ],
              ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 8.0,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _pageController.jumpToPage(index);
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFd2982a),
        unselectedItemColor: Colors.grey[600],
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

  // Method to build the dashboard content
  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add jump links at the top
            _buildJumpLinks(),

            // Latest News section
            Container(key: _sectionKeys['latestNews']),
            _buildSectionHeader(
              'Latest News',
              onSeeAllPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocalNewsScreen(),
                  ),
                );
              },
            ),
            _buildNewsSlider(_localNews),

            // Weather section
            Container(key: _sectionKeys['weather']),
            _buildSectionHeader(
              'This Week\'s Weather',
              onSeeAllPressed: () {
                setState(() {
                  _selectedIndex = 2; // Switch to weather tab
                  _pageController.jumpToPage(2);
                });
              },
            ),
            _buildWeatherPreview(),

            // Sponsored Events section
            Container(key: _sectionKeys['sponsoredEvents']),
            _buildSectionHeader(
              'Sponsored Events',
              onSeeAllPressed: () {
                setState(() {
                  _selectedIndex = 3; // Switch to calendar tab
                  _pageController.jumpToPage(3);
                });
              },
            ),
            _buildEventSlider(
              _upcomingEvents.where((e) => e.isSponsored).toList(),
            ),

            // Sponsored Articles section - NEW
            Container(key: _sectionKeys['sponsoredArticles']),
            _buildSectionHeader(
              'Sponsored Articles',
              onSeeAllPressed: () {
                // Navigate to a dedicated sponsored articles screen
                // This would need to be implemented
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SportsScreen()),
                );
              },
            ),
            _buildNewsSlider(_sportsNews),

            // Politics News section
            Container(key: _sectionKeys['politics']),
            _buildSectionHeader(
              'NC Politics',
              onSeeAllPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PoliticsScreen(),
                  ),
                );
              },
            ),
            _buildNewsSlider(_politicsNews),

            // Columns News section
            Container(key: _sectionKeys['columns']),
            _buildSectionHeader(
              'Columns',
              onSeeAllPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ColumnsScreen(),
                  ),
                );
              },
            ),
            _buildNewsSlider(_columnsNews),

            // Classifieds News section
            Container(key: _sectionKeys['classifieds']),
            _buildSectionHeader(
              'Classifieds',
              onSeeAllPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClassifiedsScreen(),
                  ),
                );
              },
            ),
            _buildNewsSlider(_classifiedsNews),

            // Obituaries News section
            Container(key: _sectionKeys['obituaries']),
            _buildSectionHeader(
              'Obituaries',
              onSeeAllPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ObituariesScreen(),
                  ),
                );
              },
            ),
            _buildNewsSlider(_obituariesNews),

            // Public Notices News section
            Container(key: _sectionKeys['publicNotices']),
            _buildSectionHeader(
              'Public Notices',
              onSeeAllPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PublicNoticesScreen(),
                  ),
                );
              },
            ),
            _buildNewsSlider(_publicNoticesNews),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Updated to take a list of articles as parameter for reusability
  Widget _buildNewsSlider(List<Article> articles) {
    return SizedBox(
      height: 200, // Adjusted height for the slider
      child:
          articles.isEmpty
              ? const Center(child: Text('No news available'))
              : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Stack(
                      children: [
                        NewsCardMini(
                          article: article,
                          onTap: () => _openArticle(article),
                        ),
                        // Show sponsored badge if article is sponsored
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

  // Add this method to build the event slider
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

  // Add this method to show event details
  void _showEventDetails(Event event) {
    // Navigate to calendar and pass the event date to focus on
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarScreen(selectedDate: event.eventDate),
      ),
    );
  }

  // Update the _buildAppBar method
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

  // Add this method to handle search functionality
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

  Future<void> _downloadReport(String fileUrl) async {
    if (fileUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report URL not available')),
        );
      }
      return;
    }

    try {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $fileUrl';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error downloading report: $e')));
      }
    }
  }
}

// Create a stateless widget for the Weather tab content
class WeatherTab extends StatelessWidget {
  final WeatherService weatherService;
  final List<weather_forecast.WeatherForecast> forecasts;

  const WeatherTab({
    super.key,
    required this.weatherService,
    required this.forecasts,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weather Forecast',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                forecasts.isEmpty
                    ? const Center(child: Text('Weather data unavailable'))
                    : ListView.builder(
                      itemCount: forecasts.length,
                      itemBuilder: (context, index) {
                        final forecast = forecasts[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: _buildWeatherIcon(forecast.condition),
                            title: Text(
                              forecast.day,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(forecast.condition),
                            trailing: Text(
                              '${forecast.temp.round()}°F',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WeatherScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFd2982a),
                foregroundColor: Colors.white,
              ),
              child: const Text('View Detailed Weather'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherIcon(String condition) {
    IconData iconData;
    switch (condition.toLowerCase()) {
      case 'clear':
        iconData = Icons.wb_sunny;
        break;
      case 'clouds':
      case 'partly cloudy':
        iconData = Icons.cloud;
        break;
      case 'rain':
      case 'drizzle':
        iconData = Icons.umbrella;
        break;
      case 'thunderstorm':
        iconData = Icons.bolt;
        break;
      case 'snow':
        iconData = Icons.ac_unit;
        break;
      case 'mist':
      case 'fog':
      case 'haze':
        iconData = Icons.cloud_queue;
        break;
      default:
        iconData = Icons.cloud;
        break;
    }
    return Icon(iconData, color: const Color(0xFFd2982a), size: 30);
  }
}

// Add URL launcher helper method
Future<void> _launchURL(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Could not open $url')));
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Placeholder Screen')),
      body: const Center(child: Text('This is a placeholder screen.')),
    );
  }
}
