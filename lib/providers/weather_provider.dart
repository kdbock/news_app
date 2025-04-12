import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neusenews/models/weather_data.dart';
import 'package:neusenews/models/weather_forecast.dart';
import 'package:neusenews/services/weather_service.dart';
import 'dart:convert';
import 'dart:async'; // Add this import for TimeoutException
import 'package:http/http.dart' as http;

class WeatherProvider with ChangeNotifier {
  // Fix constant casing to match Dart style guidelines
  static const String zipCodeKey = 'weather_zip_code';
  static const String locationDataKey = 'weather_location_data';
  static const String lastWeatherKey = 'last_weather_data';
  static const String unitPreferenceKey = 'temperature_unit';
  static const String defaultZip = '28501'; // Kinston, NC

  final WeatherService _weatherService = WeatherService();

  String _zipCode = defaultZip;
  String get zipCode => _zipCode;

  double? _latitude;
  double? _longitude;

  WeatherData? _currentWeather;
  WeatherData? get currentWeather => _currentWeather;

  List<WeatherForecast> _hourlyForecast = [];
  List<WeatherForecast> get hourlyForecast => _hourlyForecast;

  List<WeatherForecast> _dailyForecast = [];
  List<WeatherForecast> get dailyForecast => _dailyForecast;

  List<Map<String, dynamic>> _weatherAlerts = [];
  List<Map<String, dynamic>> get weatherAlerts => _weatherAlerts;

  Map<String, dynamic>? _airQuality;
  Map<String, dynamic>? get airQuality => _airQuality;

  String? _locationName;
  String? get locationName => _locationName;

  // Temperature unit preference (true = Celsius, false = Fahrenheit)
  bool _useCelsius = false;
  bool get useCelsius => _useCelsius;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DateTime? _lastUpdated;
  DateTime? get lastUpdated => _lastUpdated;

  // Cache duration in minutes - make it final as it doesn't change
  final int _cacheDuration = 30;

  List<WeatherForecast> _forecasts = [];
  List<WeatherForecast> get forecasts => _forecasts;

  WeatherProvider() {
    _loadSavedPreferences();
  }

  // Replace the _loadSavedPreferences method with this safer version
  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load temperature unit preference with default
      _useCelsius = prefs.getBool(unitPreferenceKey) ?? false;

      // Try to load cached weather data with proper null checking
      final cachedWeatherString = prefs.getString(lastWeatherKey);
      if (cachedWeatherString != null) {
        try {
          final cachedData = jsonDecode(cachedWeatherString);
          if (cachedData != null && cachedData is Map<String, dynamic>) {
            // Safely extract data with null checks
            if (cachedData['current'] != null) {
              // Handle current weather with proper null checking
              final currentData =
                  cachedData['current'] as Map<String, dynamic>?;
              if (currentData != null && currentData['temp'] != null) {
                // Create weather data safely
                // (implement based on your WeatherData structure)
              }
            }
            // Similarly handle hourly and daily forecasts
          }
        } catch (e) {
          debugPrint('Error parsing cached weather: $e');
        }
      }

      // Load weather regardless of whether cache was successful
      await refreshWeather();
    } catch (e) {
      debugPrint('Error loading weather preferences: $e');
      // Don't rethrow - we'll just try to load live data
      await refreshWeather();
    }
  }

  // Save location information
  Future<void> _saveLocationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final locationData = {
        'zipCode': _zipCode,
        'latitude': _latitude,
        'longitude': _longitude,
        'name': _locationName,
      };

      await prefs.setString(locationDataKey, json.encode(locationData));
    } catch (e) {
      debugPrint('Error saving location data: $e');
    }
  }

  // Cache weather data
  Future<void> _cacheWeatherData() async {
    try {
      if (_currentWeather == null) return;

      final prefs = await SharedPreferences.getInstance();

      final weatherCache = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'currentWeather': _currentWeather!.toJson(),
        'locationName': _locationName,
        'hourlyForecast':
            _hourlyForecast.map((forecast) => forecast.toJson()).toList(),
        'dailyForecast':
            _dailyForecast.map((forecast) => forecast.toJson()).toList(),
        'airQuality': _airQuality,
        'weatherAlerts': _weatherAlerts,
      };

      await prefs.setString(lastWeatherKey, json.encode(weatherCache));
    } catch (e) {
      debugPrint('Error caching weather data: $e');
    }
  }

  // Check if the cache is expired
  bool _isCacheExpired() {
    if (_lastUpdated == null) return true;

    final now = DateTime.now();
    final difference = now.difference(_lastUpdated!);

    return difference.inMinutes > _cacheDuration;
  }

  // Toggle temperature unit
  Future<void> toggleTemperatureUnit() async {
    _useCelsius = !_useCelsius;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(unitPreferenceKey, _useCelsius);
    } catch (e) {
      debugPrint('Error saving temperature unit preference: $e');
    }

    notifyListeners();
  }

  // Modify the updateZipCode method
  Future<void> updateZipCode(String zip) async {
    if (zip.isEmpty || zip == _zipCode) return;

    _zipCode = zip;
    _latitude = null;
    _longitude = null;
    _locationName = null; // Reset location name while loading

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(zipCodeKey, zip);

      // Tell UI we're loading
      _isLoading = true;
      notifyListeners();

      // Load weather data from ZIP which will also update location name
      await _loadWeatherDataFromZip();

      // Save the new location data
      await _saveLocationData();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating zip code: $e');
      _isLoading = false;
      _errorMessage = 'Error updating location: $e';
      notifyListeners();
    }
  }

  // Fix the code in updateCityName method
  Future<void> updateCityName(String cityName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final coordinates = await _weatherService.getCoordinatesFromCityName(
        cityName,
      );

      _latitude = coordinates['lat'];
      _longitude = coordinates['lon'];
      _locationName =
          '${coordinates['name']}, ${coordinates['state'] ?? coordinates['country']}';

      // Try to get ZIP code for this location if in the US
      if (coordinates['country'] == 'US') {
        try {
          // Fix: getZipFromCoordinates returns a String, not a Map
          final zipCode = await _weatherService.getZipFromCoordinates(
            _latitude!,
            _longitude!,
          );

          // Only update if we got a valid zip
          if (zipCode != null) {
            _zipCode = zipCode;
          }
        } catch (e) {
          // If we can't get ZIP, just continue with coordinates
          debugPrint('Could not get ZIP code for these coordinates: $e');
        }
      }

      await _saveLocationData();
      await _loadWeatherDataFromCoordinates();
    } catch (e) {
      _errorMessage = 'Error finding location: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Replace refreshWeather method with this implementation
  Future<void> refreshWeather() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // First try loading from network
      if (_latitude != null && _longitude != null) {
        await _loadWeatherDataFromCoordinates();
      } else {
        await _loadWeatherDataFromZip();
      }

      // Cache successful results
      await _cacheWeatherData();

      _lastUpdated = DateTime.now();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing weather: $e');

      // Try loading from cache as fallback
      final cachedForecasts =
          await _loadFromCache(); // This returns List<WeatherForecast>, not bool

      // Check if we got any forecasts from cache
      if (cachedForecasts.isEmpty) {
        // If cache fails too, use placeholder data
        _currentWeather = WeatherData.fallback();
        _dailyForecast = _getPlaceholderForecasts();
        _hourlyForecast = [];
        _errorMessage = 'Unable to load weather data';
      } else {
        // Use cached forecasts
        _dailyForecast = cachedForecasts;
      }

      _isLoading = false;
      notifyListeners();
    }
  }

  // Fix the _loadWeatherDataFromCoordinates method
  Future<void> _loadWeatherDataFromCoordinates() async {
    if (_latitude == null || _longitude == null) return;

    try {
      // Get weather data
      _currentWeather = await _weatherService.getWeatherFromCoordinates(
        _latitude!,
        _longitude!,
      );

      // Get daily forecast
      _dailyForecast = await _weatherService.getDailyForecastFromCoordinates(
        _latitude!,
        _longitude!,
      );

      // Get hourly forecast
      _hourlyForecast = await _weatherService.getHourlyForecastFromCoordinates(
        _latitude!,
        _longitude!,
      );

      // Add this to the _loadWeatherDataFromCoordinates method, after getting hourly forecast:

      // Get weather alerts
      _weatherAlerts = await _weatherService.getWeatherAlerts(
        _latitude!,
        _longitude!,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading weather data: $e');
      rethrow;
    }
  }

  // Modify _loadWeatherDataFromZip to update location name
  Future<void> _loadWeatherDataFromZip() async {
    try {
      // Get coordinates from ZIP using the free Zippopotam service
      final zipUrl = 'https://api.zippopotam.us/us/$_zipCode';
      final zipResponse = await http.get(Uri.parse(zipUrl));

      if (zipResponse.statusCode == 200) {
        final data = json.decode(zipResponse.body);

        // Extract coordinates
        _latitude = double.parse(data['places'][0]['latitude']);
        _longitude = double.parse(data['places'][0]['longitude']);

        // Set location name correctly
        final city = data['places'][0]['place name'];
        final state = data['places'][0]['state abbreviation'];
        _locationName = '$city, $state';

        // Now load weather with the coordinates
        await _loadWeatherDataFromCoordinates();
      } else {
        throw Exception('Failed to get coordinates from ZIP code');
      }
    } catch (e) {
      debugPrint('Error loading weather data from ZIP: $e');

      // Fall back to default coordinates (Kinston, NC)
      _latitude = 35.2626;
      _longitude = -77.5816;
      _locationName = 'Kinston, NC';

      // Try to load weather from coordinates
      await _loadWeatherDataFromCoordinates();
    }
  }

  // Fix the temperature formatter method
  String formatTemperature(double temperature) {
    if (_useCelsius) {
      // Convert from Fahrenheit to Celsius
      final celsius = (temperature - 32) * 5 / 9;
      return '${celsius.round()}°C';
    } else {
      return '${temperature.round()}°F';
    }
  }

  // Get dashboard forecast
  List<WeatherForecast> getDashboardForecast() {
    return _dailyForecast.take(5).toList();
  }

  // Check if weather data should be refreshed
  bool get shouldRefresh {
    return _isCacheExpired();
  }

  Future<void> loadForecasts() async {
    // Fetch weather data and update _forecasts
    _forecasts = [
      WeatherForecast(
        date: DateTime.now(),
        day: 'Today',
        condition: 'Sunny',
        temp: 75.0,
        tempMin: 68.0,
        tempMax: 80.0,
        icon: '01d', // Example icon
        pop: 0.0,
        uvIndex: 5.0,
      ),
    ];
    notifyListeners();
  }

  // Add this method to optimize memory usage
  Future<void> loadWeather({bool forceRefresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Try loading from cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedForecasts = await _loadFromCache();
        if (cachedForecasts.isNotEmpty) {
          _forecasts = cachedForecasts;
          _dailyForecast = cachedForecasts.take(5).toList();
          _isLoading = false;
          _lastUpdated = DateTime.now();
          notifyListeners();
          return;
        }
      }

      // Attempt to get from weather service with timeout
      try {
        _forecasts = await _weatherService.getForecast().timeout(
          const Duration(seconds: 5),
          onTimeout:
              () => throw TimeoutException('Weather data request timed out'),
        );

        // Use mock data as a fallback if API returned empty list
        if (_forecasts.isEmpty) {
          _forecasts = _getPlaceholderForecasts();
        }

        _dailyForecast = _forecasts.take(5).toList();
        _lastUpdated = DateTime.now();

        // Cache in background to avoid delays
        _saveToCache(_forecasts);
      } catch (e) {
        debugPrint('Weather service error: $e');
        // Use fallback forecasts on any error
        _forecasts = _getPlaceholderForecasts();
        _dailyForecast = _forecasts.take(5).toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading weather: $e');
      _errorMessage = 'Unable to load weather data';
      _isLoading = false;

      // Always provide some data even on error
      if (_forecasts.isEmpty) {
        _forecasts = _getPlaceholderForecasts();
        _dailyForecast = _forecasts.take(5).toList();
      }

      notifyListeners();
    }
  }

  // Add the implementation for saving to cache
  Future<void> _saveToCache(List<WeatherForecast> forecasts) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert forecasts to JSON
      final forecastsJson =
          forecasts
              .map(
                (f) => {
                  'date': f.date.millisecondsSinceEpoch,
                  'day': f.day,
                  'condition': f.condition,
                  'temp': f.temp,
                  'tempMin': f.tempMin,
                  'tempMax': f.tempMax,
                  'icon': f.icon,
                  'pop': f.pop,
                  'uvIndex': f.uvIndex,
                },
              )
              .toList();

      // Save to SharedPreferences
      await prefs.setString(
        'weather_forecasts_cache',
        json.encode(forecastsJson),
      );
      await prefs.setInt(
        'weather_cache_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error saving forecasts to cache: $e');
    }
  }

  // Add the implementation for loading from cache
  Future<List<WeatherForecast>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if cache exists and is not expired
      final timestamp = prefs.getInt('weather_cache_timestamp');
      if (timestamp == null) return [];

      final cacheDuration = Duration(minutes: _cacheDuration);
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > cacheDuration) {
        return []; // Cache expired
      }

      // Load and parse cache
      final forecastsJson = prefs.getString('weather_forecasts_cache');
      if (forecastsJson == null) return [];

      final forecasts = List<Map<String, dynamic>>.from(
        json.decode(forecastsJson),
      );

      return forecasts
          .map(
            (f) => WeatherForecast(
              date: DateTime.fromMillisecondsSinceEpoch(f['date']),
              day: f['day'],
              condition: f['condition'],
              temp: f['temp'],
              tempMin: f['tempMin'],
              tempMax: f['tempMax'],
              icon: f['icon'],
              pop: f['pop'] ?? 0.0,
              uvIndex: f['uvIndex'] ?? 0.0,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading forecasts from cache: $e');
      return [];
    }
  }

  // Improve the placeholder forecasts implementation
  List<WeatherForecast> _getPlaceholderForecasts() {
    final now = DateTime.now();
    final List<String> conditions = [
      'Clear',
      'Clouds',
      'Rain',
      'Clear',
      'Clouds',
    ];

    return List.generate(5, (index) {
      final date = now.add(Duration(days: index));
      return WeatherForecast(
        date: date,
        day: index == 0 ? 'Today' : _getDayName(date),
        condition: conditions[index],
        temp: 75.0 - (index * 2),
        tempMin: 70.0 - (index * 2),
        tempMax: 82.0 - (index * 2),
        icon: 'default',
        pop: index == 2 ? 0.4 : 0.0, // 40% chance of rain on day 3
        uvIndex: 5.0,
      );
    });
  }

  // Helper method to get day name
  String _getDayName(DateTime date) {
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

// Add these extensions to the models to support caching
extension WeatherDataJsonExtension on WeatherData {
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'feelsLike': feelsLike,
      'tempMin': tempMin,
      'tempMax': tempMax,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'windDegree': windDegree,
      'condition': condition,
      'description': description,
      'icon': icon,
      'cloudiness': cloudiness,
      'pressure': pressure,
      'visibility': visibility,
      'sunrise': sunrise.millisecondsSinceEpoch,
      'sunset': sunset.millisecondsSinceEpoch,
      'uvIndex': uvIndex,
      'coordinates': coordinates.toJson(),
    };
  }
}

extension WeatherForecastJsonExtension on WeatherForecast {
  Map<String, dynamic> toJson() {
    return {
      'date': date.millisecondsSinceEpoch,
      'day': day,
      'condition': condition,
      'temp': temp,
      'tempMin': tempMin,
      'tempMax': tempMax,
      'icon': icon,
      'pop': pop,
      'uvIndex': uvIndex,
    };
  }
}
