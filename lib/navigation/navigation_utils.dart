import 'package:flutter/material.dart';

class NavigationUtils {
  // Navigate to a named route
  static Future<T?> navigateTo<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }
  
  // Replace current screen with a new route
  static Future<T?> replaceWith<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.of(context).pushReplacementNamed(routeName, arguments: arguments);
  }
  
  // Pop to a specific route
  static void popUntil(BuildContext context, String routeName) {
    Navigator.of(context).popUntil(ModalRoute.withName(routeName));
  }
  
  // Show a dialog
  static Future<T?> showAppDialog<T>(BuildContext context, Widget dialog) {
    return showDialog<T>(
      context: context,
      builder: (BuildContext context) => dialog,
    );
  }
  
  // Show a bottom sheet
  static Future<T?> showAppBottomSheet<T>(BuildContext context, Widget bottomSheet) {
    return showModalBottomSheet<T>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => bottomSheet,
    );
  }
  
  // Show a snackbar
  static void showSnackBar(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }
}