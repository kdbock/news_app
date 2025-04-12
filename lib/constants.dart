
// Re-export constants for easier imports
export 'constants/app_colors.dart';
export 'constants/app_strings.dart';
export 'constants/app_assets.dart';
export 'constants/api_constants.dart';

// App-wide constants
class Constants {
  // App version
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;
  
  // Cache durations
  static const Duration weatherCacheDuration = Duration(minutes: 30);
  static const Duration newsCacheDuration = Duration(minutes: 15);
  static const Duration eventsCacheDuration = Duration(hours: 1);
  
  // Pagination defaults
  static const int defaultPageSize = 10;
  
  // Max upload sizes
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  
  // Ad limits
  static const int maxActiveAdsPerBusiness = 5;
  
  // Location defaults
  static const double defaultLatitude = 35.2626; // Kinston, NC
  static const double defaultLongitude = -77.5811;
  
  // Social media links
  static const String facebookUrl = 'https://www.facebook.com/neusenews';
  static const String twitterUrl = 'https://twitter.com/neusenews';
  static const String instagramUrl = 'https://www.instagram.com/neusenews';
  
  // Support contact
  static const String supportEmail = 'support@neusenews.com';
  static const String supportPhone = '252-555-1234';
  
  // Privacy and legal
  static const String privacyPolicyUrl = 'https://www.neusenews.com/privacy-policy';
  static const String termsOfServiceUrl = 'https://www.neusenews.com/terms-of-service';
}