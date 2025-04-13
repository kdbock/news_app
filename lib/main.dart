import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:neusenews/features/news/screens/sponsored_articles_screen.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:neusenews/di/service_locator.dart';
import 'package:neusenews/theme/app_theme.dart';
import 'package:neusenews/di/app_services.dart';
import 'package:neusenews/widgets/bottom_nav_bar.dart';

// Import services and providers
import 'package:neusenews/services/connectivity_service.dart';
import 'package:neusenews/providers/news_provider.dart';
import 'package:neusenews/providers/weather_provider.dart';
import 'package:neusenews/providers/events_provider.dart';
import 'package:neusenews/providers/auth_provider.dart' as app_auth;

// Import screens
import 'package:neusenews/screens/splash_screen.dart';
import 'package:neusenews/screens/dashboard_screen.dart';
import 'package:neusenews/features/news/screens/news_screen.dart';
import 'package:neusenews/features/weather/screens/weather_screen.dart';
import 'package:neusenews/features/events/screens/calendar_screen.dart';
import 'package:neusenews/features/news/screens/base_category_screen.dart';
import 'package:neusenews/features/news/screens/article_detail_screen.dart';
import 'package:neusenews/features/news/screens/bookmarks_screen.dart';
import 'package:neusenews/features/users/screens/profile_screen.dart';
import 'package:neusenews/features/news/screens/submit_news_tip.dart';
import 'package:neusenews/features/events/screens/submit_sponsored_event.dart';
import 'package:neusenews/features/users/screens/submit_sponsored_article.dart';
import 'package:neusenews/features/advertising/screens/advertising_options_screen.dart';
import 'package:neusenews/features/admin/screens/admin_dashboard_screen.dart';
import 'package:neusenews/features/users/screens/my_contributions_screen.dart';
import 'package:neusenews/features/users/screens/investor_dashboard_screen.dart';
import 'package:neusenews/screens/settings_screen.dart';
import 'package:neusenews/features/users/screens/login_screen.dart';
import 'package:neusenews/features/events/screens/event_detail_screen.dart';
// Add imports for new authentication screens
import 'package:neusenews/features/users/screens/register_screen.dart';
import 'package:neusenews/features/users/screens/password_reset_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Only initialize if not already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // If duplicate-app error occurs, ignore it and continue
    if (e.toString().contains("duplicate-app")) {
      // Log and move on
      debugPrint("Firebase already initialized.");
    } else {
      // Rethrow or handle other errors as needed
      rethrow;
    }
  }

  // Initialize the service locator
  await setupServiceLocator();

  // Retrieve services from the service locator
  final services = AppServices(
    connectivityService: serviceLocator<ConnectivityService>(),
    newsProvider: serviceLocator<NewsProvider>(),
    weatherProvider: serviceLocator<WeatherProvider>(),
    eventsProvider: serviceLocator<EventsProvider>(),
  );

  runApp(MyApp(services: services));
}

class MyApp extends StatefulWidget {
  final AppServices services;

  const MyApp({super.key, required this.services});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ConnectivityService>.value(
          value: widget.services.connectivityService,
        ),
        ChangeNotifierProvider<NewsProvider>.value(
          value: widget.services.newsProvider,
        ),
        ChangeNotifierProvider<WeatherProvider>.value(
          value: widget.services.weatherProvider,
        ),
        ChangeNotifierProvider<EventsProvider>.value(
          value: widget.services.eventsProvider,
        ),
        ChangeNotifierProvider<app_auth.AuthProvider>(
          create: (_) => app_auth.AuthProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Neuse News',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        routes: {
          '/dashboard': (context) => const HomeNavigator(),
          '/home': (context) => const HomeNavigator(),
          '/news': (context) => const NewsScreen(),
          '/weather': (context) => const WeatherScreen(),
          '/calendar': (context) => const CalendarScreen(),
          '/sponsored': (context) => const SponsoredArticlesScreen(),
          '/article': (context) => const ArticleDetailScreen(),
          '/bookmarks': (context) => const BookmarksScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/submit-news-tip': (context) => const SubmitNewsTipScreen(),
          '/submit-sponsored-event':
              (context) => const SubmitSponsoredEventScreen(),
          '/submit-sponsored-article':
              (context) => const SubmitSponsoredArticleScreen(),
          '/advertising-options': (context) => const AdvertisingOptionsScreen(),
          '/admin-dashboard': (context) => const AdminDashboardScreen(),
          '/my-contributions': (context) => const MyContributionsScreen(),
          '/investor-dashboard': (context) => const InvestorDashboardScreen(),
          '/settings': (context) => const SettingsScreen(),
          // Authentication routes
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/password-reset': (context) => const PasswordResetScreen(),
          '/base-category':
              (context) => const BaseCategoryScreen(
                category: 'defaultCategory',
                url: 'defaultUrl',
                categoryColor: Colors.blue,
              ),
          '/base-category/:category': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map;
            return BaseCategoryScreen(
              category: args['category'],
              url: args['url'],
              categoryColor: args['categoryColor'],
              showAppBar: args['showAppBar'] ?? true,
              showBottomNav: args['showBottomNav'] ?? true,
            );
          },
          '/event': (context) => const EventDetailScreen(),
        },
      ),
    );
  }
}

// New persistent navigation class
class HomeNavigator extends StatefulWidget {
  const HomeNavigator({super.key});

  @override
  State<HomeNavigator> createState() => _HomeNavigatorState();
}

class _HomeNavigatorState extends State<HomeNavigator> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swiping
        children: const [
          DashboardScreen(showBottomNav: false),
          NewsScreen(showBottomNav: false),
          WeatherScreen(showBottomNav: false),
          CalendarScreen(showBottomNav: false),
        ],
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.jumpToPage(index);
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
