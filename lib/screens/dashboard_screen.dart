import 'package:flutter/material.dart';
import 'package:news_app/services/news_service.dart';
import 'package:news_app/models/article.dart';
import 'package:news_app/widgets/news_card_mini.dart';
import 'package:news_app/services/weather_service.dart';
import 'package:news_app/models/weather_forecast.dart' as weather_forecast;
import 'package:news_app/screens/weather_screen.dart';
import 'package:news_app/screens/home_screen.dart';
import 'package:news_app/widgets/news_search_delegate.dart'
    as news_search_delegate; // Add this import
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:news_app/screens/edit_profile_screen.dart';
import 'package:news_app/screens/settings_screen.dart';
import 'package:news_app/screens/calendar_screen.dart';
import 'package:news_app/models/event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:news_app/services/event_service.dart';
import 'package:news_app/widgets/webview_screen.dart';

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
  bool _isLoading = true;

  // Add selected tab index
  int _selectedIndex = 0;

  // PageController to manage the tab content
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Load data in parallel for better performance
      final results = await Future.wait([
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
        _eventService.getUpcomingEvents(), // Use EventService here
      ]);

      if (mounted) {
        setState(() {
          // Cast the results to the correct types
          _localNews = results[0] as List<Article>;
          _sportsNews = results[1] as List<Article>;
          _columnsNews = results[2] as List<Article>;
          _classifiedsNews = results[3] as List<Article>;
          _obituariesNews = results[4] as List<Article>;
          _publicNoticesNews = results[5] as List<Article>;
          _politicsNews = results[6] as List<Article>;
          _forecasts = results[7] as List<weather_forecast.WeatherForecast>;
          _upcomingEvents = results[8] as List<Event>;
          _isLoading = false;
        });

        debugPrint(
          'Loaded feeds - Local: ${_localNews.length}, Sports: ${_sportsNews.length}, '
          'Politics: ${_politicsNews.length}, '
          'Columns: ${_columnsNews.length}, Classifieds: ${_classifiedsNews.length}, '
          'Obituaries: ${_obituariesNews.length}, Public Notices: ${_publicNoticesNews.length}, '
          'Weather Forecasts: ${_forecasts.length}, '
          'Upcoming Events: ${_upcomingEvents.length}',
        );
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  // Rest of your existing methods...

  // Create a stateless widget for the Weather tab content
  Widget _buildWeatherTab() {
    return WeatherTab(weatherService: _weatherService, forecasts: _forecasts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/header.png',
          height: 80,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFFd2982a)),
        // Add search icon to app bar
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFFd2982a)),
            onPressed: () {
              // Open search functionality
              showSearch(
                context: context,
                delegate: news_search_delegate.NewsSearchDelegate(
                  _localNews,
                  _sportsNews,
                  _columnsNews,
                  _obituariesNews,
                ),
              );
            },
          ),
        ],
      ),
      // Add drawer
      drawer: _buildDrawer(context),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFd2982a)),
              )
              : PageView(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Disable swiping
                onPageChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                children: [
                  // Home/Dashboard tab
                  _buildDashboardContent(),

                  // News tab
                  const HomeScreen(),

                  // Weather tab - inline weather content
                  WeatherTab(
                    weatherService: _weatherService,
                    forecasts: _forecasts,
                  ),

                  // Calendar tab
                  const CalendarScreen(),
                ],
              ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 8.0,
        currentIndex: _selectedIndex,
        onTap: (index) {
          // Update the selected index and change page
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            // Sports News section
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

            // Add the Events section here
            _buildSectionHeader(
              'Upcoming Events',
              onSeeAllPressed: () {
                setState(() {
                  _selectedIndex = 3; // Switch to calendar tab
                  _pageController.jumpToPage(3);
                });
              },
            ),
            _buildEventSlider(_upcomingEvents),

            // Politics News section
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: NewsCardMini(
                      article: articles[index],
                      onTap: () => _openArticle(articles[index]),
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

  // Add this method for building the drawer
  Widget _buildDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String firstName = '';

    if (user != null && user.displayName != null) {
      // Extract first name from display name
      firstName = user.displayName!.split(' ')[0];
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header with logo and greeting
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo image instead of avatar
                Image.asset(
                  'assets/images/header.png',
                  height: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),

                // Show greeting with first name if logged in
                if (user != null)
                  Text(
                    'Hello $firstName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Row(
                    children: [
                      const Text(
                        'Welcome!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/login');
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Color(0xFFd2982a),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Navigation items
          ListTile(
            leading: const Icon(Icons.home, color: Color(0xFFd2982a)),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 0);
              _pageController.jumpToPage(0);
            },
          ),

          ListTile(
            leading: const Icon(Icons.newspaper, color: Color(0xFFd2982a)),
            title: const Text('Latest News'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 1);
              _pageController.jumpToPage(1);
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.sports_baseball,
              color: Color(0xFFd2982a),
            ),
            title: const Text('Sports'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SportsScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.gavel, color: Color(0xFFd2982a)),
            title: const Text('Politics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PoliticsScreen()),
              );
            },
          ),

          // Add Order Classifieds option here
          ListTile(
            leading: const Icon(Icons.shopping_cart, color: Color(0xFFd2982a)),
            title: const Text('Order Classifieds'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => const WebViewScreen(
                        url: 'https://www.neusenews.com/order-classifieds',
                        title: 'Order Classifieds',
                      ),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.cloud, color: Color(0xFFd2982a)),
            title: const Text('Weather'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 2);
              _pageController.jumpToPage(2);
            },
          ),

          ListTile(
            leading: const Icon(Icons.calendar_month, color: Color(0xFFd2982a)),
            title: const Text('Community Calendar'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 3);
              _pageController.jumpToPage(3);
            },
          ),

          const Divider(),

          // Submit section
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 8.0),
            child: Text(
              'SUBMIT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(
              Icons.add_box_outlined,
              color: Color(0xFFd2982a),
            ),
            title: const Text('News Tip'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubmitNewsTipScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.event, color: Color(0xFFd2982a)),
            title: const Text('Sponsored Event'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubmitSponsoredEventScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.article, color: Color(0xFFd2982a)),
            title: const Text('Sponsored Article'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubmitSponsoredArticleScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // Profile/settings section
          if (user != null) ...[
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFFd2982a)),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFFd2982a)),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);

                // Get current user data
                String firstName = '';
                String lastName = '';
                final String email = user.email ?? '';

                // Parse display name into first and last name
                if (user.displayName != null) {
                  final nameParts = user.displayName!.split(' ');
                  firstName = nameParts.first;
                  lastName = nameParts.length > 1 ? nameParts.last : '';
                }

                // Navigate to edit profile with current user data
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => EditProfileScreen(
                          firstName: firstName,
                          lastName: lastName,
                          email: email,
                          phone:
                              '(252) 555-1234', // Default or placeholder data
                          zipCode:
                              '28577', // These would come from Firestore in a real app
                          birthday: '',
                          textAlerts: true,
                          dailyDigest: true,
                          sportsNewsletter: false,
                          politicalNewsletter: true,
                        ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFFd2982a)),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings using direct push
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFd2982a)),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                setState(() {}); // Refresh drawer
              },
            ),
          ],

          // App info at the bottom
          if (user == null) // Only show space if no user info is shown
            const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ],
      ),
    );
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
