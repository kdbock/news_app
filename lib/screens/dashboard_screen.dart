import 'dart:async';
import 'package:flutter/material.dart';
import 'package:neusenews/models/article.dart';
import 'package:provider/provider.dart';
import 'package:neusenews/widgets/app_drawer.dart';
import 'package:neusenews/widgets/components/section_header.dart';
import 'package:neusenews/providers/news_provider.dart';
import 'package:neusenews/providers/weather_provider.dart';
import 'package:neusenews/services/connectivity_service.dart';
import 'package:neusenews/widgets/news_card_mini.dart';
import 'package:neusenews/widgets/news_card.dart'; // Add this import for NewsCard
import 'package:neusenews/widgets/dashboard/dashboard_weather_widget.dart';
import 'package:neusenews/widgets/category_navigation_bar.dart';
import 'package:neusenews/widgets/bottom_nav_bar.dart';
import 'package:neusenews/services/news_service.dart';
import 'package:neusenews/widgets/dashboard/dashboard_sponsored_article.dart';
import 'package:neusenews/providers/events_provider.dart'; // Ensure this is the correct path
import 'package:neusenews/widgets/dashboard/dashboard_event.dart'; // Add this import
// Add this import for the title sponsor banner
import 'package:neusenews/features/advertising/widgets/title_sponsor_banner.dart';
// Add this import at the top with your other imports
import 'package:neusenews/features/advertising/widgets/in_feed_ad_banner.dart';
import 'package:neusenews/features/advertising/models/ad_type.dart';

class DashboardScreen extends StatefulWidget {
  final bool showBottomNav;

  // Add this parameter to the constructor
  const DashboardScreen({super.key, this.showBottomNav = true});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final bool _isRefreshing = false;
  bool _isInitialized = false;

  // Add these fields to your _DashboardScreenState class
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {
    'local': GlobalKey(),
    'sports': GlobalKey(),
    'politics': GlobalKey(),
    'columns': GlobalKey(),
    'obituaries': GlobalKey(),
    'publicnotices': GlobalKey(),
    'classifieds': GlobalKey(),
    'matters': GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeData();
      }
    });
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    final weatherProvider = Provider.of<WeatherProvider>(
      context,
      listen: false,
    );
    final connectivityService = Provider.of<ConnectivityService>(
      context,
      listen: false,
    );
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);

    try {
      await newsProvider.loadCachedData();

      if (connectivityService.isOnline) {
        weatherProvider.refreshWeather().catchError(
          (e) => debugPrint('Error loading weather: $e'),
        );
        await newsProvider.loadDashboardData();
        // Load sponsored articles separately
        await newsProvider.loadSponsoredArticles();
        await eventsProvider.loadEvents();
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/header.png', height: 32),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF2d2c31)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<ConnectivityService>(
        builder: (context, connectivityService, child) {
          return Stack(
            children: [
              _buildDashboard(),
              if (!connectivityService.isOnline)
                _buildOfflineBanner(connectivityService),
            ],
          );
        },
      ),
      bottomNavigationBar:
          widget.showBottomNav
              ? AppBottomNavBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() => _selectedIndex = index);
                  switch (index) {
                    case 0:
                      break;
                    case 1:
                      Navigator.pushReplacementNamed(context, '/news');
                      break;
                    case 2:
                      Navigator.pushReplacementNamed(context, '/weather');
                      break;
                    case 3:
                      Navigator.pushReplacementNamed(context, '/calendar');
                      break;
                  }
                },
              )
              : null,
    );
  }

  Widget _buildDashboard() {
    if (!_isInitialized) {
      return _buildLoadingSkeleton();
    }

    final categories = <CategoryItem>[
      CategoryItem(id: 'local', label: 'Local', route: '/news/local'),
      CategoryItem(id: 'sports', label: 'Sports', route: '/news/sports'),
      CategoryItem(id: 'politics', label: 'Politics', route: '/news/politics'),
      CategoryItem(id: 'columns', label: 'Columns', route: '/news/columns'),
      CategoryItem(
        id: 'obituaries',
        label: 'Obituaries',
        route: '/news/obituaries',
      ),
      CategoryItem(
        id: 'publicnotices',
        label: 'Public Notices',
        route: '/news/public-notices',
      ),
      CategoryItem(
        id: 'classifieds',
        label: 'Classifieds',
        route: '/news/classifieds',
      ),
      CategoryItem(
        id: 'matters',
        label: 'Matters of Record',
        route: '/news/matters-of-record',
      ),
    ];

    return SingleChildScrollView(
      controller: _scrollController, // Add this line
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryNavigationBar(
            categories: categories,
            initialCategory: 'local',
            onCategorySelected: (categoryId) {
              // Scroll to the section instead of navigating
              if (_sectionKeys.containsKey(categoryId)) {
                _scrollToSection(categoryId);
              }
            },
          ),
          // Title sponsor banner (existing)
          const TitleSponsorBanner(),
          Consumer<WeatherProvider>(
            builder: (context, weatherProvider, _) {
              final forecasts = weatherProvider.getDashboardForecast();
              if (forecasts.isEmpty) return const SizedBox.shrink();
              return DashboardWeatherWidget(
                forecasts: forecasts,
                onSeeAllPressed: () => Navigator.pushNamed(context, '/weather'),
              );
            },
          ),
          _buildNewsSection(
            newsSelector: (p) => p.localNews,
            title: 'Local News',
            categoryKey: 'local',
          ),
          Consumer<EventsProvider>(
            builder: (context, eventsProvider, _) {
              final events = eventsProvider.upcomingEvents;
              if (events.isEmpty) return const SizedBox.shrink();
              return DashboardEventWidget(
                events: events,
                onEventTapped:
                    (event) => Navigator.pushNamed(
                      context,
                      '/event',
                      arguments: event,
                    ),
                onRsvpTapped: (event) {
                  debugPrint('RSVP tapped for event: $event');
                },
                onAddEventTapped:
                    () =>
                        Navigator.pushNamed(context, '/submit-sponsored-event'),
              );
            },
          ),
          Consumer<NewsProvider>(
            builder: (context, newsProvider, _) {
              final sponsored = newsProvider.sponsoredArticles;
              if (sponsored.isEmpty) return const SizedBox.shrink();
              return DashboardSponsoredArticleWidget(
                articles: sponsored,
                onArticleTapped:
                    (article) => Navigator.pushNamed(
                      context,
                      '/article',
                      arguments: article,
                    ),
                onSeeAllPressed:
                    () => Navigator.pushNamed(context, '/Sponsored'),
              );
            },
          ),
          _buildNewsSection(
            newsSelector: (p) => p.sportsNews,
            title: 'Sports',
            categoryKey: 'sports',
          ),
          _buildNewsSection(
            newsSelector: (p) => p.politicsNews,
            title: 'Politics',
            categoryKey: 'politics',
          ),
          _buildNewsSection(
            newsSelector: (p) => p.columnsNews,
            title: 'Columns',
            categoryKey: 'columns',
          ),
          _buildNewsSection(
            newsSelector: (p) => p.obituariesNews,
            title: 'Obituaries',
            categoryKey: 'obituaries',
          ),
          _buildNewsSection(
            newsSelector: (p) => p.publicNoticesNews,
            title: 'Public Notices',
            categoryKey: 'public-notices',
          ),
          _buildNewsSection(
            newsSelector: (p) => p.classifiedsNews,
            title: 'Classifieds',
            categoryKey: 'classifieds',
          ),
          _buildNewsSection(
            newsSelector: (p) => p.mattersOfRecordNews,
            title: 'Matters of Record',
            categoryKey: 'matters-of-record',
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(ConnectivityService connectivityService) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: connectivityService.forceOnlineMode,
        child: Container(
          color: Colors.red[700],
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'You are offline. Tap to retry.',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSkeletonSectionHeader(),
        const SizedBox(height: 8),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            itemBuilder: (context, index) => _buildSkeletonNewsCardMini(),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 120,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Container(
          width: 60,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonNewsCardMini() {
    return Container(
      margin: const EdgeInsets.all(8),
      width: 220,
      height: 210,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _openArticle(Article article) {
    Navigator.pushNamed(context, '/article', arguments: article);
  }

  void _showSearch(BuildContext context) {
    Navigator.pushNamed(context, '/search');
  }

  Widget _buildNewsSection({
    required Function(NewsProvider) newsSelector,
    required String title,
    required String categoryKey,
  }) {
    return Consumer<NewsProvider>(
      builder: (context, newsProvider, _) {
        final news = newsSelector(newsProvider);
        if (news.isEmpty) return const SizedBox.shrink();

        return Column(
          key: _sectionKeys[categoryKey], // Add this line
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Uniform section headers
            Container(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFd2982a), width: 1.0),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2d2c31),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed:
                        () => Navigator.pushNamed(
                          context,
                          '/news',
                          arguments: title, // Pass the tab name as argument
                        ),
                    child: const Text(
                      'See All',
                      style: TextStyle(fontSize: 14, color: Color(0xFFd2982a)),
                    ),
                  ),
                ],
              ),
            ),
            // Rest of the section remains the same
            SizedBox(
              height: 180,
              child: _buildNewsListWithAds(news, AdType.inFeedDashboard),
            ),
          ],
        );
      },
    );
  }

  // Add this method to your _DashboardScreenState class

  Widget _buildNewsListWithAds(List<Article> articles, AdType adType) {
    final List<Widget> itemsWithAds = [];
    const int adFrequency = 5; // Insert ad after every 5th article

    for (int i = 0; i < articles.length; i++) {
      // Add the article
      itemsWithAds.add(
        NewsCardMini(
          article: articles[i],
          onTap:
              () => Navigator.pushNamed(
                context,
                '/article',
                arguments: articles[i],
              ),
        ),
      );

      // After every 'adFrequency' articles (and not at the very end), add an ad
      if ((i + 1) % adFrequency == 0 && i < articles.length - 1) {
        itemsWithAds.add(
          // Important: Ensure consistent sizing with news cards
          SizedBox(
            width: 220, // Match width of news cards
            child: Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const InFeedAdBanner(adType: AdType.inFeedDashboard),
            ),
          ),
        );
        debugPrint('[Dashboard] Inserted ad after article ${i + 1}');
      }
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: itemsWithAds.length,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemBuilder: (context, index) => itemsWithAds[index],
    );
  }

  void _scrollToSection(String categoryId) {
    final key = _sectionKeys[categoryId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.0, // Top of the screen
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
