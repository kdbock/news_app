import 'package:flutter/foundation.dart';
import 'package:neusenews/models/article.dart';
import 'package:neusenews/services/news_service.dart';
import 'package:neusenews/services/connectivity_service.dart';
import 'package:neusenews/repositories/news_prefetch_repository.dart';
import 'package:neusenews/repositories/sponsored_article_repository.dart'; // Add this import
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

enum NewsLoadingState { initial, loading, loaded, error }

class NewsProvider extends ChangeNotifier {
  final NewsService _newsService;
  final ConnectivityService _connectivityService;
  final NewsPrefetchRepository _prefetchRepository;
  final SponsoredArticleRepository _sponsoredArticleRepository =
      SponsoredArticleRepository();

  // State management
  NewsLoadingState _state = NewsLoadingState.initial;
  String? _errorMessage;

  // Article collections for various feeds
  List<Article> _localNews = [];
  List<Article> _sportsNews = [];
  List<Article> _politicsNews = [];
  List<Article> _columnsNews = [];
  List<Article> _classifiedsNews = [];
  List<Article> _obituariesNews = [];
  List<Article> _publicNoticesNews = [];
  List<Article> _mattersOfRecordNews = [];
  List<Article> _stateNews = [];
  final List<Article> _sponsoredArticles = [];

  // Getters – adjust these names as needed
  NewsLoadingState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Article> get localNews => _localNews;
  List<Article> get sportsNews => _sportsNews;
  List<Article> get politicsNews => _politicsNews;
  List<Article> get columnsNews => _columnsNews;
  List<Article> get classifiedsNews => _classifiedsNews;
  List<Article> get obituariesNews => _obituariesNews;
  List<Article> get publicNoticesNews => _publicNoticesNews;
  List<Article> get sponsoredArticles => _sponsoredArticles;
  List<Article> get mattersOfRecordNews => _mattersOfRecordNews;
  List<Article> get stateNews => _stateNews;
  // For latest news, we use _localNews
  List<Article> get articles => _localNews;

  // Flag to indicate data is loaded
  bool get isInitialized => _state == NewsLoadingState.loaded;

  // Constructor with dependency injection.
  NewsProvider({
    required NewsService newsService,
    required ConnectivityService connectivityService,
    required NewsPrefetchRepository prefetchRepository,
  }) : _newsService = newsService,
       _connectivityService = connectivityService,
       _prefetchRepository = prefetchRepository;

  // Helper to update state and notify listeners.
  void _setState(NewsLoadingState newState, [String? error]) {
    if (_state != newState || _errorMessage != error) {
      _state = newState;
      _errorMessage = error;
      notifyListeners();
    }
  }

  // Loads all dashboard feeds.
  Future<void> loadDashboardData() async {
    if (_state == NewsLoadingState.loading) return;
    _setState(NewsLoadingState.loading);
    try {
      final localNewsResult = await _newsService.fetchNewsByUrl(
        'https://www.neusenews.com/index/category/Local+News?format=rss',
      );
      final sportsNewsResult = await _newsService.fetchNewsByUrl(
        'https://www.neusenewssports.com/news-1?format=rss',
      );
      final politicsNewsResult = await _newsService.fetchNewsByUrl(
        'https://www.ncpoliticalnews.com/news?format=rss',
      );
      final columnsNewsResult = await _newsService.fetchNewsByUrl(
        'https://www.neusenews.com/index/category/Columns?format=rss',
      );
      final obituariesNewsResult = await _newsService.fetchNewsByUrl(
        'https://www.neusenews.com/index/category/Obituaries?format=rss',
      );
      final publicNoticesNewsResult = await _newsService.fetchNewsByUrl(
        'https://www.neusenews.com/index/category/Public+Notices?format=rss',
      );
      final classifiedsNewsResult = await _newsService.fetchNewsByUrl(
        'https://www.neusenews.com/index/category/Classifieds?format=rss',
      );
      final mattersOfRecordResult = await _newsService.fetchNewsByUrl(
        'https://www.neusenews.com/index/category/Matters+of+Record?format=rss',
      );
      final stateNewsResult = await _newsService.fetchNewsByUrl(
        'https://www.neusenews.com/index/category/NC+News?format=rss',
      );

      _localNews = localNewsResult;
      _sportsNews = sportsNewsResult;
      _politicsNews = politicsNewsResult;
      _columnsNews = columnsNewsResult;
      _obituariesNews = obituariesNewsResult;
      _publicNoticesNews = publicNoticesNewsResult;
      _classifiedsNews = classifiedsNewsResult;
      _mattersOfRecordNews = mattersOfRecordResult;
      _stateNews = stateNewsResult;
      _setState(NewsLoadingState.loaded);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      _setState(NewsLoadingState.error, 'Failed to load news data');
    }
  }

  // A helper to safely load data with a timeout.
  Future<List<Article>> _safeLoadData(
    Future<List<Article>> Function() dataLoader,
  ) async {
    try {
      return await dataLoader().timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Safe data load error: $e');
      return [];
    }
  }

  // Caches articles in the background using SharedPreferences.
  Future<void> _cacheArticlesInBackground(
    String key,
    List<Article> articles,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(articles.map((a) => a.toJson()).toList());
      await prefs.setString(key, data);
    } catch (e) {
      debugPrint('Error caching articles: $e');
    }
  }

  // Fetches sponsored articles.
  Future<List<Article>> _fetchSponsoredArticles() async {
    try {
      return await _newsService.fetchSponsoredArticles();
    } catch (e) {
      debugPrint('Error fetching sponsored articles: $e');
      return [];
    }
  }

  // Prefetches next pages in the background.
  void _prefetchNextPages() {
    Future.delayed(const Duration(seconds: 2), () {
      _prefetchRepository.prefetch('localnews', 1, 10, lowPriority: true);
      Future.delayed(const Duration(milliseconds: 500), () {
        _prefetchRepository.prefetch('sports', 1, 10, lowPriority: true);
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        _prefetchRepository.prefetch('politics', 1, 10, lowPriority: true);
      });
    });
  }

  // Refreshes all data.
  Future<void> refreshAllData() async {
    await loadDashboardData();
  }

  // Loads more articles for a specific category.
  Future<List<Article>> loadMoreArticles(
    String category, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final cached = _prefetchRepository.getCachedArticles(
        category,
        page,
        pageSize,
      );
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      switch (category.toLowerCase()) {
        case 'localnews':
          return await _newsService.fetchLocalNews(
            skip: page * pageSize,
            take: pageSize,
          );
        case 'sports':
          return await _newsService.fetchSports(
            skip: page * pageSize,
            take: pageSize,
          );
        case 'politics':
          return await _newsService.fetchPolitics(
            skip: page * pageSize,
            take: pageSize,
          );
        case 'columns':
          return await _newsService.fetchColumns(
            skip: page * pageSize,
            take: pageSize,
          );
        case 'obituaries':
          return await _newsService.fetchObituaries(
            skip: page * pageSize,
            take: pageSize,
          );
        case 'publicnotices':
          return await _newsService.fetchPublicNotices(
            skip: page * pageSize,
            take: pageSize,
          );
        case 'classifieds':
          return await _newsService.fetchClassifieds(
            skip: page * pageSize,
            take: pageSize,
          );
        default:
          return await _newsService.fetchLocalNews(
            skip: page * pageSize,
            take: pageSize,
          );
      }
    } catch (e) {
      debugPrint('Error loading more $category: $e');
      rethrow;
    }
  }

  // Loads cached article data from SharedPreferences.
  Future<void> loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localNewsJson = prefs.getString('local_news_cache');
      if (localNewsJson != null) {
        _localNews =
            (jsonDecode(localNewsJson) as List)
                .map((data) => Article.fromJson(data))
                .toList();
      }
      final sportsNewsJson = prefs.getString('sports_news_cache');
      if (sportsNewsJson != null) {
        _sportsNews =
            (jsonDecode(sportsNewsJson) as List)
                .map((data) => Article.fromJson(data))
                .toList();
      }
      final politicsNewsJson = prefs.getString('politics_news_cache');
      if (politicsNewsJson != null) {
        _politicsNews =
            (jsonDecode(politicsNewsJson) as List)
                .map((data) => Article.fromJson(data))
                .toList();
      }
      _setState(NewsLoadingState.loaded);
    } catch (e) {
      debugPrint('Error loading cached data: $e');
    }
  }

  // Generates placeholder articles for when the app is offline.
  List<Article> _generatePlaceholderArticles(String category, int count) {
    return List.generate(
      count,
      (index) => Article(
        id: 'placeholder-$category-$index',
        title: 'Sample $category Article ${index + 1}',
        author: 'Neuse News',
        content: 'This is placeholder content for when the app is offline.',
        excerpt: 'This is placeholder content for when the app is offline.',
        imageUrl: '',
        publishDate: DateTime.now().subtract(Duration(days: index)),
        publishedAt: DateTime.now().subtract(Duration(days: index)), // Added required parameter
        url: '',
        categories: [category],
        primaryCategory: category,
      ),
    );
  }

  // Loads mock data for testing.
  Future<void> loadMockData() async {
    _localNews = _generateSampleArticles('Local News', 5);
    _sportsNews = _generateSampleArticles('Sports', 5);
    _politicsNews = _generateSampleArticles('Politics', 5);
    _columnsNews.clear();
    _columnsNews.addAll(_generateSampleArticles('Columns', 5));
    _obituariesNews.clear();
    _obituariesNews.addAll(_generateSampleArticles('Obituaries', 5));
    _publicNoticesNews.clear();
    _publicNoticesNews.addAll(_generateSampleArticles('Public Notices', 5));
    _classifiedsNews.clear();
    _classifiedsNews.addAll(_generateSampleArticles('Classifieds', 5));
    _setState(NewsLoadingState.loaded);
  }

  // Generates sample articles for testing.
  List<Article> _generateSampleArticles(String category, int count) {
    final List<String> sampleTitles = [
      'Local Business Expands Downtown',
      'New Community Center Opens Next Month',
      'County Approves Road Improvement Project',
      'School Board Announces New Programs',
      'Police Department Hosting Community Event',
    ];
    final List<String> sampleAuthors = [
      'John Smith',
      'Sarah Johnson',
      'Michael Williams',
      'Emily Davis',
      'Robert Brown',
    ];
    final List<String> sampleImages = [
      'https://images.pexels.com/photos/2662116/pexels-photo-2662116.jpeg',
      'https://images.pexels.com/photos/1563356/pexels-photo-1563356.jpeg',
      'https://images.pexels.com/photos/3184360/pexels-photo-3184360.jpeg',
      'https://images.pexels.com/photos/3184339/pexels-photo-3184339.jpeg',
      'https://images.pexels.com/photos/2422294/pexels-photo-2422294.jpeg',
    ];
    return List.generate(
      count,
      (index) => Article(
        id: 'sample-$category-$index',
        title: '$category: ${sampleTitles[index % sampleTitles.length]}',
        author: sampleAuthors[index % sampleAuthors.length],
        content:
            'This is sample content for the article about ${sampleTitles[index % sampleTitles.length].toLowerCase()}.',
        excerpt:
            'This is a sample article excerpt for ${category.toLowerCase()} news. The full article contains more details about this topic.',
        imageUrl: sampleImages[index % sampleImages.length],
        publishDate: DateTime.now().subtract(Duration(hours: index * 4)),
        publishedAt: DateTime.now().subtract(Duration(hours: index * 4)), // Added required parameter
        url: 'https://example.com/article/$index',
        categories: [category],
        primaryCategory: category,
      ),
    );
  }

  // Loads sponsored articles from the repository
  Future<void> loadSponsoredArticles() async {
    try {
      final articles =
          await _sponsoredArticleRepository.fetchPublishedArticles();
      _sponsoredArticles.clear();
      _sponsoredArticles.addAll(articles);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading sponsored articles: $e');
    }
  }
}
