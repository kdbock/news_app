class WeatherForecast {
  final DateTime date;
  final String day;
  final String condition;
  final double temp;
  final String icon;

  WeatherForecast({
    required this.date,
    required this.day,
    required this.condition,
    required this.temp,
    required this.icon,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    final timestamp = json['dt'] * 1000;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
    return WeatherForecast(
      date: date,
      day: _getDayName(date),
      condition: json['weather'][0]['main'],
      temp: (json['main']['temp'] as num).toDouble(),
      icon: json['weather'][0]['icon'],
    );
  }

  static String _getDayName(DateTime date) {
    final now = DateTime.now();
    
    if (date.day == now.day) {
      return 'Today';
    }
    
    if (date.day == now.day + 1) {
      return 'Tomorrow';
    }
    
    // Full day names
    switch (date.weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }
}