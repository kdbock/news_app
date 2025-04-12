import 'package:flutter/material.dart';
import 'package:neusenews/models/weather_forecast.dart';
import 'package:neusenews/widgets/components/section_header.dart';

class DashboardWeatherWidget extends StatelessWidget {
  final List<WeatherForecast> forecasts;
  final VoidCallback onSeeAllPressed;
  
  const DashboardWeatherWidget({
    super.key,
    required this.forecasts,
    required this.onSeeAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (forecasts.isEmpty) {
      return Container(); // Return empty container if no forecast data
    }
    
    final currentForecast = forecasts.first;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Weather',
          onSeeAllPressed: onSeeAllPressed,
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _getWeatherIcon(currentForecast.condition),
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${currentForecast.temperature.round()}°',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currentForecast.condition,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'H: ${currentForecast.highTemp.round()}°',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'L: ${currentForecast.lowTemp.round()}°',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  IconData _getWeatherIcon(String condition) {
    final lowerCondition = condition.toLowerCase();
    if (lowerCondition.contains('clear') || lowerCondition.contains('sunny')) {
      return Icons.wb_sunny;
    } else if (lowerCondition.contains('cloud')) {
      return Icons.cloud;
    } else if (lowerCondition.contains('rain') || lowerCondition.contains('shower')) {
      return Icons.beach_access;
    } else if (lowerCondition.contains('snow')) {
      return Icons.ac_unit;
    } else if (lowerCondition.contains('storm') || lowerCondition.contains('thunder')) {
      return Icons.flash_on;
    } else {
      return Icons.cloud;
    }
  }
}