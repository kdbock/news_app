import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Log article view event
  Future<void> logArticleView(
    String articleId,
    String title,
    String category,
  ) async {
    try {
      await _analytics.logEvent(
        name: 'article_view',
        parameters: {
          'article_id': articleId,
          'article_title': title,
          'article_category': category,
        },
      );

      // Store in Firestore for custom analytics
      await _incrementArticleView(articleId);
    } catch (e) {
      print('Error logging article view: $e');
    }
  }

  // Increment article view count in Firestore
  Future<void> _incrementArticleView(String articleId) async {
    try {
      DocumentReference articleRef = _firestore
          .collection('article_metrics')
          .doc(articleId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(articleRef);

        if (!snapshot.exists) {
          transaction.set(articleRef, {
            'views': 1,
            'last_updated': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(articleRef, {
            'views': FieldValue.increment(1),
            'last_updated': FieldValue.serverTimestamp(),
          });
        }
      });

      // Also store user-specific view if logged in
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('user_activity')
            .doc(user.uid)
            .collection('article_views')
            .add({
              'article_id': articleId,
              'timestamp': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      print('Error incrementing article view: $e');
    }
  }

  // Log search event
  Future<void> logSearch(String searchTerm) async {
    try {
      await _analytics.logSearch(searchTerm: searchTerm);

      // Store search term in Firestore for trending searches
      await _firestore.collection('search_analytics').add({
        'search_term': searchTerm,
        'timestamp': FieldValue.serverTimestamp(),
        'user_id': _auth.currentUser?.uid,
      });
    } catch (e) {
      print('Error logging search: $e');
    }
  }

  // Log app open event
  Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
    } catch (e) {
      print('Error logging app open: $e');
    }
  }

  // Log login event
  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      print('Error logging login: $e');
    }
  }

  // Log signup event
  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      print('Error logging sign up: $e');
    }
  }

  // Get trending articles
  Future<List<Map<String, dynamic>>> getTrendingArticles() async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('article_metrics')
              .orderBy('views', descending: true)
              .limit(5)
              .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error getting trending articles: $e');
      return [];
    }
  }

  // Set user properties
  Future<void> setUserProperties({String? userType, String? zipCode}) async {
    try {
      if (userType != null) {
        await _analytics.setUserProperty(name: 'user_type', value: userType);
      }
      if (zipCode != null) {
        await _analytics.setUserProperty(name: 'zip_code', value: zipCode);
      }
    } catch (e) {
      print('Error setting user properties: $e');
    }
  }

  // Add this method to the AnalyticsService class:
  Future<void> incrementArticleView(String articleId) async {
    try {
      // Implement your analytics logic here
      debugPrint('Incremented view for article: $articleId');
    } catch (e) {
      debugPrint('Error tracking article view: $e');
    }
  }

  // In analytics_service.dart, add proper Firebase Analytics implementation
  Future<void> trackArticleView(String articleId) async {
    await _analytics.logEvent(
      name: 'article_view',
      parameters: {'article_id': articleId},
    );

    // Also store in Firestore for custom analytics
    await _firestore.collection('article_metrics').doc(articleId).update({
      'views': FieldValue.increment(1),
      'last_viewed': FieldValue.serverTimestamp(),
    });
  }
}
