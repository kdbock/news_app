import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neusenews/models/weather_data.dart';
import 'package:neusenews/models/weather_forecast.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherService {
  // Make this accessible to the weather screen
  static const apiKey = 'd7265370b126555980c6dc783ebe185e';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _geoUrl = 'https://api.openweathermap.org/geo/1.0';

  // Add default ZIP code
  final String _defaultZip = '28501'; // Kinston, NC

  // Add these properties to track client requests
  final client = http.Client();
  final Map<String, http.Client> _activeRequests = {};

  // Update cancelRequests method
  void cancelRequests() {
    _activeRequests.forEach((_, client) {
      try {
        client.close();
      } catch (e) {
        debugPrint('Error closing client: $e');
      }
    });
    _activeRequests.clear();
    debugPrint('WeatherService: All requests canceled');
  }

  // Add the getForecast method for the dashboard with fallback data
  Future<List<WeatherForecast>> getForecast() async {
    try {
      // Use the default ZIP code if none provided
      return getDailyForecast(_defaultZip);
    } catch (e) {
      debugPrint('Error fetching forecast, using fallback data: $e');
      // Return fallback forecast data
      return _getFallbackForecast();
    }
  }

  // Fallback forecast data for when the API fails
  List<WeatherForecast> _getFallbackForecast() {
    final now = DateTime.now();
    return [
      WeatherForecast(
        date: now,
        day: 'Today',
        condition: 'Clear',
        temp: 75,
        tempMin: 70,
        tempMax: 80,
        icon: '01d',
        pop: 0.0,
      ),
      // Add more fallback days if needed
    ];
  }

  Future<WeatherData> getCurrentWeather(String zipCode) async {
    final client = http.Client();
    _activeRequests['current_$zipCode'] = client;

    try {
      final response = await client.get(
        Uri.parse(
          '$_baseUrl/weather?zip=$zipCode,us&units=imperial&appid=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherData.fromJson(data);
      } else {
        debugPrint(
          'Weather API error: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in getCurrentWeather: $e');
      // Return fallback weather data
      return WeatherData(
        condition: 'Clear',
        description: 'clear sky',
        temperature: 75.0,
        feelsLike: 76.0,
        humidity: 45,
        windSpeed: 5.0,
        icon: '01d',
        pressure: 1015.0,
        visibility: 10000,
        sunrise:
            DateTime.now().millisecondsSinceEpoch ~/ 1000 -
            21600, // 6 hours ago
        sunset:
            DateTime.now().millisecondsSinceEpoch ~/ 1000 +
            43200, // 12 hours from now
      );
    } finally {
      _activeRequests.remove('current_$zipCode');
    }
  }

  Future<List<WeatherForecast>> getHourlyForecast(String zipCode) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/forecast?zip=$zipCode,us&units=imperial&appid=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> forecastList = data['list'];

        // Map each forecast to WeatherForecast object
        return forecastList.map((item) {
          final timestamp = item['dt'] * 1000;
          final date = DateTime.fromMillisecondsSinceEpoch(timestamp);

          // Extract precipitation probability if available
          double precipitation = 0.0;
          if (item.containsKey('pop')) {
            precipitation = (item['pop'] as num).toDouble();
          }

          return WeatherForecast(
            date: date,
            day: _getDayName(date),
            condition: item['weather'][0]['main'],
            temp: (item['main']['temp'] as num).toDouble(),
            tempMin: (item['main']['temp_min'] as num).toDouble(),
            tempMax: (item['main']['temp_max'] as num).toDouble(),
            icon: item['weather'][0]['icon'],
            pop: precipitation,
            uvIndex: 0.0,
          );
        }).toList();
      } else {
        debugPrint(
          'Hourly forecast API error: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to load forecast data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in getHourlyForecast: $e');
      // Return fallback hourly forecast
      return _getFallbackHourlyForecast();
    }
  }

  List<WeatherForecast> _getFallbackHourlyForecast() {
    final List<WeatherForecast> hourlyForecasts = [];
    final DateTime now = DateTime.now();

    // Generate 24 hours of fallback data
    for (int i = 0; i < 24; i++) {
      final DateTime forecastTime = now.add(Duration(hours: i));
      final int hour = forecastTime.hour;

      // Create some variation in the forecasts
      final double baseTemp =
          70 + (hour > 6 && hour < 18 ? 5 : -3) + (i % 3) * 2.0;
      final String condition =
          i % 8 == 0 ? 'Clouds' : (i % 12 == 0 ? 'Rain' : 'Clear');
      final double pop =
          condition == 'Rain' ? 0.6 : (condition == 'Clouds' ? 0.2 : 0.0);

      hourlyForecasts.add(
        WeatherForecast(
          date: forecastTime,
          day: i == 0 ? 'Now' : '${forecastTime.hour}:00',
          condition: condition,
          temp: baseTemp,
          tempMin: baseTemp - 2,
          tempMax: baseTemp + 2,
          icon:
              condition == 'Clear'
                  ? '01d'
                  : (condition == 'Clouds' ? '03d' : '10d'),
          pop: pop,
          uvIndex: hour > 8 && hour < 16 ? 5.0 : 1.0,
        ),
      );
    }

    return hourlyForecasts;
  }

  Future<List<WeatherForecast>> getDailyForecast(String zipCode) async {
    try {
      // Use the 5-day forecast endpoint which is available in free tier
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/forecast?zip=$zipCode,us&units=imperial&appid=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> forecastList = data['list'];

        // Group forecasts by day (free API gives 3-hour intervals)
        final Map<String, WeatherForecast> dailyForecasts = {};

        for (var item in forecastList) {
          final timestamp = item['dt'] * 1000;
          final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final dayKey = '${date.year}-${date.month}-${date.day}';

          // Take noon forecast as representative for the day
          final hour = date.hour;
          if (!dailyForecasts.containsKey(dayKey) ||
              (hour >= 11 && hour <= 13)) {
            dailyForecasts[dayKey] = WeatherForecast(
              date: date,
              day: _getDayName(date),
              condition: item['weather'][0]['main'],
              temp: (item['main']['temp'] as num).toDouble(),
              tempMin: (item['main']['temp_min'] as num).toDouble(),
              tempMax: (item['main']['temp_max'] as num).toDouble(),
              icon: item['weather'][0]['icon'],
              pop:
                  item.containsKey('pop')
                      ? (item['pop'] as num).toDouble()
                      : 0.0,
            );
          }
        }

        // Sort by date and return first 5 days
        final sortedForecasts =
            dailyForecasts.values.toList()
              ..sort((a, b) => a.date.compareTo(b.date));

        return sortedForecasts.take(5).toList();
      } else {
        debugPrint(
          'Daily forecast API error: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to load daily forecast: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error in getDailyForecast: $e');
      return _getFallbackForecast();
    }
  }

  Future<Map<String, dynamic>> getAirQuality(String zipCode) async {
    try {
      // First get coordinates from ZIP code
      final coordsResponse = await http.get(
        Uri.parse('$_geoUrl/zip?zip=$zipCode,us&appid=$apiKey'),
      );

      if (coordsResponse.statusCode != 200) {
        debugPrint(
          'Air quality geocoding API error: ${coordsResponse.statusCode} - ${coordsResponse.body}',
        );
        throw Exception(
          'Failed to get coordinates from ZIP code: ${coordsResponse.statusCode}',
        );
      }

      final coordsData = jsonDecode(coordsResponse.body);
      final lat = coordsData['lat'];
      final lon = coordsData['lon'];

      // Now get the air quality data
      final response = await http.get(
        Uri.parse('$_baseUrl/air_pollution?lat=$lat&lon=$lon&appid=$apiKey'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
          'Air quality API error: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to load air quality data: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error in getAirQuality: $e');
      // Return fallback air quality data
      return {
        'list': [
          {
            'main': {'aqi': 2}, // 2 = Fair
            'components': {
              'co': 250.0,
              'no': 10.0,
              'no2': 15.0,
              'o3': 80.0,
              'so2': 5.0,
              'pm2_5': 10.0,
              'pm10': 15.0,
              'nh3': 1.0,
            },
          },
        ],
      };
    }
  }

  Future<String?> getCityFromZip(String zipCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_geoUrl/zip?zip=$zipCode,us&appid=$apiKey'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return '${data['name']}, ${data['country']}';
      } else {
        debugPrint(
          'Geocoding city API error: ${response.statusCode} - ${response.body}',
        );
        return zipCode == _defaultZip ? 'Kinston, NC' : 'Unknown Location';
      }
    } catch (e) {
      debugPrint('Error in getCityFromZip: $e');
      return zipCode == _defaultZip ? 'Kinston, NC' : 'Unknown Location';
    }
  }

  Future<Map<String, dynamic>> _getCoordinatesFromZip(String zipCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_geoUrl/zip?zip=$zipCode,us&appid=$apiKey'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
          'Geocoding API error: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to get coordinates from ZIP code: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error in _getCoordinatesFromZip: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getWeatherAlerts(String zipCode) async {
    try {
      // Get coordinates from ZIP code
      final coordsData = await _getCoordinatesFromZip(zipCode);
      final lat = coordsData['lat'];
      final lon = coordsData['lon'];

      // Get alerts with OneCall API
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/onecall?lat=$lat&lon=$lon&exclude=current,minutely,hourly,daily&units=imperial&appid=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data.containsKey('alerts') ? data['alerts'] : [];
      }
      return [];
    } catch (e) {
      debugPrint('Error getting weather alerts: $e');
      return [];
    }
  }

  Future<void> cacheWeatherData(
    String zipCode,
    Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('weather_data_$zipCode', jsonEncode(data));
      await prefs.setInt(
        'weather_cache_time',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error caching weather data: $e');
    }
  }

  Future<Map<String, dynamic>?> getCachedWeatherData(String zipCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTime = prefs.getInt('weather_cache_time') ?? 0;

      // Check if cache is less than 30 minutes old
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - cacheTime < 30 * 60 * 1000) {
        final data = prefs.getString('weather_data_$zipCode');
        if (data != null) {
          return jsonDecode(data);
        }
      }
    } catch (e) {
      debugPrint('Error getting cached weather: $e');
    }
    return null;
  }

  static String _getDayName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Today';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow';
    }

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }
}
