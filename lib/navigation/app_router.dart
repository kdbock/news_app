import 'package:flutter/material.dart';
import 'package:neusenews/navigation/routes.dart';

import 'package:neusenews/screens/splash_screen.dart';
import 'package:neusenews/screens/dashboard_screen.dart';
import 'package:neusenews/screens/settings_screen.dart';

import 'package:neusenews/features/users/screens/login_screen.dart';
import 'package:neusenews/features/users/screens/profile_screen.dart';
import 'package:neusenews/features/users/screens/edit_profile_screen.dart';

// Import other screen files

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case Routes.home:
      case Routes.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case Routes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      
      // Auth routes
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case Routes.register:
        return MaterialPageRoute(builder: (_) => const LoginScreen(initialTab: 1));
      
      // User routes
      case Routes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case Routes.editProfile:
        // Handle EditProfileScreen with parameters
        return MaterialPageRoute(
          builder: (_) {
            if (settings.arguments != null) {
              // You would handle the arguments here
              return const EditProfileScreen(
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
              );
            } else {
              // Provide default values
              return const EditProfileScreen(
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
              );
            }
          },
        );
        
      // You would continue with other routes in a similar pattern
      // ...

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}