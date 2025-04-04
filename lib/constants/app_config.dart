class AppConfig {
  // API Keys and IDs
  static const String androidClientId =
      "236600949564-YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com";
  static const String iosClientId =
      "236600949564-eclf8t63s95aaasic4emeol55eh32hdt.apps.googleusercontent.com";
  static const String webClientId =
      "236600949564-5nsalftfmgc6u1r3am1lcsbpp14m71ct.apps.googleusercontent.com";

  // URL Endpoints
  static const String baseUrl = "https://neusenews.com";
  static const String sponsoredContentUrl =
      "https://www.neusenews.com/sponsored";
  static const String classifiedsOrderUrl =
      "https://www.neusenews.com/order-classifieds";

  // RSS Feed URLs
  static const Map<String, String> rssFeedUrls = {
    'main': 'https://www.neusenews.com/index?format=rss',
    'sports': 'https://www.neusenewssports.com/news-1?format=rss',
    'politics': 'https://www.ncpoliticalnews.com/news?format=rss',
    'business': 'https://www.magicmilemedia.com/blog?format=rss',
    'localNews':
        'https://www.neusenews.com/index/category/Local+News?format=rss',
    'stateNews': 'https://www.neusenews.com/index/category/NC+News?format=rss',
    'columns': 'https://www.neusenews.com/index/category/Columns?format=rss',
    'mattersOfRecord':
        'https://www.neusenews.com/index/category/Matters+of+Record?format=rss',
    'obituaries':
        'https://www.neusenews.com/index/category/Obituaries?format=rss',
    'publicNotices':
        'https://www.neusenews.com/index/category/Public+Notices?format=rss',
    'classifieds':
        'https://www.neusenews.com/index/category/Classifieds?format=rss',
  };

  // Cache Config
  static const int newsCacheDuration = 30; // in minutes
  static const int weatherCacheDuration = 60; // in minutes

  // App Configuration
  static const bool enablePushNotifications = true;
  static const bool enableInAppPurchases = true;
  static const bool showAds = true;
  static const int maxCachedArticles = 100;

  // Feature Flags
  static const bool enableContributorFeatures = true;
  static const bool enableInvestorFeatures = true;
  static const bool enableCalendarSubmission = true;
}
