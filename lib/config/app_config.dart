class AppConfig {
  // API Keys
  static const String weatherApiKey = 'd7265370b126555980c6dc783ebe185e';
  
  // Default values
  static const String defaultZipCode = '28501'; // Kinston, NC
  
  // Feature flags
  static const bool enableAnalytics = true;
  static const bool enableNotifications = true;
  static const bool enableAds = true;
  
  // App version
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;
  
  // Firebase collections
  static const String usersCollection = 'users';
  static const String adsCollection = 'ads';
  static const String eventsCollection = 'events';
  static const String articlesCollection = 'articles';
  
  // Cache durations
  static const int weatherCacheDuration = 30; // minutes
  static const int newsCacheDuration = 15; // minutes
  static const int eventsCacheDuration = 60; // minutes
}