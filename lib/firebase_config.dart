import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import
import 'package:flutter/foundation.dart';
import 'package:neusenews/firebase_options.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Configure Firebase for better offline support
      // This makes Firestore and other Firebase services work better offline
      await _configureFirebaseOfflineSupport();
    } catch (e) {
      debugPrint("Firebase initialization error: $e");
    }
  }

  static Future<void> _configureFirebaseOfflineSupport() async {
    // Configure Firestore to handle offline support better
    try {
      // These settings help Firestore work better in environments with poor connectivity
      // Fix the settings assignment syntax
      FirebaseFirestore.instance.settings = Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        sslEnabled: true,
      );

      // Optional: Set additional Firestore configuration
      // Note: PersistenceSettings needs to be part of the Settings constructor
      // not a separate method call
    } catch (e) {
      debugPrint("Error configuring Firestore offline settings: $e");
    }
  }
}
