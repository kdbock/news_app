import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neusenews/models/article.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarksRepository extends ChangeNotifier {
  static const String _localBookmarksKey = 'bookmarked_articles';
  
  List<Article> _bookmarkedArticles = [];
  bool _isLoading = false;
  
  List<Article> get bookmarkedArticles => _bookmarkedArticles;
  bool get isLoading => _isLoading;
  
  // Singleton pattern
  static final BookmarksRepository _instance = BookmarksRepository._internal();
  
  factory BookmarksRepository() => _instance;
  
  BookmarksRepository._internal();

  // Initialize repository by loading bookmarks
  Future<void> initialize() async {
    await loadBookmarks();
  }

  // Load bookmarks from SharedPreferences and Firebase if user is logged in
  Future<void> loadBookmarks() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getString(_localBookmarksKey) ?? '[]';
      final List<dynamic> bookmarksList = jsonDecode(bookmarksJson);
      
      // Convert JSON to Article objects
      final List<Article> localBookmarks = bookmarksList
          .map((json) => Article.fromJson(json))
          .toList();
      
      // If user is logged in, fetch cloud bookmarks and merge
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cloudBookmarks = await _fetchCloudBookmarks(user.uid);
        
        // Merge local and cloud bookmarks, removing duplicates
        final Map<String, Article> mergedBookmarks = {};
        
        // Add local bookmarks to map
        for (final article in localBookmarks) {
          mergedBookmarks[article.id] = article;
        }
        
        // Add cloud bookmarks to map, overwriting any duplicates
        for (final article in cloudBookmarks) {
          mergedBookmarks[article.id] = article;
        }
        
        _bookmarkedArticles = mergedBookmarks.values.toList();
        
        // Sync merged bookmarks back to cloud
        await _syncBookmarksToCloud(user.uid, _bookmarkedArticles);
      } else {
        // Just use local bookmarks
        _bookmarkedArticles = localBookmarks;
      }
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch bookmarks from Cloud Firestore
  Future<List<Article>> _fetchCloudBookmarks(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .get();
          
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Reconstruct the Article from Firestore data
        return Article.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching cloud bookmarks: $e');
      return [];
    }
  }

  // Sync bookmarks to Cloud Firestore
  Future<void> _syncBookmarksToCloud(String userId, List<Article> bookmarks) async {
    try {
      // Batch write for efficiency
      final batch = FirebaseFirestore.instance.batch();
      final bookmarksRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bookmarks');
          
      // Get existing bookmarks to avoid unnecessary writes
      final snapshot = await bookmarksRef.get();
      final existingIds = snapshot.docs.map((doc) => doc.id).toSet();
      
      // Articles to add (those not already in Firestore)
      final articlesToAdd = bookmarks
          .where((article) => !existingIds.contains(article.id))
          .toList();
          
      // Add new bookmarks
      for (final article in articlesToAdd) {
        final docRef = bookmarksRef.doc(article.id);
        batch.set(docRef, article.toJson());
      }
      
      await batch.commit();
      
      // Update the timestamp of the last sync
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'lastBookmarkSync': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error syncing bookmarks to cloud: $e');
    }
  }

  // Check if an article is bookmarked
  bool isBookmarked(String articleId) {
    return _bookmarkedArticles.any((article) => article.id == articleId);
  }

  // Toggle bookmark status
  Future<bool> toggleBookmark(Article article) async {
    try {
      final isCurrentlyBookmarked = isBookmarked(article.id);
      
      if (isCurrentlyBookmarked) {
        // Remove from bookmarks
        _bookmarkedArticles.removeWhere((a) => a.id == article.id);
      } else {
        // Add to bookmarks
        _bookmarkedArticles.add(article);
      }
      
      // Update local storage
      await _saveBookmarksToLocal(_bookmarkedArticles);
      
      // Update cloud if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _updateCloudBookmark(user.uid, article, !isCurrentlyBookmarked);
      }
      
      notifyListeners();
      return !isCurrentlyBookmarked;
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      return isBookmarked(article.id);
    }
  }

  // Save bookmarks to SharedPreferences
  Future<void> _saveBookmarksToLocal(List<Article> bookmarks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = jsonEncode(
        bookmarks.map((article) => article.toJson()).toList()
      );
      await prefs.setString(_localBookmarksKey, bookmarksJson);
    } catch (e) {
      debugPrint('Error saving bookmarks locally: $e');
    }
  }

  // Update a single bookmark in Cloud Firestore
  Future<void> _updateCloudBookmark(
    String userId, 
    Article article, 
    bool isBookmarked
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .doc(article.id);
          
      if (isBookmarked) {
        // Add bookmark
        await docRef.set(article.toJson());
      } else {
        // Remove bookmark
        await docRef.delete();
      }
    } catch (e) {
      debugPrint('Error updating cloud bookmark: $e');
    }
  }
}