// Create a secure config file: lib/config/api_config.dart
class ApiConfig {
  static const String weatherApiKey = String.fromEnvironment('WEATHER_API_KEY', 
    defaultValue: 'd7265370b126555980c6dc783ebe185e'); // Fallback for development
}

