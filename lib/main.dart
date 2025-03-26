import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:news_app/screens/splash_screen.dart';
import 'package:news_app/screens/login_screen.dart';
import 'package:news_app/screens/home_screen.dart';
import 'package:news_app/screens/dashboard_screen.dart';
import 'package:news_app/screens/article_detail_screen.dart';
import 'package:news_app/screens/weather_screen.dart';
// Add imports for all category screens
import 'package:news_app/screens/local_news_screen.dart';
import 'package:news_app/screens/politics_screen.dart';
import 'package:news_app/screens/sports_screen.dart';
import 'package:news_app/screens/obituaries_screen.dart';
import 'package:news_app/screens/columns_screen.dart';
import 'package:news_app/screens/public_notices_screen.dart';
import 'package:news_app/screens/classifieds_screen.dart';
import 'package:news_app/screens/profile_screen.dart';
import 'package:news_app/screens/edit_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Set preferred orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neuse News',
      theme: ThemeData(
        primaryColor: const Color(0xFFd2982a), // Gold
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFd2982a),
          primary: const Color(0xFFd2982a),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      // Start with splash screen instead
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/dashboard': (context) => const DashboardScreen(),
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
      },
    );
  }
}
