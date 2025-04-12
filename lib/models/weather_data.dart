class WeatherData {
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final double windSpeed;
  final int windDegree;
  final String condition;
  final String description;
  final String icon;
  final int cloudiness;
  final int pressure;
  final int visibility;
  final DateTime sunrise;
  final DateTime sunset;
  final double uvIndex;
  // Add the coordinates property
  final Coordinates coordinates;
  
  WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeed,
    required this.windDegree,
    required this.condition,
    required this.description,
    required this.icon,
    required this.cloudiness,
    required this.pressure,
    required this.visibility,
    required this.sunrise,
    required this.sunset,
    this.uvIndex = 0.0,
    required this.coordinates,
  });
  
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      tempMin: (json['main']['temp_min'] as num).toDouble(),
      tempMax: (json['main']['temp_max'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      windDegree: (json['wind']['deg'] as num).toInt(),
      condition: json['weather'][0]['main'] as String,
      description: json['weather'][0]['description'] as String,
      icon: json['weather'][0]['icon'] as String,
      cloudiness: json['clouds']['all'] as int,
      pressure: json['main']['pressure'] as int,
      visibility: json['visibility'] as int,
      sunrise: DateTime.fromMillisecondsSinceEpoch((json['sys']['sunrise'] as int) * 1000),
      sunset: DateTime.fromMillisecondsSinceEpoch((json['sys']['sunset'] as int) * 1000),
      uvIndex: json['uvi'] != null ? (json['uvi'] as num).toDouble() : 0.0,
      coordinates: Coordinates(
        latitude: (json['coord']['lat'] as num).toDouble(),
        longitude: (json['coord']['lon'] as num).toDouble(),
      ),
    );
  }
  
  // Fallback constructor for when API fails
  factory WeatherData.fallback() {
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
      icon: '01d',
      cloudiness: 0,
      pressure: 1015,
      visibility: 10000,
      sunrise: DateTime(now.year, now.month, now.day, 6, 30),
      sunset: DateTime(now.year, now.month, now.day, 20, 15),
      uvIndex: 5.0,
      coordinates: Coordinates(latitude: 35.2627, longitude: -77.5816), // Default to Kinston, NC
    );
  }
}

class Coordinates {
  final double latitude;
  final double longitude;
  
  Coordinates({required this.latitude, required this.longitude});
  
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
  
  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }
}
