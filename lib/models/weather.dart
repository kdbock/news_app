import 'package:neusenews/models/weather_data.dart';
import 'package:neusenews/models/weather_forecast.dart';

class Weather {
  final WeatherData current;
  final List<WeatherForecast> hourlyForecast;
  final List<WeatherForecast> dailyForecast;
  final Map<String, dynamic>? airQuality;
  final String locationName;

  Weather({
    required this.current,
    required this.hourlyForecast,
    required this.dailyForecast,
    this.airQuality,
    required this.locationName,
  });

  // Helper method to get current UV index level
  String getUVIndexLevel() {
    final double uvi = current.uvIndex;
    
    if (uvi >= 0 && uvi < 3) {
      return 'Low';
    } else if (uvi >= 3 && uvi < 6) {
      return 'Moderate';
    } else if (uvi >= 6 && uvi < 8) {
      return 'High';
    } else if (uvi >= 8 && uvi < 11) {
      return 'Very High';
    } else {
      return 'Extreme';
    }
  }

  // Helper method to get current air quality level
  String getAirQualityLevel() {
    if (airQuality == null) {
      return 'Unknown';
    }
    
    final int aqi = airQuality!['main']['aqi'];
    switch (aqi) {
      case 1: return 'Good';
      case 2: return 'Fair';
      case 3: return 'Moderate';
      case 4: return 'Poor';
      case 5: return 'Very Poor';
      default: return 'Unknown';
    }
  }
}