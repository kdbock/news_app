import 'package:flutter/material.dart';
import 'package:neusenews/models/weather_forecast.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WeatherCard extends StatelessWidget {
  final WeatherForecast forecast;
  final bool showFullDetails;
  final bool useMetric;

  const WeatherCard({
    super.key,
    required this.forecast,
    this.showFullDetails = false,
    this.useMetric = false,
  });

  String _formatTemperature(double temp) {
    if (useMetric) {
      return '${((temp - 32) * 5 / 9).round()}°C';
    }
    return '${temp.round()}°F';
  }

  String _getRainChanceText(double pop) {
    final percentage = (pop * 100).round();
    return '$percentage%';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Day & Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        forecast.day,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (showFullDetails)
                        Text(
                          '${forecast.date.month}/${forecast.date.day}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),

                // Weather icon
                CachedNetworkImage(
                  imageUrl:
                      'https://openweathermap.org/img/wn/${forecast.icon}@2x.png',
                  width: 50,
                  height: 50,
                  placeholder:
                      (context, url) => const SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  errorWidget:
                      (context, url, error) => const Icon(
                        Icons.cloud_off,
                        size: 40,
                        color: Colors.grey,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Condition & Temperature
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(forecast.condition, style: const TextStyle(fontSize: 16)),
                Row(
                  children: [
                    Text(
                      _formatTemperature(forecast.tempMax),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTemperature(forecast.tempMin),
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),

            if (showFullDetails) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Additional details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailItem(
                    Icons.water_drop,
                    _getRainChanceText(forecast.pop),
                    'Rain Chance',
                  ),
                  _buildDetailItem(
                    Icons.thermostat,
                    _formatTemperature(forecast.temp),
                    'Avg Temp',
                  ),
                  _buildDetailItem(
                    Icons.wb_sunny,
                    forecast.uvIndex.toStringAsFixed(1),
                    'UV Index',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFd2982a)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
