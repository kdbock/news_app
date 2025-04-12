import 'package:flutter/material.dart';
import 'package:neusenews/models/weather_forecast.dart';

class WeatherSection extends StatelessWidget {
  final List<WeatherForecast> forecasts;

  const WeatherSection({
    super.key,
    required this.forecasts,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: forecasts.isEmpty
        ? Center(
            child: Text(
              'Weather data unavailable',
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        : ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: forecasts.length,
            itemBuilder: (context, index) {
              final forecast = forecasts[index];
              return WeatherCard(forecast: forecast);
            },
          ),
    );
  }
}

class WeatherCard extends StatelessWidget {
  final WeatherForecast forecast;

  const WeatherCard({
    super.key,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              forecast.day,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildWeatherIcon(forecast.condition),
            const SizedBox(height: 8),
            Text('${forecast.temp.round()}°F'),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherIcon(String condition) {
    return Icon(
      _getWeatherIcon(condition),
      color: const Color(0xFFd2982a),
      size: 24,
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