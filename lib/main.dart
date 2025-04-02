import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io'; // Add this import for File type
import 'firebase_options.dart';

// Core screens
import 'package:neusenews/screens/splash_screen.dart';
import 'package:neusenews/screens/dashboard_screen.dart';
import 'package:neusenews/screens/settings_screen.dart';

// User features
import 'package:neusenews/features/user/screens/login_screen.dart';
import 'package:neusenews/features/user/screens/profile_screen.dart';
import 'package:neusenews/features/user/screens/edit_profile_screen.dart';
import 'package:neusenews/features/user/screens/investor_dashboard_screen.dart';
import 'package:neusenews/features/user/screens/my_contributions_screen.dart';
import 'package:neusenews/features/user/screens/submit_sponsored_article.dart';

// News features - using namespaced imports to avoid ambiguity
import 'package:neusenews/features/news/screens/article_detail_screen.dart';
import 'package:neusenews/features/news/screens/news_screen.dart';
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
import 'package:neusenews/features/news/screens/matters_of_record.dart'
    as matters_of_record;
import 'package:neusenews/features/news/screens/news_detail_screen.dart';
import 'package:neusenews/features/news/screens/submit_news_tip.dart';

// Weather features
import 'package:neusenews/features/weather/screens/weather_screen.dart';

// Events features
import 'package:neusenews/features/events/screens/calendar_screen.dart';
import 'package:neusenews/features/events/screens/submit_sponsored_event.dart';

// Ads features
import 'package:neusenews/features/ads/screens/ad_creation_screen.dart';
import 'package:neusenews/features/ads/screens/ad_checkout_screen.dart';
import 'package:neusenews/features/ads/screens/ad_confirmation_screen.dart';
import 'package:neusenews/features/ads/screens/advertiser_dashboard_screen.dart';
import 'package:neusenews/features/ads/screens/advertising_options_screen.dart';
import 'package:neusenews/models/ad.dart'; // Import Ad model

// Admin features
import 'package:neusenews/features/admin/screens/admin_dashboard_screen.dart';
import 'package:neusenews/features/admin/screens/review_ads_screen.dart';
import 'package:neusenews/features/admin/screens/review_sponsored_content.dart';
import 'package:neusenews/features/admin/screens/admin_users_screen.dart';

// Provider imports
import 'package:provider/provider.dart';
import 'package:neusenews/providers/auth_provider.dart' as app_auth;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if Firebase is already initialized to prevent duplicate initialization
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<app_auth.AuthProvider>(
          create: (_) => app_auth.AuthProvider(),
        ),
        // Add other providers here if needed
      ],
      child: MaterialApp(
        title: 'Neuse News',
        theme: ThemeData(
          primaryColor: const Color(0xFFd2982a),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFd2982a)),
          // Add more theme configuration for consistency
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFd2982a),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFd2982a),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        // Always start with splash screen regardless of auth status
        home: const SplashScreen(),
        routes: {
          // Core screens
          '/splash': (context) => const SplashScreen(),
          '/home': (context) => const DashboardScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/settings': (context) => const SettingsScreen(),

          // Auth and user screens
          '/login': (context) => const AuthScreen(),
          '/register': (context) => const AuthScreen(initialTab: 1),
          '/profile': (context) => const ProfileScreen(),
          '/edit_profile':
              (context) => const EditProfileScreen(
                firstName: '',
                lastName: '',
                email: '',
                phone: '',
                zipCode: '',
                birthday: '',
                textAlerts: false,
                dailyDigest: false,
                sportsNewsletter: false,
                politicalNewsletter: false,
              ),
          '/investor-dashboard': (context) => const InvestorDashboardScreen(),
          '/my-contributions': (context) => const MyContributionsScreen(),

          // News screens
          '/article': (context) => const ArticleDetailScreen(),
          '/news': (context) => const NewsScreen(),
          '/local-news': (context) => const local_news.LocalNewsScreen(),
          '/politics': (context) => const politics.PoliticsScreen(),
          '/sports': (context) => const sports.SportsScreen(),
          '/obituaries': (context) => const obituaries.ObituariesScreen(),
          '/columns': (context) => const columns.ColumnsScreen(),
          '/public-notices':
              (context) => const public_notices.PublicNoticesScreen(),
          '/classifieds': (context) => const classifieds.ClassifiedsScreen(),
          '/matters-of-record':
              (context) => const matters_of_record.MattersOfRecordScreen(),
          '/submit-news-tip': (context) => const SubmitNewsTipScreen(),

          // Weather screens
          '/weather': (context) => const WeatherScreen(),

          // Events screens
          '/calendar': (context) => const CalendarScreen(),
          '/submit-sponsored-event':
              (context) => const SubmitSponsoredEventScreen(),
          '/submit-sponsored-article':
              (context) => const SubmitSponsoredArticleScreen(),

          // Ads screens
          '/advertising-options': (context) => const AdvertisingOptionsScreen(),
          '/create-ad': (context) => const AdCreationScreen(),

          // Using wrapper classes for screens that require parameters
          '/ad-checkout': (context) => const AdCheckoutWrapper(),
          '/ad-confirmation': (context) => const AdConfirmationWrapper(),
          '/advertiser-dashboard':
              (context) => const AdvertiserDashboardScreen(),

          // Admin screens
          '/admin-dashboard': (context) => const AdminDashboardScreen(),
          '/review-ads': (context) => const ReviewAdsScreen(),
          '/review-sponsored-content':
              (context) => const ReviewSponsoredContentScreen(),
          '/admin-users': (context) => const AdminUsersScreen(),
        },
      ),
    );
  }
}

// Wrapper class for AdCheckoutScreen that handles the required ad parameter
class AdCheckoutWrapper extends StatelessWidget {
  const AdCheckoutWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the ad from arguments or redirect to ad creation
    final ad = ModalRoute.of(context)?.settings.arguments as Ad?;

    // If no ad is provided, show a message and redirect option
    if (ad == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ad Checkout')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please create or select an ad first'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/create-ad'),
                child: const Text('Create Ad'),
              ),
            ],
          ),
        ),
      );
    }

    // Create a temporary empty file for the imageFile parameter
    // Note: This is a workaround. The proper solution would be to modify AdCheckoutScreen
    // to accept a nullable File parameter, but we'll create an empty file as a temporary solution.
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/temp_placeholder.png');

    // Otherwise show the actual checkout screen
    return AdCheckoutScreen(ad: ad, imageFile: tempFile);
  }
}

// Wrapper class for AdConfirmationScreen that handles the required ad parameter
class AdConfirmationWrapper extends StatelessWidget {
  const AdConfirmationWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the ad from arguments
    final ad = ModalRoute.of(context)?.settings.arguments as Ad?;

    // If no ad is provided, show a generic confirmation
    if (ad == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ad Confirmation')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Your ad has been processed'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    () => Navigator.pushNamed(context, '/advertiser-dashboard'),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    // Otherwise show the actual confirmation screen
    return AdConfirmationScreen(ad: ad);
  }
}
