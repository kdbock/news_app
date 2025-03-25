import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

class WeatherService {
  static const String apiKey =
      'd7265370b126555980c6dc783ebe185e'; // Add your API key here

  Future<WeatherData> getWeatherByZip(String zipCode) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?zip=$zipCode,us&units=imperial&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return WeatherData.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      // Use logger in production instead
      print('Error fetching weather: $e');
      throw Exception('Error fetching weather data: $e');
    }
  }
}
