import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:news_app/models/weather_data.dart';
import 'package:news_app/models/weather_forecast.dart';

class WeatherService {
  // Make this accessible to the weather screen
  static const apiKey = 'd7265370b126555980c6dc783ebe185e';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _geoUrl = 'https://api.openweathermap.org/geo/1.0';

  // Add default ZIP code
  final String _defaultZip = '28501'; // Kinston, NC

  // Add the getForecast method for the dashboard
  Future<List<WeatherForecast>> getForecast() async {
    try {
      // Use the default ZIP code if none provided
      return getDailyForecast(_defaultZip);
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  Future<WeatherData> getCurrentWeather(String zipCode) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/weather?zip=$zipCode,us&units=imperial&appid=$apiKey',
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return WeatherData.fromJson(data);
    } else {
      throw Exception('Failed to load weather data: ${response.statusCode}');
    }
  }

  Future<List<WeatherForecast>> getHourlyForecast(String zipCode) async {
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
      throw Exception('Failed to load forecast data: ${response.statusCode}');
    }
  }

  Future<List<WeatherForecast>> getDailyForecast(String zipCode) async {
    // First get coordinates from ZIP code
    final coordsResponse = await http.get(
      Uri.parse('$_geoUrl/zip?zip=$zipCode,us&appid=$apiKey'),
    );

    if (coordsResponse.statusCode != 200) {
      throw Exception(
        'Failed to get coordinates from ZIP code: ${coordsResponse.statusCode}',
      );
    }

    final coordsData = jsonDecode(coordsResponse.body);
    final lat = coordsData['lat'];
    final lon = coordsData['lon'];

    // Now get the daily forecast with OneCall API
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/onecall?lat=$lat&lon=$lon&exclude=current,minutely,hourly,alerts&units=imperial&appid=$apiKey',
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> dailyList = data['daily'];

      // Take only the first 5 days
      final limitedList = dailyList.take(5).toList();

      return limitedList.map<WeatherForecast>((item) {
        final timestamp = item['dt'] * 1000;
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);

        double uvIndex = 0.0;
        if (item.containsKey('uvi')) {
          uvIndex = (item['uvi'] as num).toDouble();
        }

        return WeatherForecast(
          date: date,
          day: _getDayName(date),
          condition: item['weather'][0]['main'],
          temp: (item['temp']['day'] as num).toDouble(),
          tempMin: (item['temp']['min'] as num).toDouble(),
          tempMax: (item['temp']['max'] as num).toDouble(),
          icon: item['weather'][0]['icon'],
          pop: item['pop'] != null ? (item['pop'] as num).toDouble() : 0.0,
          uvIndex: uvIndex,
        );
      }).toList();
    } else {
      throw Exception('Failed to load daily forecast: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getAirQuality(String zipCode) async {
    // First get coordinates from ZIP code
    final coordsResponse = await http.get(
      Uri.parse('$_geoUrl/zip?zip=$zipCode,us&appid=$apiKey'),
    );

    if (coordsResponse.statusCode != 200) {
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
      throw Exception(
        'Failed to load air quality data: ${response.statusCode}',
      );
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
      }
    } catch (e) {
      // Silently fail and return null
    }
    return null;
  }

  static String _getDayName(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else {
      switch (date.weekday) {
        case 1:
          return 'Monday';
        case 2:
          return 'Tuesday';
        case 3:
          return 'Wednesday';
        case 4:
          return 'Thursday';
        case 5:
          return 'Friday';
        case 6:
          return 'Saturday';
        case 7:
          return 'Sunday';
        default:
          return '';
      }
    }
  }
}
