class WeatherData {
  final String condition;
  final double temperature;
  final double feelsLike;
  final double windSpeed;
  final String location;
  final DateTime lastUpdated;

  WeatherData({
    required this.condition,
    required this.temperature,
    required this.feelsLike,
    required this.windSpeed,
    required this.location,
    required this.lastUpdated,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      condition: json['weather'][0]['main'] ?? 'Unknown',
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      location: json['name'] ?? 'Unknown Location',
      lastUpdated: DateTime.now(),
    );
  }

  String get weatherImage {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'assets/images/weather/Clear.jpeg';
      case 'clouds':
        return 'assets/images/weather/Cloudy.jpeg';
      case 'rain':
      case 'drizzle':
        return 'assets/images/weather/Rain.jpeg';
      case 'thunderstorm':
        return 'assets/images/weather/Thunder.jpeg';
      case 'snow':
        return 'assets/images/weather/Snow.jpeg';
      case 'mist':
      case 'fog':
        return 'assets/images/weather/Fog.jpeg';
      default:
        return 'assets/images/weather/Default.jpeg';
    }
  }
}
