import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:news_app/screens/splash_screen.dart';
import 'package:news_app/screens/login_screen.dart';
import 'package:news_app/screens/home_screen.dart';
// Import other screens as needed

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neuse News',
      debugShowCheckedModeBanner: false, // Removes the debug banner
      theme: ThemeData(
        primaryColor: const Color(0xFFd2982a), // Gold
        scaffoldBackgroundColor: Colors.white, // White background
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFd2982a), // Gold header
          titleTextStyle: TextStyle(
            color: Color(0xFF2d2c31), // Dark gray text
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFd2982a), // Gold button
            foregroundColor: Colors.white, // White text
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Modern corners
            ),
          ),
        ),
      ),
      // Both approaches work - you can use either one
      home: const SplashScreen(), // Direct approach
      // Named routes for deeper navigation
      routes: {
        '/login': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        // Add other routes as needed
      },
    );
  }
}
