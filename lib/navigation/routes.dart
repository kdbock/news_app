class Routes {
  // Core routes
  static const String splash = '/';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';

  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  
  // User routes
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String investorDashboard = '/investor-dashboard';
  
  // News routes
  static const String article = '/article';
  static const String news = '/news';
  static const String localNews = '/local-news';
  static const String politics = '/politics';
  static const String sports = '/sports';
  static const String obituaries = '/obituaries';
  static const String columns = '/columns';
  static const String publicNotices = '/public-notices';
  static const String classifieds = '/classifieds';
  static const String mattersOfRecord = '/matters-of-record';
  
  // Submit routes
  static const String submitNewsTip = '/submit-news-tip';
  static const String submitSponsoredEvent = '/submit-sponsored-event';
  static const String submitSponsoredArticle = '/submit-sponsored-article';
  
  // Weather and events
  static const String weather = '/weather';
  static const String calendar = '/calendar';
  
  // Ad routes
  static const String advertisingOptions = '/advertising-options';
  static const String createAd = '/create-ad';
  static const String adCheckout = '/ad-checkout';
  static const String adConfirmation = '/ad-confirmation';
  static const String advertiserDashboard = '/advertiser-dashboard';
  
  // Admin routes
  static const String adminDashboard = '/admin-dashboard';
  static const String reviewAds = '/review-ads';
  static const String reviewSponsoredContent = '/review-sponsored-content';
  static const String adminUsers = '/admin-users';
  static const String sponsored = '/sponsored';
  static const String advertising = '/advertising';
}