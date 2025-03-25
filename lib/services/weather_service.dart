import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_data.dart';
import '../models/weather_forecast.dart';

class WeatherService {
  static const String apiKey = 'd7265370b126555980c6dc783ebe185e';
  
  // Default ZIP code (Kinston, NC)
  static const String defaultZip = '28501';
  
  // Cache duration in minutes
  static const int cacheDuration = 30;

  // Get current weather data
  Future<WeatherData> getCurrentWeather() async {
    final zipCode = await _getZipCode();
    final url = 'https://api.openweathermap.org/data/2.5/weather?zip=$zipCode,us&units=imperial&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return WeatherData.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching current weather: $e');
      throw Exception('Error fetching weather data');
    }
  }

  // Get 5-day forecast
  Future<List<WeatherForecast>> getForecast() async {
    final zipCode = await _getZipCode();
    final url = 'https://api.openweathermap.org/data/2.5/forecast?zip=$zipCode,us&units=imperial&appid=$apiKey';

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'weather_forecast_$zipCode';
      final cachedData = prefs.getString(cacheKey);
      
      // Check if we have cached data and it's still valid
      if (cachedData != null) {
        final cachedTime = prefs.getInt('${cacheKey}_time') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsed = (now - cachedTime) / (1000 * 60); // minutes
        
        if (elapsed < cacheDuration) {
          print('Using cached forecast data');
          final cachedForecast = json.decode(cachedData);
          return _processForecast(cachedForecast);
        }
      }
      
      // Fetch new data
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Cache the response
        prefs.setString(cacheKey, response.body);
        prefs.setInt('${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);
        
        return _processForecast(data);
      } else {
        throw Exception('Failed to load forecast data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching forecast: $e');
      throw Exception('Error fetching forecast data');
    }
  }

  // Process forecast data to get one forecast per day
  List<WeatherForecast> _processForecast(Map<String, dynamic> data) {
    final List<dynamic> list = data['list'];
    
    // Get one forecast for each day at noon
    final Map<String, WeatherForecast> dailyForecasts = {};
    
    for (var item in list) {
      final forecast = WeatherForecast.fromJson(item);
      final date = forecast.date;
      final dateString = '${date.year}-${date.month}-${date.day}';
      
      // If we don't have this day yet, or if this forecast is closer to noon
      if (!dailyForecasts.containsKey(dateString)) {
        dailyForecasts[dateString] = forecast;
      } else {
        // Try to get forecasts for around noon (12-2pm)
        final existingHour = dailyForecasts[dateString]!.date.hour;
        final newHour = date.hour;
        
        if ((newHour == 12 || newHour == 13 || newHour == 14) && 
            (existingHour < 12 || existingHour > 14)) {
          dailyForecasts[dateString] = forecast;
        }
      }
    }
    
    // Convert to list and sort by date
    final forecasts = dailyForecasts.values.toList();
    forecasts.sort((a, b) => a.date.compareTo(b.date));
    
    // Return at most 5 days
    return forecasts.take(5).toList();
  }

  // Get the user's ZIP code from preferences or use default
  Future<String> _getZipCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_zip_code') ?? defaultZip;
    } catch (e) {
      return defaultZip;
    }
  }

  // Allow updating the ZIP code
  Future<void> setZipCode(String zipCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_zip_code', zipCode);
  }
}
