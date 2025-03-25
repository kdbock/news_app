import 'package:flutter/material.dart';
import 'package:news_app/services/news_service.dart';
import 'package:news_app/models/article.dart';
import 'package:news_app/widgets/news_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // Make sure this is in pubspec.yaml

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NewsService _newsService = NewsService();
  List<Article> _articles = [];
  bool _isLoading = true;
  String _currentCategory = 'Local News';
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
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
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading news: $e')));
      }
    }
  }

  Future<void> _loadCategoryNews(String category, String url) async {
    setState(() => _isLoading = true);

    try {
      final articles = await _newsService.fetchNewsByUrl(url);
      if (mounted) {
        setState(() {
          _articles = articles;
          _currentCategory = category;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading $category: $e')));
      }
    }
  }

  void _onArticleTap(Article article) {
    // Navigate to article detail page
    Navigator.pushNamed(context, '/article', arguments: article);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // Simplified to use built-in white
        elevation: 0.5, // Subtle shadow
        title: Image.asset(
          'assets/images/header.png',
          height: 80,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Color(0xFFd2982a), // Gold hamburger menu
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search,
              color: Color(0xFFd2982a), // Gold search icon
            ),
            onPressed: () {
              // Show search dialog
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white, // Make entire drawer background white
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.white, // Keep header white to match drawer
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/loading_logo.png',
                  height: 80,
                ),
              ),
              // Make the header shorter
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
            ),
            // News Categories
            _buildDrawerItem(
              'Local News',
              Icons.location_on,
              url: 'https://www.neusenews.com/index?format=rss',
            ),
            _buildDrawerItem(
              'NC Politics',
              Icons.gavel,
              url: 'https://www.ncpoliticalnews.com/news?format=rss',
            ),
            _buildDrawerItem(
              'Sports',
              Icons.sports_baseball,
              url: 'https://www.neusenewssports.com/news-1?format=rss',
            ),
            _buildDrawerItem(
              'Columns',
              Icons.article,
              url:
                  'https://www.neusenews.com/index/category/Columns?format=rss',
            ),
            _buildDrawerItem(
              'Matters of Record',
              Icons.summarize,
              url:
                  'https://www.neusenews.com/index/category/Matters+of+Record?format=rss',
            ),
            _buildDrawerItem(
              'Obituaries',
              Icons.sentiment_very_dissatisfied,
              url:
                  'https://www.neusenews.com/index/category/Obituaries?format=rss',
            ),
            _buildDrawerItem(
              'Public Notices',
              Icons.announcement,
              url:
                  'https://www.neusenews.com/index/category/Public+Notices?format=rss',
            ),
            _buildDrawerItem(
              'Classifieds',
              Icons.sell,
              url:
                  'https://www.neusenews.com/index/category/Classifieds?format=rss',
            ),
            _buildDrawerItem(
              'Order Classifieds',
              Icons.shopping_cart,
              externalUrl: 'https://www.neusenews.com/order-classifieds',
            ),

            const Divider(),

            // User Actions
            _buildDrawerItem('Profile', Icons.person, route: '/profile'),
            _buildDrawerItem(
              'Edit Profile',
              Icons.edit,
              route: '/edit_profile',
            ),
            _buildDrawerItem(
              'Submit Press Release',
              Icons.send,
              route: '/submit_press_release',
            ),
            _buildDrawerItem(
              'Submit News Tip',
              Icons.tips_and_updates,
              route: '/submit_news_tip',
            ),
            _buildDrawerItem(
              'Submit Sponsored Event',
              Icons.event,
              route: '/submit_sponsored_event',
            ),
            _buildDrawerItem(
              'Submit Sponsored News',
              Icons.newspaper,
              route: '/submit_sponsored_news',
            ),

            const Divider(),

            // Logout
            _buildDrawerItem('Logout', Icons.logout, isLogout: true),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadNews,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8.0),
                  itemCount: _articles.length,
                  itemBuilder: (context, index) {
                    return NewsCard(
                      article: _articles[index],
                      onReadMore: () => _onArticleTap(_articles[index]),
                    );
                  },
                ),
              ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white, // Added white background
        elevation: 8.0, // Add shadow for better separation
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          // Handle navigation
          switch (index) {
            case 0: // Home
              _loadCategoryNews(
                'Local News',
                'https://www.neusenews.com/index?format=rss',
              );
              break;
            case 1: // News
              showModalBottomSheet(
                context: context,
                builder: (context) => _buildCategoriesSheet(),
              );
              break;
            case 2: // Weather
              Navigator.pushNamed(context, '/weather');
              break;
            case 3: // Calendar
              Navigator.pushNamed(context, '/calendar');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFd2982a),
        unselectedItemColor: Colors.grey[600], // Slightly darker than default
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

  // Update the _buildDrawerItem method with darker text and compact spacing
  Widget _buildDrawerItem(
    String title,
    IconData icon, {
    String? url,
    String? externalUrl,
    String? route,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF2d2c31), // Dark gray icons
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF2d2c31), // Darker text (dark gray)
          fontWeight: FontWeight.w500, // Medium weight for better visibility
        ),
      ),
      dense: true, // Makes the list tile more compact
      visualDensity: const VisualDensity(
        vertical: -1,
      ), // Further reduce vertical spacing
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 0,
      ), // Custom padding
      onTap: () async {
        Navigator.pop(context); // Close drawer first

        // Handle different navigation types
        if (url != null) {
          // Load RSS feed with category
          await _loadCategoryNews(title, url);
        } else if (externalUrl != null) {
          // Launch external URL (requires url_launcher package)
          final Uri uri = Uri.parse(externalUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not open $externalUrl')),
              );
            }
          }
        } else if (route != null) {
          // Navigate to internal screen
          Navigator.pushNamed(context, route);
        } else if (isLogout) {
          // Handle logout
          _handleLogout();
        }
      },
    );
  }

  // Add this method to handle logout
  void _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // Navigate back to login screen and clear navigation stack
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
    }
  }

  Widget _buildCategoriesSheet() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'News Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildCategoryChip('Local News'),
              _buildCategoryChip('State News'),
              _buildCategoryChip('NC Politics'),
              _buildCategoryChip('Sports'),
              _buildCategoryChip('Columns'),
              _buildCategoryChip('Matters of Record'),
              _buildCategoryChip('Obituaries'),
              _buildCategoryChip('Public Notices'),
              _buildCategoryChip('Classifieds'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return ActionChip(
      label: Text(category),
      backgroundColor:
          _currentCategory == category
              ? const Color(0xFFd2982a)
              : Colors.grey[200],
      labelStyle: TextStyle(
        color: _currentCategory == category ? Colors.white : Colors.black,
      ),
      onPressed: () {
        Navigator.pop(context);
        _loadCategoryNews(
          category,
          'https://www.neusenews.com/index?format=rss',
        );
      },
    );
  }
}
