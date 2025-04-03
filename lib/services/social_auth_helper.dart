// Add this helper file to resolve social auth issues:
// filepath: /Users/kristybock/news_app/lib/services/social_auth_helper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io' show Platform;

class SocialAuthHelper {
  static Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      // Initialize GoogleSignIn with proper configuration
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: ${e.toString()}')),
      );
      return null;
    }
  }

  static Future<UserCredential?> signInWithApple(BuildContext context) async {
    try {
      final appleProvider = AppleAuthProvider();
      if (Platform.isIOS || Platform.isMacOS) {
        // Native sign-in for iOS/macOS
        return await FirebaseAuth.instance.signInWithProvider(appleProvider);
      } else {
        // Web-based sign-in for Android
        return await FirebaseAuth.instance.signInWithPopup(appleProvider);
      }
    } catch (e) {
      debugPrint('Apple sign-in error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple sign-in failed: ${e.toString()}')),
      );
      return null;
    }
  }
}
