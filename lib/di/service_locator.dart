import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:neusenews/services/news_service.dart';
import 'package:neusenews/providers/news_provider.dart';
import 'package:neusenews/services/weather_service.dart';
import 'package:neusenews/providers/weather_provider.dart';
import 'package:neusenews/services/event_service.dart';
import 'package:neusenews/providers/events_provider.dart';
import 'package:neusenews/repositories/news_prefetch_repository.dart';
import 'package:neusenews/services/connectivity_service.dart';

import '../features/advertising/repositories/ad_repository.dart';
import '../features/advertising/services/ad_service.dart';
import '../features/advertising/services/ad_analytics_service.dart';
import '../features/advertising/services/ad_lifecycle_service.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Register core services
  setupCoreServices();

  // Register feature-specific services
  setupAdvertisingServices();

  // Register news and general app services
  setupAppServices();
}

void setupCoreServices() {
  // Firebase services
  serviceLocator.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );
  serviceLocator.registerLazySingleton<FirebaseAuth>(
    () => FirebaseAuth.instance,
  );
  serviceLocator.registerLazySingleton<FirebaseStorage>(
    () => FirebaseStorage.instance,
  );

  // Add ConnectivityService
  serviceLocator.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(),
  );
}

void setupAdvertisingServices() {
  // Register repositories
  serviceLocator.registerLazySingleton<AdRepository>(
    () => AdRepository(
      firestore: serviceLocator<FirebaseFirestore>(),
      storage: serviceLocator<FirebaseStorage>(),
    ),
  );

  // Register services that use repositories
  serviceLocator.registerLazySingleton<AdService>(
    () => AdService(
      repository: serviceLocator<AdRepository>(),
      auth: serviceLocator<FirebaseAuth>(),
    ),
  );

  // Register analytics service
  serviceLocator.registerLazySingleton<AdAnalyticsService>(
    () => AdAnalyticsService(repository: serviceLocator<AdRepository>()),
  );

  // Register lifecycle service
  serviceLocator.registerLazySingleton<AdLifecycleService>(
    () => AdLifecycleService(repository: serviceLocator<AdRepository>()),
  );
}

void setupAppServices() {
  // First register all the basic services
  serviceLocator.registerLazySingleton<NewsService>(() => NewsService());
  serviceLocator.registerLazySingleton<WeatherService>(() => WeatherService());
  serviceLocator.registerLazySingleton<EventService>(() => EventService());

  // Register Repositories BEFORE providers that depend on them
  serviceLocator.registerLazySingleton<NewsPrefetchRepository>(
    () => NewsPrefetchRepository(),
  );

  // Register the NewsProvider with dependency injection instead of having it access serviceLocator directly
  serviceLocator.registerLazySingleton<NewsProvider>(() {
    return NewsProvider(
      newsService: serviceLocator<NewsService>(),
      connectivityService: serviceLocator<ConnectivityService>(),
      prefetchRepository: serviceLocator<NewsPrefetchRepository>(),
    );
  });

  // Register other providers
  serviceLocator.registerLazySingleton<WeatherProvider>(
    () => WeatherProvider(),
  );
  serviceLocator.registerLazySingleton<EventsProvider>(
    () => EventsProvider(eventService: serviceLocator<EventService>()),
  );
}
