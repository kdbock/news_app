import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/services/news_service.dart';

class NewsPrefetchRepository {
  // Singleton
  static final NewsPrefetchRepository _instance = NewsPrefetchRepository._internal();
  factory NewsPrefetchRepository() => _instance;
  NewsPrefetchRepository._internal();

  final NewsService _newsService = NewsService();
  
  // Cache of prefetched articles by category
  final Map<String, List<Article>> _prefetchedArticles = {};
  
  // Cache size management
  final int _maxCacheItemsPerCategory = 30;
  
  // Track ongoing prefetch operations to avoid duplicates
  final Map<String, bool> _activePrefetches = {};
  
  // For debugging
  bool get isLogging => false;
  
  void _log(String message) {
    if (isLogging) {
      debugPrint('[NewsPrefetchRepository] $message');
    }
  }
  
  // Check if we have prefetched articles for a category
  List<Article>? getCachedArticles(String category, int page, int pageSize) {
    final cacheKey = _getCacheKey(category, page);
    if (!_prefetchedArticles.containsKey(cacheKey)) return null;
    
    final cached = _prefetchedArticles[cacheKey]!;
    if (cached.length < pageSize) return null;  // Don't return partial pages
    
    _log('Using cached articles for $cacheKey');
    return cached;
  }
  
  // Prefetch articles for a category and page
  Future<void> prefetch(
    String category, 
    int page, 
    int pageSize, {
    bool lowPriority = true,
  }) async {
    final cacheKey = _getCacheKey(category, page);
    
    // Skip if already cached or prefetch in progress
    if (_prefetchedArticles.containsKey(cacheKey) || 
        _activePrefetches[cacheKey] == true) {
      return;
    }
    
    _activePrefetches[cacheKey] = true;
    _log('Prefetching articles for $cacheKey');
    
    try {
      // Use compute to move to background thread if low priority
      final articles = lowPriority 
          ? await compute(_fetchInBackground, _FetchParams(
              category: category,
              skip: page * pageSize,
              pageSize: pageSize,
              service: _newsService,
            ))
          : await _fetch(category, page * pageSize, pageSize);
          
      _prefetchedArticles[cacheKey] = articles;
      _log('Prefetched ${articles.length} articles for $cacheKey');
      
      // Trim cache if needed
      _trimCache(category);
    } catch (e) {
      _log('Error prefetching articles for $cacheKey: $e');
    } finally {
      _activePrefetches[cacheKey] = false;
    }
  }
  
  // Trim cache for a specific category
  void _trimCache(String category) {
    final keysForCategory = _prefetchedArticles.keys
        .where((key) => key.startsWith('$category:'))
        .toList();
    
    if (keysForCategory.length > 3) { // Keep only 3 pages per category
      keysForCategory.sort(); // Sort by page number
      final keysToRemove = keysForCategory.sublist(0, keysForCategory.length - 3);
      for (final key in keysToRemove) {
        _prefetchedArticles.remove(key);
        _log('Removed cache for $key');
      }
    }
  }
  
  // Clear cache for testing or when user explicitly refreshes
  void clearCache([String? category]) {
    if (category != null) {
      final keysToRemove = _prefetchedArticles.keys
          .where((key) => key.startsWith('$category:'))
          .toList();
      
      for (final key in keysToRemove) {
        _prefetchedArticles.remove(key);
      }
      _log('Cleared cache for category: $category');
    } else {
      _prefetchedArticles.clear();
      _log('Cleared entire cache');
    }
  }
  
  // Create a cache key from category and page
  String _getCacheKey(String category, int page) => '$category:$page';
  
  // Fetch articles based on category
  Future<List<Article>> _fetch(String category, int skip, int pageSize) async {
    switch (category.toLowerCase()) {
      case 'localnews':
        return _newsService.fetchLocalNews(skip: skip, take: pageSize);
      case 'sports':
        return _newsService.fetchSports(skip: skip, take: pageSize);
      case 'politics':
        return _newsService.fetchPolitics(skip: skip, take: pageSize);
      case 'columns':
        return _newsService.fetchColumns(skip: skip, take: pageSize);
      case 'obituaries':
        return _newsService.fetchObituaries(skip: skip, take: pageSize);
      case 'publicnotices':
        return _newsService.fetchPublicNotices(skip: skip, take: pageSize);
      case 'classifieds':
        return _newsService.fetchClassifieds(skip: skip, take: pageSize);
      default:
        return _newsService.fetchLocalNews(skip: skip, take: pageSize);
    }
  }
}

// Helper class for background fetching
class _FetchParams {
  final String category;
  final int skip;
  final int pageSize;
  final NewsService service;
  
  _FetchParams({
    required this.category,
    required this.skip,
    required this.pageSize,
    required this.service,
  });
}

// Function to run in background thread
Future<List<Article>> _fetchInBackground(_FetchParams params) async {
  switch (params.category.toLowerCase()) {
    case 'localnews':
      return params.service.fetchLocalNews(skip: params.skip, take: params.pageSize);
    case 'sports':
      return params.service.fetchSports(skip: params.skip, take: params.pageSize);
    case 'politics':
      return params.service.fetchPolitics(skip: params.skip, take: params.pageSize);
    case 'columns':
      return params.service.fetchColumns(skip: params.skip, take: params.pageSize);
    case 'obituaries':
      return params.service.fetchObituaries(skip: params.skip, take: params.pageSize);
    case 'publicnotices':
      return params.service.fetchPublicNotices(skip: params.skip, take: params.pageSize);
    case 'classifieds':
      return params.service.fetchClassifieds(skip: params.skip, take: params.pageSize);
    default:
      return params.service.fetchLocalNews(skip: params.skip, take: params.pageSize);
  }
}