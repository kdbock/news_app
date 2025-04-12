import 'package:http/http.dart' as http;
import 'package:dart_rss/dart_rss.dart';
import 'package:neusenews/models/article.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:neusenews/config/api_endpoints.dart';
import 'package:neusenews/services/article_categorizer_service.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';
import 'dart:async'; // Add this import for TimeoutException
// Add these missing imports
import 'package:intl/intl.dart';

class NewsService {
  // Cache storage for offline mode
  static const String _localNewsCacheKey = 'local_news_cache';
  static const String _sportsNewsCacheKey = 'sports_news_cache';
  static const String _politicsNewsCacheKey = 'politics_news_cache';
  static const String _columnsNewsCacheKey = 'columns_news_cache';
  static const String _mattersOfRecordCacheKey = 'matters_of_record_cache';
  static const String _obituariesCacheKey = 'obituaries_cache';
  static const String _publicNoticesCacheKey = 'public_notices_cache';
  static const String _classifiedsCacheKey = 'classifieds_cache';

  // Cache expiration (4 hours in milliseconds)
  static const int _cacheExpirationMs = 4 * 60 * 60 * 1000;

  final ArticleCategorizerService _categorizerService =
      ArticleCategorizerService();

  // URLs that work in simulator with DNS issues
  static const Map<String, String> _fallbackUrls = {
    'https://www.neusenews.com/index?format=rss':
        'https://mockoon.com/fake-apis/json-placeholder/posts',
    'https://www.neusenewssports.com/news-1?format=rss':
        'https://jsonplaceholder.typicode.com/posts?_limit=10',
    'https://www.ncpoliticalnews.com/news?format=rss':
        'https://jsonplaceholder.typicode.com/posts?_limit=5',
  };

  // Enhanced fetchNewsByUrl with better error handling and timeouts
  Future<List<Article>> fetchNewsByUrl(
    String url, {
    String? cacheKey,
    bool forceRefresh = false,
    int? skip,
    int? take,
  }) async {
    // Use the URL as the cache key if none provided
    final effectiveCacheKey = cacheKey ?? url;

    // Check cache first if not forcing refresh
    if (!forceRefresh) {
      final cachedArticles = await _getFromCache(effectiveCacheKey);
      if (cachedArticles.isNotEmpty) {
        debugPrint(
          'Returning ${cachedArticles.length} cached articles for $effectiveCacheKey',
        );

        // Apply pagination if requested
        if (skip != null || take != null) {
          final startIndex = skip ?? 0;
          final endIndex =
              take != null ? startIndex + take : cachedArticles.length;
          return cachedArticles.sublist(
            startIndex.clamp(0, cachedArticles.length),
            endIndex.clamp(0, cachedArticles.length),
          );
        }

        return cachedArticles;
      }
    }

    debugPrint('Fetching news from: $url');

    // Check if we need to use a fallback URL due to DNS issues
    final String effectiveUrl = _getFallbackUrl(url);
    debugPrint(
      'Using ${effectiveUrl == url ? "original" : "direct IP"} connection to ${Uri.parse(url).host}',
    );

    try {
      // Use a timeout to prevent hanging
      final response = await http
          .get(Uri.parse(effectiveUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Parse the RSS feed
        final List<Article> articles = [];

        try {
          final channel = RssFeed.parse(response.body).items ?? [];

          for (final item in channel ?? []) {
            // Extract article data
            final article = _convertRssItemToArticle(item);
            articles.add(article);
          }

          // Cache results
          await _saveToCache(effectiveCacheKey, articles);

          // Apply pagination if requested
          if (skip != null || take != null) {
            final startIndex = skip ?? 0;
            final endIndex = take != null ? startIndex + take : articles.length;
            return articles.sublist(
              startIndex.clamp(0, articles.length),
              endIndex.clamp(0, articles.length),
            );
          }

          return articles;
        } catch (parseError) {
          debugPrint('Error parsing RSS feed: $parseError');
          throw Exception('Failed to parse feed: $parseError');
        }
      } else {
        debugPrint('HTTP error: ${response.statusCode}');
        throw Exception('Failed to load feed: HTTP ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      debugPrint('Error fetching news from $url: $e');

      // Try to get from cache on timeout as fallback
      final cachedArticles = await _getFromCache(effectiveCacheKey);
      if (cachedArticles.isNotEmpty) {
        debugPrint(
          'Returning ${cachedArticles.length} cached articles after timeout',
        );
        return cachedArticles;
      }

      throw Exception('Connection timed out');
    } catch (e) {
      debugPrint('Error fetching news: $e');

      // Try to get from cache on any error as fallback
      final cachedArticles = await _getFromCache(effectiveCacheKey);
      if (cachedArticles.isNotEmpty) {
        debugPrint(
          'Returning ${cachedArticles.length} cached articles after error',
        );
        return cachedArticles;
      }

      throw Exception('Failed to load feed: $e');
    }
  }

  // Helper method to get fallback URL with direct IP if available
  String _getFallbackUrl(String url) {
    final Uri uri = Uri.parse(url);
    final String host = uri.host;

    if (_fallbackUrls.containsKey(host)) {
      final fallbackIp = _fallbackUrls[host]!;
      return url.replaceFirst(host, fallbackIp);
    }

    return url;
  }

  // Save articles to cache
  Future<void> _saveToCache(String cacheKey, List<Article> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'articles': articles.map((article) => article.toJson()).toList(),
      };
      await prefs.setString(cacheKey, jsonEncode(cacheData));
      debugPrint('Cached ${articles.length} articles for $cacheKey');
    } catch (e) {
      debugPrint('Error caching articles: $e');
    }
  }

  // Get articles from cache
  Future<List<Article>> _getFromCache(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(cacheKey);

      if (cacheJson == null) {
        return [];
      }

      final cacheData = jsonDecode(cacheJson);
      final timestamp = cacheData['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check if cache is expired
      if (now - timestamp > _cacheExpirationMs) {
        debugPrint('Cache expired for $cacheKey');
        return [];
      }

      final articlesList = cacheData['articles'] as List;
      final articles =
          articlesList.map((json) => Article.fromJson(json)).toList();

      debugPrint('Retrieved ${articles.length} articles from $cacheKey cache');
      return articles;
    } catch (e) {
      debugPrint('Error retrieving from cache: $e');
      return [];
    }
  }

  // Category-specific methods with proper URL encoding and caching
  Future<List<Article>> fetchLocalNews({
    bool forceRefresh = false,
    int? skip,
    int? take,
  }) {
    return fetchNewsByUrl(
      'https://www.neusenews.com/index?format=rss',
      cacheKey: _localNewsCacheKey,
      forceRefresh: forceRefresh,
      skip: skip,
      take: take,
    );
  }

  Future<List<Article>> fetchPolitics({
    bool forceRefresh = false,
    int? skip,
    int? take,
  }) {
    return fetchNewsByUrl(
      'https://www.ncpoliticalnews.com/news?format=rss',
      cacheKey: _politicsNewsCacheKey,
      forceRefresh: forceRefresh,
      skip: skip,
      take: take,
    );
  }

  Future<List<Article>> fetchSports({
    bool forceRefresh = false,
    int? skip,
    int? take,
  }) {
    return fetchNewsByUrl(
      'https://www.neusenewssports.com/news-1?format=rss',
      cacheKey: _sportsNewsCacheKey,
      forceRefresh: forceRefresh,
      skip: skip,
      take: take,
    );
  }

  Future<List<Article>> fetchColumns({
    int skip = 0,
    int take = 10,
    bool forceRefresh = false,
  }) {
    return fetchNewsByUrl(
      ApiEndpoints.columnsUrl,
      cacheKey: _columnsNewsCacheKey,
      forceRefresh: forceRefresh,
      skip: skip,
      take: take,
    );
  }

  Future<List<Article>> fetchMattersOfRecord({
    int skip = 0,
    int take = 10,
    bool forceRefresh = false,
  }) {
    return fetchNewsByUrl(
      ApiEndpoints.mattersOfRecordUrl,
      cacheKey: _mattersOfRecordCacheKey,
      forceRefresh: forceRefresh,
      skip: skip,
      take: take,
    );
  }

  Future<List<Article>> fetchObituaries({
    int skip = 0,
    int take = 10,
    bool forceRefresh = false,
  }) {
    return fetchNewsByUrl(
      ApiEndpoints.obituariesUrl,
      cacheKey: _obituariesCacheKey,
      forceRefresh: forceRefresh,
      skip: skip,
      take: take,
    );
  }

  Future<List<Article>> fetchPublicNotices({
    int skip = 0,
    int take = 10,
    bool forceRefresh = false,
  }) {
    return fetchNewsByUrl(
      ApiEndpoints.publicNoticesUrl,
      cacheKey: _publicNoticesCacheKey,
      forceRefresh: forceRefresh,
      skip: skip,
      take: take,
    );
  }

  Future<List<Article>> fetchClassifieds({
    int skip = 0,
    int take = 10,
    bool forceRefresh = false,
  }) {
    return fetchNewsByUrl(
      ApiEndpoints.classifiedsUrl,
      cacheKey: _classifiedsCacheKey,
      forceRefresh: forceRefresh,
      skip: skip,
      take: take,
    );
  }

  // Clear all caches - useful for troubleshooting or forced refresh
  Future<void> clearAllCaches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localNewsCacheKey);
    await prefs.remove(_sportsNewsCacheKey);
    await prefs.remove(_politicsNewsCacheKey);
    await prefs.remove(_columnsNewsCacheKey);
    await prefs.remove(_mattersOfRecordCacheKey);
    await prefs.remove(_obituariesCacheKey);
    await prefs.remove(_publicNoticesCacheKey);
    await prefs.remove(_classifiedsCacheKey);
    debugPrint('All news caches cleared');
  }

  // Helper function to limit string length
  int min(int a, int b) => a < b ? a : b;

  // Helper method to categorize a list of articles
  // TODO: This method is currently unused but will be used for future categorization feature
  Future<void> _categorizeArticles(List<Article> articles) async {
    // Process articles in batches to avoid excessive processing
    const int batchSize = 5;

    for (int i = 0; i < articles.length; i += batchSize) {
      final int end =
          (i + batchSize < articles.length) ? i + batchSize : articles.length;
      final batch = articles.sublist(i, end);

      // Process each article in the batch
      await Future.wait(
        batch.map((article) async {
          // Skip articles that already have categories
          if (article.categoryScores != null &&
              article.primaryCategory != null) {
            return;
          }

          try {
            final scores = await _categorizerService.categorizeArticle(article);

            // Get primary category
            String primaryCategory = 'General';
            if (scores.isNotEmpty) {
              primaryCategory =
                  scores.entries
                      .reduce((a, b) => a.value > b.value ? a : b)
                      .key;
            }

            // Get categories as list (scores > 0.15)
            List<String> categories =
                scores.entries
                    .where((e) => e.value > 0.15)
                    .map((e) => e.key)
                    .toList();

            // Update article fields (need to cast to dynamic since Article is immutable)
            (article as dynamic).categoryScores = scores;
            (article as dynamic).primaryCategory = primaryCategory;
            (article as dynamic).categories = categories;
          } catch (e) {
            debugPrint('Error categorizing article ${article.id}: $e');
          }
        }),
      );

      // Add a small delay between batches to avoid device freezing
      if (end < articles.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  // Categorize a single article (useful for article detail screen)
  Future<Article> categorizeArticle(Article article) async {
    if (article.categoryScores != null && article.primaryCategory != null) {
      return article;
    }

    try {
      final scores = await _categorizerService.categorizeArticle(article);

      // Get primary category
      String primaryCategory = 'General';
      if (scores.isNotEmpty) {
        primaryCategory =
            scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }

      // Get categories as list (scores > 0.15)
      List<String> categories =
          scores.entries
              .where((e) => e.value > 0.15)
              .map((e) => e.key)
              .toList();

      // Create a new article with categorization data
      return Article(
        id: article.id,
        title: article.title,
        author: article.author,
        publishDate: article.publishDate,
        content: article.content,
        excerpt: article.excerpt,
        imageUrl: article.imageUrl,
        url: article.url,
        linkText: article.linkText,
        source: article.source,
        isSponsored: article.isSponsored,
        categoryScores: scores,
        primaryCategory: primaryCategory,
        categories: categories,
      );
    } catch (e) {
      debugPrint('Error categorizing article ${article.id}: $e');
      return article;
    }
  }

  Future<List<Article>> fetchSponsoredArticles({int take = 5}) async {
    try {
      // Implement logic to fetch sponsored articles
      return [];
    } catch (e) {
      debugPrint('Error fetching sponsored articles: $e');
      return [];
    }
  }

  Future<List<Article>> retrieveFromCache(String cacheKey) async {
    try {
      // Replace the incorrect check with a safer alternative
      if (!_isMainIsolate()) {
        debugPrint('Not in main isolate, skipping cache access');
        return [];
      }

      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        final List<dynamic> decoded = json.decode(cachedData);
        return decoded.map((item) => Article.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error retrieving from cache: $e');
      return [];
    }
  }

  // Add this helper method to check if we're in the main isolate
  bool _isMainIsolate() {
    try {
      // This will throw an error if not in the main isolate
      WidgetsBinding.instance;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> preloadMockDataForSimulator() async {
    if (!kDebugMode) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if we already preloaded
      if (prefs.getBool('mock_data_preloaded') == true) return;

      // Add mock articles to cache
      final mockArticles = _generateMockArticles(20);

      // Save to cache keys
      await prefs.setString(
        _localNewsCacheKey,
        json.encode(mockArticles.map((a) => a.toJson()).toList()),
      );
      await prefs.setString(
        _sportsNewsCacheKey,
        json.encode(mockArticles.take(10).map((a) => a.toJson()).toList()),
      );
      await prefs.setString(
        _politicsNewsCacheKey,
        json.encode(mockArticles.take(8).map((a) => a.toJson()).toList()),
      );

      // Mark as preloaded
      await prefs.setBool('mock_data_preloaded', true);

      debugPrint('Successfully preloaded mock data for simulator');
    } catch (e) {
      debugPrint('Error preloading mock data: $e');
    }
  }

  List<Article> _generateMockArticles(int count) {
    return List.generate(
      count,
      (i) => Article(
        id: 'mock-$i',
        title: 'Mock Article $i',
        author: 'Simulator Author',
        content:
            'This is mock content for testing in the simulator environment where DNS resolution might fail.',
        excerpt: 'Mock excerpt for testing in simulator...',
        imageUrl: '',
        publishDate: DateTime.now().subtract(Duration(hours: i)),
        url: 'https://example.com/article-$i',
        categories: ['Local News', 'Test'],
      ),
    );
  }

  // Add the following method to replace the dns_client functionality
  // TODO: This method is currently unused but will be needed for DNS resolution improvements
  Future<String> _resolveHostIP(String hostname) async {
    try {
      // Try direct system DNS lookup first
      final List<InternetAddress> addresses = await InternetAddress.lookup(
        hostname,
      ).timeout(const Duration(seconds: 5));

      if (addresses.isNotEmpty) {
        return addresses.first.address;
      }
    } catch (e) {
      debugPrint('DNS resolution error: $e');
    }

    // Hardcoded IPs for common domains as fallback
    final knownIPs = {
      'www.neusenews.com': '13.33.242.31',
      'www.neusenewssports.com': '54.236.39.101',
      'www.ncpoliticalnews.com': '54.236.39.101',
      'api.openweathermap.org': '99.86.13.12',
    };

    return knownIPs[hostname] ?? hostname;
  }

  // Add these methods to your NewsService class

  // Parse RSS feed XML content into Articles
  // Removed unused method '_parseRssFeed' as it was not referenced anywhere in the code.

  // Helper method to extract image URL from RSS item
  String _extractImageUrl(RssItem item) {
    // Try different ways to get the image URL

    // 1. Try media content
    if (item.media != null && item.media!.contents.isNotEmpty) {
      final mediaUrl = item.media!.contents.first.url;
      if (mediaUrl != null && mediaUrl.isNotEmpty) {
        return mediaUrl;
      }
    }

    // 2. Try enclosure
    if (item.enclosure != null && item.enclosure!.url != null) {
      return item.enclosure!.url!;
    }

    // 3. Try to extract from content or description
    final content = item.content?.value ?? item.description ?? '';
    final imgRegExp = RegExp(r'<img[^>]+src="([^">]+)"');
    final match = imgRegExp.firstMatch(content);
    if (match != null && match.groupCount >= 1) {
      return match.group(1) ?? '';
    }

    // Default empty image URL if nothing found
    return '';
  }

  // Add this method to the NewsService class
  Article _convertRssItemToArticle(RssItem item) {
    // Extract data from RSS item
    final title = item.title ?? 'Untitled';
    final author = item.author ?? 'Neuse News Staff';
    final link = item.link ?? '';
    final publishDate =
        item.pubDate != null
            ? DateFormat('EEE, dd MMM yyyy HH:mm:ss Z').parse(item.pubDate!)
            : DateTime.now();

    // Extract content and format properly
    String content = item.description ?? '';
    content = content.replaceAll(RegExp(r'<[^>]*>'), ''); // Remove HTML tags

    // Extract image URL
    final imageUrl = _extractImageUrl(item);

    // Handle categories safely - ensure non-nullable string list
    final List<String> categories = [];
    for (var category in item.categories) {
      if (category.value != null) {
        categories.add(category.value!);
      }
    }

    return Article(
      id: link.hashCode.toString(),
      title: title,
      author: author,
      url: link,
      imageUrl: imageUrl,
      content: content,
      excerpt:
          content.length > 150 ? '${content.substring(0, 150)}...' : content,
      publishDate: publishDate,
      categories: categories, // Now this is guaranteed to be non-nullable
    );
  }
}
