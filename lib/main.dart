import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // This will be created by flutterfire configure
import 'package:neusenews/screens/splash_screen.dart';
import 'package:neusenews/screens/login_screen.dart';
import 'package:neusenews/screens/home_screen.dart';
import 'package:neusenews/screens/dashboard_screen.dart';
import 'package:neusenews/screens/article_detail_screen.dart';
import 'package:neusenews/screens/weather_screen.dart';
// Add imports for all category screens
import 'package:neusenews/screens/local_news_screen.dart';
import 'package:neusenews/screens/politics_screen.dart';
import 'package:neusenews/screens/sports_screen.dart';
import 'package:neusenews/screens/obituaries_screen.dart';
import 'package:neusenews/screens/columns_screen.dart';
import 'package:neusenews/screens/public_notices_screen.dart';
import 'package:neusenews/screens/classifieds_screen.dart';
import 'package:neusenews/screens/profile_screen.dart';
import 'package:neusenews/screens/edit_profile_screen.dart';
import 'package:neusenews/screens/calendar_screen.dart';
import 'package:neusenews/screens/submit_sponsored_event.dart';
import 'package:neusenews/screens/news_screen.dart';
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
        ),
        // Always start with splash screen regardless of auth status
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const AuthScreen(),
          '/register': (context) => const AuthScreen(initialTab: 1),
          '/dashboard': (context) => const DashboardScreen(),
          '/splash': (context) => const SplashScreen(),
          '/home': (context) => const HomeScreen(),
          '/article': (context) => const ArticleDetailScreen(),
          '/weather': (context) => const WeatherScreen(),
          '/local-news': (context) => const LocalNewsScreen(),
          '/politics': (context) => const PoliticsScreen(),
          '/sports': (context) => const SportsScreen(),
          '/obituaries': (context) => const ObituariesScreen(),
          '/columns': (context) => const ColumnsScreen(),
          '/public-notices': (context) => const PublicNoticesScreen(),
          '/classifieds': (context) => const ClassifiedsScreen(),
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
          '/news': (context) => const NewsScreen(),
          '/calendar': (context) => const CalendarScreen(),
          '/submit-sponsored-event':
              (context) => const SubmitSponsoredEventScreen(),
        },
      ),
    );
  }
}
