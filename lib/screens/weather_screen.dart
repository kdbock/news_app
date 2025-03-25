import 'package:flutter/material.dart';
import 'package:news_app/models/weather_data.dart';
import 'package:news_app/models/weather_forecast.dart';
import 'package:news_app/services/weather_service.dart';
import 'package:intl/intl.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  WeatherData? _currentWeather;
  List<WeatherForecast> _forecasts = [];
  bool _isLoading = true;
  String _zipCode = '28501';
  final _zipCodeController = TextEditingController(text: '28501');

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _weatherService.getCurrentWeather(),
        _weatherService.getForecast(),
      ]);

      if (mounted) {
        setState(() {
          _currentWeather = results[0] as WeatherData?;
          _forecasts = results[1] as List<WeatherForecast>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading weather data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading weather data: $e')),
        );
      }
    }
  }

  Future<void> _updateZipCode() async {
    if (_zipCodeController.text.length == 5) {
      await _weatherService.setZipCode(_zipCodeController.text);
      setState(() => _zipCode = _zipCodeController.text);
      _loadWeatherData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 5-digit ZIP code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFd2982a)),
            )
          : RefreshIndicator(
              onRefresh: _loadWeatherData,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ZIP code selector
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _zipCodeController,
                              decoration: InputDecoration(
                                labelText: 'ZIP Code',
                                hintText: 'Enter 5-digit ZIP code',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 5,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _updateZipCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFd2982a),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Update'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Current weather
                      if (_currentWeather != null) ...[
                        _buildCurrentWeather(),
                        const Divider(height: 32),
                      ],

                      // 5-day forecast
                      const Text(
                        '5-Day Forecast',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildForecastList(),
                      
                      // Weather source attribution (required by OpenWeatherMap)
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'Weather data provided by:',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'OpenWeatherMap.org',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentWeather() {
    final weather = _currentWeather!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Weather',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${weather.location} (${_zipCode})',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Updated ${DateFormat('h:mm a').format(weather.lastUpdated)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${weather.temperature.toStringAsFixed(0)}°F',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Feels like ${weather.feelsLike.toStringAsFixed(0)}°F',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  _getWeatherIcon(weather.condition),
                  size: 30,
                  color: const Color(0xFFd2982a),
                ),
                const SizedBox(width: 8),
                Text(
                  weather.condition,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(
                  Icons.air,
                  size: 20,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Wind: ${weather.windSpeed.toStringAsFixed(1)} mph',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForecastList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _forecasts.length,
      itemBuilder: (context, index) {
        final forecast = _forecasts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    forecast.day,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      _getWeatherIcon(forecast.condition),
                      color: const Color(0xFFd2982a),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      forecast.condition,
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                Text(
                  '${forecast.temp.toStringAsFixed(0)}°F',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
      case 'partly cloudy':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
        return Icons.umbrella;
      case 'thunderstorm':
        return Icons.bolt;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.cloud_queue;
      default:
        return Icons.cloud;
    }
  }
}