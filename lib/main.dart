import 'package:flutter/material.dart';
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
// Import Stripe package
import 'package:provider/provider.dart';
import 'package:news_app/providers/auth_provider.dart' as app_auth;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase without DefaultFirebaseOptions
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        // Other providers...
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, authProvider, _) {
        return MaterialApp(
          title: 'News App',
          theme: ThemeData(
            primaryColor: const Color(0xFFd2982a),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFd2982a),
            ),
          ),
          // Always start with splash screen regardless of auth status
          home: const SplashScreen(),
          routes: {
            '/login': (context) => const AuthScreen(), // Update route
            '/register':
                (context) =>
                    const AuthScreen(initialTab: 1), // Add initialTab parameter
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
          },
        );
      },
    );
  }
}

// No changes needed to splash_screen.dart - it already has the right navigation
void _navigateToLogin(BuildContext context) {
  Navigator.pushReplacementNamed(context, '/login');
}
