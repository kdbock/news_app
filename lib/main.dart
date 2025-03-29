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
// Import Stripe package
import 'package:provider/provider.dart';
import 'package:neusenews/providers/auth_provider.dart' as app_auth;
// For logging

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
          title: 'Neuse News',
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
