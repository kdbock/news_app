import 'package:flutter/material.dart';
import 'package:neusenews/models/weather_forecast.dart';
import 'package:intl/intl.dart';

class WeatherCard extends StatelessWidget {
  final WeatherForecast forecast;
  final bool isHourly;

  const WeatherCard({
    super.key,
    required this.forecast,
    this.isHourly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        width: isHourly ? 80 : 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day or time
            Text(
              _getTimeOrDay(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Weather icon
            _getWeatherIcon(),
            const SizedBox(height: 8),
            
            // Temperature
            Text(
              '${forecast.temp.round()}°F',
              style: const TextStyle(fontSize: 14),
            ),
            
            // Precipitation probability (if not 0)
            if (forecast.pop > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${(forecast.pop * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getTimeOrDay() {
    if (isHourly) {
      return DateFormat('h a').format(forecast.date);
    } else {
      return forecast.day;
    }
  }

  Widget _getWeatherIcon() {
    IconData iconData;
    Color iconColor;

    // Determine icon and color based on condition
    switch (forecast.condition.toLowerCase()) {
      case 'clear':
        iconData = Icons.wb_sunny;
        iconColor = Colors.orange;
        break;
      case 'clouds':
      case 'partly cloudy':
        iconData = Icons.cloud;
        iconColor = Colors.grey;
        break;
      case 'rain':
      case 'drizzle':
        iconData = Icons.umbrella;
        iconColor = Colors.blue;
        break;
      case 'thunderstorm':
        iconData = Icons.flash_on;
        iconColor = Colors.amber;
        break;
      case 'snow':
        iconData = Icons.ac_unit;
        iconColor = Colors.lightBlue;
        break;
      case 'mist':
      case 'fog':
      case 'haze':
        iconData = Icons.cloud_queue;
        iconColor = Colors.blueGrey;
        break;
      default:
        iconData = Icons.cloud;
        iconColor = Colors.grey;
    }

    return Icon(
      iconData,
      color: iconColor,
      size: 28,
    );
  }
}