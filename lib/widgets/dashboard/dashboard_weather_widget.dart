import 'package:flutter/material.dart';
import 'package:neusenews/models/weather_forecast.dart';

class DashboardWeatherWidget extends StatelessWidget {
  final List<WeatherForecast> forecasts;
  final VoidCallback?
  onSeeAllPressed; // Keep this parameter for dashboard_screen.dart

  const DashboardWeatherWidget({
    super.key,
    required this.forecasts,
    this.onSeeAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (forecasts.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentForecast = forecasts.first;

    // Remove the SectionHeader and start directly with the Card
    return Column(
      children: [
        // SectionHeader removed from here
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Rest of the widget content remains the same
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
                          'H: ${currentForecast.tempMax.round()}°',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'L: ${currentForecast.tempMin.round()}°',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
                // Rest of weather forecast display
              ],
            ),
          ),
        ),
        // Daily forecast section remains
      ],
    );
  }

  IconData _getWeatherIcon(String condition) {
    // Your existing weather icon logic
    final lowerCondition = condition.toLowerCase();
    if (lowerCondition.contains('cloud')) return Icons.cloud;
    if (lowerCondition.contains('rain')) return Icons.grain;
    if (lowerCondition.contains('snow')) return Icons.ac_unit;
    if (lowerCondition.contains('thunder')) return Icons.flash_on;
    return Icons.wb_sunny;
  }
}
