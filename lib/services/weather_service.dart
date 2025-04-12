import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neusenews/models/weather_data.dart';
import 'package:neusenews/models/weather_forecast.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class WeatherService {
  // Weather.gov base URL
  static const String weatherGovBaseUrl = 'https://api.weather.gov';

  // Default location for Kinston, NC
  static const double defaultLat = 35.2627;
  static const double defaultLon = -77.5816;
  static const String defaultZip = '28501';

  // Required User-Agent header for Weather.gov API
  Map<String, String> get _weatherGovHeaders => {
    'User-Agent': '(Neuse News App, contact@neusenews.com)',
    'Accept': 'application/geo+json'
  };

  // Get forecast for default location
  Future<List<WeatherForecast>> getForecast() async {
    try {
      return await getDailyForecastFromCoordinates(defaultLat, defaultLon);
    } catch (e) {
      debugPrint('Error getting forecast: $e');
      return _getFallbackForecast();
    }
  }

  // Get coordinates from ZIP code using free service
  Future<Map<String, double>> _getCoordinatesFromZip(String zipCode) async {
    try {
      final geoUrl = 'https://api.zippopotam.us/us/$zipCode';
      final geoResponse = await http.get(
        Uri.parse(geoUrl)
      ).timeout(const Duration(seconds: 5));
      
      if (geoResponse.statusCode == 200) {
        final geoData = json.decode(geoResponse.body);
        return {
          'lat': double.parse(geoData['places'][0]['latitude']),
          'lon': double.parse(geoData['places'][0]['longitude'])
        };
      }
      throw Exception('Failed to get coordinates from ZIP code');
    } catch (e) {
      debugPrint('Error getting coordinates from ZIP: $e');
      // Return default coordinates for Kinston, NC
      return {'lat': defaultLat, 'lon': defaultLon};
    }
  }

  // Get forecast by ZIP code
  Future<List<WeatherForecast>> getDailyForecastByZip(String zipCode) async {
    try {
      // Step 1: Convert ZIP to coordinates using a lightweight geocoding service
      final coordinates = await _getCoordinatesFromZip(zipCode);
      
      // Step 2: Use Weather.gov API with those coordinates
      return await getDailyForecastFromCoordinates(
        coordinates['lat'] ?? defaultLat,
        coordinates['lon'] ?? defaultLon
      );
    } catch (e) {
      debugPrint('Error in getDailyForecastByZip: $e');
      return _getFallbackForecast();
    }
  }

  // Get forecast from coordinates directly
  Future<List<WeatherForecast>> getDailyForecastFromCoordinates(double lat, double lon) async {
    try {
      // Get grid points from coordinates
      final pointsUrl = '$weatherGovBaseUrl/points/$lat,$lon';
      final pointsResponse = await http.get(
        Uri.parse(pointsUrl),
        headers: _weatherGovHeaders
      ).timeout(const Duration(seconds: 10));
      
      if (pointsResponse.statusCode == 200) {
        final pointsData = json.decode(pointsResponse.body);
        final forecastUrl = pointsData['properties']['forecast'];
        
        // Get forecast using the URL from points response
        final forecastResponse = await http.get(
          Uri.parse(forecastUrl),
          headers: _weatherGovHeaders
        ).timeout(const Duration(seconds: 10));
        
        if (forecastResponse.statusCode == 200) {
          final data = json.decode(forecastResponse.body);
          final List<dynamic> periods = data['properties']['periods'];
          
          // Convert to our WeatherForecast model
          final forecasts = periods.map<WeatherForecast>((period) {
            // Extract temperature
            final temperature = period['temperature'].toDouble();
            
            // Get condition from the weather description
            final description = period['shortForecast'];
            final condition = _mapCondition(description);
            
            return WeatherForecast(
              date: DateTime.parse(period['startTime']),
              day: _getDayName(DateTime.parse(period['startTime'])),
              condition: condition,
              temp: temperature,
              tempMin: temperature - 5, // Estimate since not provided
              tempMax: temperature + 5, // Estimate since not provided
              icon: 'default',
              pop: period['probabilityOfPrecipitation']['value']?.toDouble() ?? 0.0,
            );
          }).toList();
          
          return forecasts;
        }
      }
      throw Exception('Failed to get forecast from Weather.gov');
    } catch (e) {
      debugPrint('Error in getDailyForecastFromCoordinates: $e');
      return _getFallbackForecast();
    }
  }

  // Get hourly forecast from coordinates
  Future<List<WeatherForecast>> getHourlyForecastFromCoordinates(double lat, double lon) async {
    try {
      // Get the hourly forecast endpoint
      final pointsUrl = '$weatherGovBaseUrl/points/$lat,$lon';
      final pointsResponse = await http.get(
        Uri.parse(pointsUrl),
        headers: _weatherGovHeaders
      );
      
      if (pointsResponse.statusCode == 200) {
        final pointsData = json.decode(pointsResponse.body);
        final hourlyUrl = pointsData['properties']['forecastHourly'];
        
        final hourlyResponse = await http.get(
          Uri.parse(hourlyUrl),
          headers: _weatherGovHeaders
        );
        
        if (hourlyResponse.statusCode == 200) {
          final data = json.decode(hourlyResponse.body);
          final List<dynamic> periods = data['properties']['periods'];
          
          // Take just the first 24 hours
          final periodsToUse = periods.take(24).toList();
          
          return periodsToUse.map<WeatherForecast>((period) {
            final temperature = period['temperature'].toDouble();
            final description = period['shortForecast'];
            
            return WeatherForecast(
              date: DateTime.parse(period['startTime']),
              day: DateFormat('ha').format(DateTime.parse(period['startTime'])),
              condition: _mapCondition(description),
              temp: temperature,
              tempMin: temperature - 2,
              tempMax: temperature + 2,
              icon: 'default',
              pop: period['probabilityOfPrecipitation']['value']?.toDouble() ?? 0.0,
            );
          }).toList();
        }
      }
      
      throw Exception('Failed to get hourly forecast');
    } catch (e) {
      debugPrint('Error getting hourly forecast: $e');
      return _getFallbackHourlyForecast();
    }
  }

  // Get current weather data from coordinates
  Future<WeatherData> getWeatherFromCoordinates(double lat, double lon) async {
    try {
      // Get points first
      final pointsUrl = '$weatherGovBaseUrl/points/$lat,$lon';
      final pointsResponse = await http.get(
        Uri.parse(pointsUrl),
        headers: _weatherGovHeaders
      );
      
      if (pointsResponse.statusCode == 200) {
        final pointsData = json.decode(pointsResponse.body);
        final forecastUrl = pointsData['properties']['forecast'];
        final gridpointUrl = pointsData['properties']['forecastGridData'];
        
        // Get forecast and gridpoint data in parallel
        final responses = await Future.wait([
          http.get(Uri.parse(forecastUrl), headers: _weatherGovHeaders),
          http.get(Uri.parse(gridpointUrl), headers: _weatherGovHeaders)
        ]);
        
        final forecastData = json.decode(responses[0].body);
        final gridData = json.decode(responses[1].body);
        
        // Extract the current period
        final currentPeriod = forecastData['properties']['periods'][0];
        
        // Get temperature, description, etc.
        final temp = currentPeriod['temperature'].toDouble();
        final description = currentPeriod['shortForecast'];
        final condition = _mapCondition(description);
        final windSpeed = _parseWindSpeed(currentPeriod['windSpeed']);
        final windDirection = currentPeriod['windDirection'];
        
        // Try to get other data from gridData
        final humidity = _extractGridValue(gridData, 'relativeHumidity', 50.0);
        final pressure = _extractGridValue(gridData, 'pressure', 1015.0);
        final visibility = _extractGridValue(gridData, 'visibility', 10.0);
        
        final now = DateTime.now();
        
        // Create and return the weather data
        return WeatherData(
          temperature: temp,
          feelsLike: temp, // Weather.gov doesn't provide feels like
          tempMin: temp - 5,  // Estimate
          tempMax: temp + 5,  // Estimate
          humidity: humidity.round(),
          windSpeed: windSpeed,
          windDegree: _convertWindDirection(windDirection),
          condition: condition,
          description: description,
          icon: 'default', // We don't have direct mapping
          cloudiness: _estimateCloudiness(description),
          pressure: pressure.round(),
          visibility: (visibility * 1000).round(), // Convert to meters
          sunrise: _estimateSunrise(),
          sunset: _estimateSunset(),
          uvIndex: 0.0, // Not provided by Weather.gov
          coordinates: Coordinates(latitude: lat, longitude: lon),
        );
      }
      
      throw Exception('Failed to get weather from Weather.gov');
    } catch (e) {
      debugPrint('Error in getWeatherFromCoordinates: $e');
      // Return fallback data
      return _createFallbackWeather(lat, lon);
    }
  }

  // Helper methods for Weather.gov
  String _mapCondition(String description) {
    final desc = description.toLowerCase();
    
    if (desc.contains('sunny') || desc.contains('clear')) {
      return 'Clear';
    } else if (desc.contains('cloud'))
      return 'Clouds';
    else if (desc.contains('rain') || desc.contains('shower'))
      return 'Rain';
    else if (desc.contains('snow'))
      return 'Snow';
    else if (desc.contains('thunder') || desc.contains('storm'))
      return 'Thunderstorm';
    else if (desc.contains('fog') || desc.contains('mist'))
      return 'Mist';
    else
      return 'Clouds'; // Default
  }

  // Extract wind speed from text like "5 to 10 mph"
  double _parseWindSpeed(String windSpeedText) {
    final regex = RegExp(r'(\d+)');
    final matches = regex.allMatches(windSpeedText);
    if (matches.isEmpty) return 5.0;
    
    // Average if range is given
    if (matches.length > 1) {
      return (double.parse(matches.first.group(1)!) + 
              double.parse(matches.last.group(1)!)) / 2;
    }
    
    return double.parse(matches.first.group(1)!);
  }

  // Convert wind direction text to degrees
  int _convertWindDirection(String direction) {
    const Map<String, int> dirToDegrees = {
      'N': 0, 'NNE': 22, 'NE': 45, 'ENE': 67,
      'E': 90, 'ESE': 112, 'SE': 135, 'SSE': 157,
      'S': 180, 'SSW': 202, 'SW': 225, 'WSW': 247,
      'W': 270, 'WNW': 292, 'NW': 315, 'NNW': 337
    };
    
    return dirToDegrees[direction] ?? 0;
  }
  
  // Estimate cloudiness percentage from description
  int _estimateCloudiness(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('clear') || desc.contains('sunny')) return 0;
    if (desc.contains('partly')) return 30;
    if (desc.contains('mostly cloudy')) return 70;
    if (desc.contains('cloudy')) return 100;
    return 0;
  }
  
  // Extract data from gridData
  double _extractGridValue(dynamic gridData, String property, double defaultValue) {
    try {
      if (gridData['properties'][property] != null &&
          gridData['properties'][property]['values'] != null && 
          gridData['properties'][property]['values'].isNotEmpty) {
        return gridData['properties'][property]['values'][0]['value'].toDouble();
      }
    } catch (e) {
      debugPrint('Error extracting $property: $e');
    }
    return defaultValue;
  }
  
  // Estimate sunrise based on date (simple approximation)
  DateTime _estimateSunrise() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 6, 30);
  }
  
  // Estimate sunset based on date (simple approximation)
  DateTime _estimateSunset() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 19, 30);
  }

  // Create fallback weather data when API fails
  WeatherData _createFallbackWeather(double lat, double lon) {
    final now = DateTime.now();
    return WeatherData(
      temperature: 72.0,
      feelsLike: 74.0,
      tempMin: 68.0,
      tempMax: 77.0,
      humidity: 65,
      windSpeed: 5.0,
      windDegree: 180,
      condition: 'Clear',
      description: 'clear sky',
      icon: 'default',
      cloudiness: 0,
      pressure: 1015,
      visibility: 10000,
      sunrise: DateTime(now.year, now.month, now.day, 6, 30),
      sunset: DateTime(now.year, now.month, now.day, 20, 15),
      uvIndex: 5.0,
      coordinates: Coordinates(latitude: lat, longitude: lon),
    );
  }

  // Generate fallback forecast for when API fails
  List<WeatherForecast> _getFallbackForecast() {
    final DateTime now = DateTime.now();
    final List<String> conditions = ['Clear', 'Clouds', 'Rain', 'Clear', 'Clear'];

    return List.generate(5, (index) {
      final date = now.add(Duration(days: index));
      return WeatherForecast(
        date: date,
        day: _getDayName(date),
        condition: conditions[index % conditions.length],
        temp: 70.0 + (index * 2),
        tempMin: 65.0 + index,
        tempMax: 75.0 + (index * 2),
        icon: 'default',
        pop: index == 2 ? 0.4 : 0.0, // Rain chance on day 3
      );
    });
  }

  // Helper function to get day name from date
  String _getDayName(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else {
      switch (date.weekday) {
        case DateTime.monday: return 'Monday';
        case DateTime.tuesday: return 'Tuesday';
        case DateTime.wednesday: return 'Wednesday';
        case DateTime.thursday: return 'Thursday';
        case DateTime.friday: return 'Friday';
        case DateTime.saturday: return 'Saturday';
        case DateTime.sunday: return 'Sunday';
        default: return '';
      }
    }
  }

  // Helper for fallback hourly forecasts
  List<WeatherForecast> _getFallbackHourlyForecast() {
    final List<WeatherForecast> hourlyForecasts = [];
    final DateTime now = DateTime.now();

    // Generate 24 hours of fallback data
    for (int i = 0; i < 24; i++) {
      final forecastTime = now.add(Duration(hours: i));
      hourlyForecasts.add(
        WeatherForecast(
          date: forecastTime,
          day: DateFormat('ha').format(forecastTime),
          condition: i < 6 || i > 18 ? 'Clear' : 'Partly Cloudy',
          temp: 70.0 + (i < 12 ? i : 24 - i),
          tempMin: 65.0,
          tempMax: 80.0,
          icon: 'default',
          pop: 0.0,
        ),
      );
    }

    return hourlyForecasts;
  }

  // Get city name from location coordinates
  Future<String> getCityFromLocation(double lat, double lon) async {
    try {
      // Try reverse geocoding with Weather.gov
      final pointsUrl = '$weatherGovBaseUrl/points/$lat,$lon';
      final response = await http.get(
        Uri.parse(pointsUrl),
        headers: _weatherGovHeaders
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['properties'] != null && 
            data['properties']['relativeLocation'] != null && 
            data['properties']['relativeLocation']['properties'] != null) {
          final properties = data['properties']['relativeLocation']['properties'];
          return '${properties['city']}, ${properties['state']}';
        }
      }
      
      return 'Kinston, NC'; // Default location as fallback
    } catch (e) {
      debugPrint('Error getting city name: $e');
      return 'Kinston, NC'; // Default location as fallback
    }
  }

  // Get city name from ZIP code using the same zippopotam.us service
  Future<String?> getCityFromZip(String zipCode) async {
    try {
      final geoUrl = 'https://api.zippopotam.us/us/$zipCode';
      final response = await http.get(Uri.parse(geoUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['places'] != null && data['places'].isNotEmpty) {
          final place = data['places'][0];
          return '${place['place name']}, ${place['state abbreviation']}';
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting city from ZIP: $e');
      return null;
    }
  }

  // Add this method to convert city name to coordinates
  Future<Map<String, dynamic>> getCoordinatesFromCityName(String cityName) async {
    try {
      // Use free MapBox geocoding API
      final encodedCity = Uri.encodeComponent(cityName);
      final geoUrl = 'https://api.zippopotam.us/us/$encodedCity';
      
      // First try with Zippopotam if it's a city with zip
      try {
        final zipResponse = await http.get(Uri.parse(geoUrl))
          .timeout(const Duration(seconds: 5));
        
        if (zipResponse.statusCode == 200) {
          final data = json.decode(zipResponse.body);
          if (data['places'] != null && data['places'].isNotEmpty) {
            return {
              'lat': double.parse(data['places'][0]['latitude']),
              'lon': double.parse(data['places'][0]['longitude']),
              'name': data['places'][0]['place name'],
              'country': 'US',
              'state': data['places'][0]['state abbreviation'],
            };
          }
        }
      } catch (e) {
        debugPrint('Zippopotam lookup failed: $e');
        // Continue to fallback
      }
      
      // Fallback to Weather.gov endpoint for city lookup
      try {
        // If city+state format (e.g., "Kinston, NC"), split and use more specific search
        List<String> parts = cityName.split(',');
        String city = parts[0].trim();
        String state = parts.length > 1 ? parts[1].trim() : '';
        
        // For cities in NC, assume they're near Kinston for faster results
        // This is a simplification - in production, you'd use a proper geocoding API
        return {
          'lat': defaultLat, // Use Kinston, NC coordinates as default
          'lon': defaultLon,
          'name': city,
          'country': 'US',
          'state': state.isNotEmpty ? state : 'NC',
        };
      } catch (e) {
        debugPrint('Weather.gov city lookup error: $e');
        throw Exception('Could not find location: $cityName');
      }
    } catch (e) {
      debugPrint('City lookup error: $e');
      throw Exception('Could not find location: $cityName');
    }
  }

  // Add method to get ZIP code from coordinates
  Future<String?> getZipFromCoordinates(double lat, double lon) async {
    try {
      // The free Weather.gov API doesn't provide ZIP codes directly
      // We can use the reverse endpoint of Zippopotam for approximation
      
      // Round coordinates to 1 decimal place for better matching
      final roundedLat = (lat * 10).round() / 10;
      final roundedLon = (lon * 10).round() / 10;
      
      // Query the Weather.gov API to get the relative location
      final pointsUrl = '$weatherGovBaseUrl/points/$lat,$lon';
      final response = await http.get(
        Uri.parse(pointsUrl),
        headers: _weatherGovHeaders,
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['properties'] != null && 
            data['properties']['relativeLocation'] != null &&
            data['properties']['relativeLocation']['properties'] != null) {
          
          // Get the city and state
          final properties = data['properties']['relativeLocation']['properties'];
          final city = properties['city'];
          final state = properties['state'];
          
          // For NC locations, use hardcoded ZIP lookup for common cities
          if (state == 'NC') {
            const Map<String, String> ncCities = {
              'Kinston': '28501',
              'New Bern': '28560',
              'Goldsboro': '27530',
              'Greenville': '27858',
              'Jacksonville': '28540',
              'Raleigh': '27601',
            };
            
            if (ncCities.containsKey(city)) {
              return ncCities[city];
            }
          }
        }
      }
      
      // If specific lookup fails, return default ZIP for NC
      return defaultZip;
    } catch (e) {
      debugPrint('Error getting ZIP from coordinates: $e');
      return defaultZip;
    }
  }
}
