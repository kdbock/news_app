import 'package:neusenews/services/connectivity_service.dart';
import 'package:neusenews/providers/news_provider.dart';
import 'package:neusenews/providers/weather_provider.dart';
import 'package:neusenews/providers/events_provider.dart';

class AppServices {
  final ConnectivityService connectivityService;
  final NewsProvider newsProvider;
  final WeatherProvider weatherProvider;
  final EventsProvider eventsProvider;

  AppServices({
    required this.connectivityService,
    required this.newsProvider,
    required this.weatherProvider,
    required this.eventsProvider,
  });
}
