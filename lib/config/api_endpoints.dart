class ApiEndpoints {
  // Base URLs
  static const String weatherBaseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String weatherGeoUrl = 'https://api.openweathermap.org/geo/1.0';

  // Weather API endpoints
  static String currentWeather(String zipCode, String apiKey) {
    return '$weatherBaseUrl/weather?zip=$zipCode,us&units=imperial&appid=$apiKey';
  }

  static String hourlyForecast(String zipCode, String apiKey) {
    return '$weatherBaseUrl/forecast?zip=$zipCode,us&units=imperial&appid=$apiKey';
  }

  static String dailyForecast(double lat, double lon, String apiKey) {
    return '$weatherBaseUrl/onecall?lat=$lat&lon=$lon&exclude=minutely,alerts&units=imperial&appid=$apiKey';
  }

  static String airQuality(double lat, double lon, String apiKey) {
    return '$weatherBaseUrl/air_pollution?lat=$lat&lon=$lon&appid=$apiKey';
  }

  static String geocoding(String zipCode, String apiKey) {
    return '$weatherGeoUrl/zip?zip=$zipCode,us&appid=$apiKey';
  }

  // Main feed URLs
  static const String localNewsUrl = 'https://www.neusenews.com/index/category/Local+News?format=rss';
  static const String stateNewsUrl = 'https://www.neusenews.com/index/category/NC+News?format=rss';
  static const String columnsUrl = 'https://www.neusenews.com/index/category/Columns?format=rss';
  static const String mattersOfRecordUrl = 'https://www.neusenews.com/index/category/Matters+of+Record?format=rss';
  static const String obituariesUrl = 'https://www.neusenews.com/index/category/Obituaries?format=rss';
  static const String publicNoticesUrl = 'https://www.neusenews.com/index/category/Public+Notices?format=rss';
  static const String classifiedsUrl = 'https://www.neusenews.com/index/category/Classifieds?format=rss';
  static const String sportsUrl = 'https://www.neusenewssports.com/news-1?format=rss';
  static const String politicsUrl = 'https://www.ncpoliticalnews.com/news?format=rss';

  // External URLs
  static const String orderClassifiedsUrl = 'https://www.neusenews.com/order-classifieds';
}