import 'package:flutter/material.dart';
import 'package:neusenews/models/weather_data.dart';
import 'package:neusenews/models/weather_forecast.dart';
import 'package:intl/intl.dart';

class DashboardWeatherCard extends StatelessWidget {
  final WeatherData currentWeather;
  final List<WeatherForecast> forecasts;
  final VoidCallback onTap;
  final String? locationName;

  const DashboardWeatherCard({
    super.key,
    required this.currentWeather,
    required this.forecasts,
    required this.onTap,
    this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFd2982a).withOpacity(0.8),
                const Color(0xFFd2982a).withOpacity(0.6),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location and view more row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          locationName ?? 'Kinston, NC',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text(
                          'View Details',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ],
                ),

                // Current weather display
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Temperature and condition
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${currentWeather.temperature.round()}°',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            currentWeather.condition,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      // Weather icon
                      Icon(
                        _getWeatherIcon(currentWeather.condition),
                        size: 50,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),

                // High/low temperatures
                Row(
                  children: [
                    _buildTempIndicator('Low', currentWeather.tempMin.round()),
                    const SizedBox(width: 16),
                    _buildTempIndicator('High', currentWeather.tempMax.round()),
                  ],
                ),

                // Last updated text
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Updated ${DateFormat('h:mm a').format(DateTime.now())}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTempIndicator(String label, int temp) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
        ),
        Text(
          '$temp°',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  IconData _getWeatherIcon(String condition) {
    final lowerCondition = condition.toLowerCase();
    if (lowerCondition.contains('clear') || lowerCondition.contains('sunny')) {
      return Icons.wb_sunny;
    } else if (lowerCondition.contains('partly cloud')) {
      return Icons.wb_cloudy;
    } else if (lowerCondition.contains('cloud')) {
      return Icons.cloud;
    } else if (lowerCondition.contains('rain') ||
        lowerCondition.contains('shower')) {
      return Icons.water_drop;
    } else if (lowerCondition.contains('snow')) {
      return Icons.ac_unit;
    } else if (lowerCondition.contains('thunder')) {
      return Icons.flash_on;
    } else if (lowerCondition.contains('fog') ||
        lowerCondition.contains('mist')) {
      return Icons.cloud_queue;
    } else {
      return Icons.wb_sunny; // Default
    }
  }
}
