import 'package:flutter/material.dart';

/// A service that provides a global navigator key and navigation methods
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Navigate to a named route
  static Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed(routeName, arguments: arguments);
  }

  /// Replace the current route with a new one
  static Future<dynamic> replaceTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushReplacementNamed(routeName, arguments: arguments);
  }

  /// Pop to the first route and navigate to a new one
  static Future<dynamic> navigateToAndRemoveUntil(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      routeName,
      (Route<dynamic> route) => false,
      arguments: arguments,
    );
  }

  /// Go back
  static void goBack() {
    return navigatorKey.currentState!.pop();
  }

  /// Check if can go back
  static bool canGoBack() {
    return navigatorKey.currentState!.canPop();
  }
}