import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsManager {
  static SharedPreferences? _preferences;
  
  // Initialize shared preferences
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }
  
  // Check if shared preferences is initialized
  static bool get isInitialized => _preferences != null;
  
  // Get shared preferences instance
  static SharedPreferences get prefs {
    if (_preferences == null) {
      throw Exception('SharedPrefsManager not initialized. Call init() first.');
    }
    return _preferences!;
  }
  
  // Save weather ZIP code
  static Future<void> saveWeatherZip(String zip) async {
    await prefs.setString('weather_zip', zip);
  }
  
  // Get weather ZIP code
  static String getWeatherZip() {
    return prefs.getString('weather_zip') ?? '28501'; // Default to Kinston, NC
  }
  
  // Save user settings
  static Future<void> saveUserSettings({
    bool? pushNotificationsEnabled,
    bool? breakingNewsAlerts,
    bool? dailyDigestNotifications,
    bool? sportScoreNotifications,
    bool? weatherAlerts,
    bool? localNewsAlerts,
    bool? showLocalNews,
    bool? showPolitics,
    bool? showSports,
    bool? showClassifieds,
    bool? showObituaries,
    bool? showWeather,
    String? locationPreference,
    String? textSize,
    bool? darkModeEnabled,
    bool? reducedMotion,
    bool? highContrastMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Only save values that are not null
    if (pushNotificationsEnabled != null) {
      await prefs.setBool('pushNotificationsEnabled', pushNotificationsEnabled);
    }
    
    if (breakingNewsAlerts != null) {
      await prefs.setBool('breakingNewsAlerts', breakingNewsAlerts);
    }
    
    if (dailyDigestNotifications != null) {
      await prefs.setBool('dailyDigestNotifications', dailyDigestNotifications);
    }
    
    if (sportScoreNotifications != null) {
      await prefs.setBool('sportScoreNotifications', sportScoreNotifications);
    }
    
    if (weatherAlerts != null) {
      await prefs.setBool('weatherAlerts', weatherAlerts);
    }
    
    if (localNewsAlerts != null) {
      await prefs.setBool('localNewsAlerts', localNewsAlerts);
    }
    
    if (showLocalNews != null) {
      await prefs.setBool('showLocalNews', showLocalNews);
    }
    
    if (showPolitics != null) {
      await prefs.setBool('showPolitics', showPolitics);
    }
    
    if (showSports != null) {
      await prefs.setBool('showSports', showSports);
    }
    
    if (showClassifieds != null) {
      await prefs.setBool('showClassifieds', showClassifieds);
    }
    
    if (showObituaries != null) {
      await prefs.setBool('showObituaries', showObituaries);
    }
    
    if (showWeather != null) {
      await prefs.setBool('showWeather', showWeather);
    }
    
    if (locationPreference != null) {
      await prefs.setString('locationPreference', locationPreference);
    }
    
    if (textSize != null) {
      await prefs.setString('textSize', textSize);
    }
    
    if (darkModeEnabled != null) {
      await prefs.setBool('darkModeEnabled', darkModeEnabled);
    }
    
    if (reducedMotion != null) {
      await prefs.setBool('reducedMotion', reducedMotion);
    }
    
    if (highContrastMode != null) {
      await prefs.setBool('highContrastMode', highContrastMode);
    }
    
    // Update last sync time
    await prefs.setInt('lastDataSync', DateTime.now().millisecondsSinceEpoch);
  }
}