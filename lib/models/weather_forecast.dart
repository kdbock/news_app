class WeatherForecast {
  final DateTime date;
  final String day;
  final String condition;
  final double temp;
  final double tempMin;
  final double tempMax;
  final String icon;
  final double pop; // Precipitation probability
  final double uvIndex;

  WeatherForecast({
    required this.date,
    required this.day,
    required this.condition,
    required this.temp,
    required this.icon,
    this.tempMin = 0.0,
    this.tempMax = 0.0,
    this.pop = 0.0,
    this.uvIndex = 0.0,
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
    } else if (date.day == now.day + 1) {
      return 'Tomorrow';
    } else {
      switch (date.weekday) {
        case 1:
          return 'Monday';
        case 2:
          return 'Tuesday';
        case 3:
          return 'Wednesday';
        case 4:
          return 'Thursday';
        case 5:
          return 'Friday';
        case 6:
          return 'Saturday';
        case 7:
          return 'Sunday';
        default:
          return '';
      }
    }
  }
}
