import 'package:flutter/material.dart';
import 'package:neusenews/widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import 'package:neusenews/providers/weather_provider.dart';
import 'package:neusenews/models/weather_forecast.dart';
import 'package:neusenews/widgets/bottom_nav_bar.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import 'package:neusenews/features/advertising/widgets/weather_sponsor_banner.dart';

class WeatherScreen extends StatefulWidget {
  final bool showAppBar;
  final bool showBottomNav;

  const WeatherScreen({
    super.key,
    this.showAppBar = true,
    this.showBottomNav = true,
  });

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _zipController = TextEditingController(
    text: '28501',
  );
  bool _isRefreshing = false;
  late TabController _tabController;
  final int _selectedNavIndex = 2; // Weather tab is selected by default

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          // No need to track index separately - using _tabController.index directly
        });
      }
    });

    // Initialize weather data from provider - force refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final weatherProvider = Provider.of<WeatherProvider>(
        context,
        listen: false,
      );

      setState(() {
        _zipController.text = weatherProvider.zipCode;
      });

      // Force a refresh of the weather data
      weatherProvider.refreshWeather();
    });
  }

  @override
  void dispose() {
    // Ensure all resources are properly disposed
    _zipController.dispose();
    _tabController.dispose();
    // Cancel any active timers or subscriptions
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Avoid repeatedly fetching data on rebuild
    final weatherProvider = Provider.of<WeatherProvider>(
      context,
      listen: false,
    );
    if (weatherProvider.shouldRefresh) {
      weatherProvider.refreshWeather();
    }
  }

  Future<void> _refreshWeatherData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      final weatherProvider = Provider.of<WeatherProvider>(
        context,
        listen: false,
      );
      await weatherProvider.refreshWeather();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _updateLocation() {
    final query = _zipController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a location')));
      return;
    }

    // Check if input is ZIP code (5 digits) or city name
    final isZipCode = RegExp(r'^\d{5}$').hasMatch(query);

    final weatherProvider = Provider.of<WeatherProvider>(
      context,
      listen: false,
    );

    if (isZipCode) {
      // Update using ZIP code
      weatherProvider.updateZipCode(query);
    } else {
      // Update using city name
      weatherProvider.updateCityName(query);
    }

    // Trigger a refresh of the weather data
    weatherProvider.refreshWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, _) {
        // Build UI based on weatherProvider state
        return Scaffold(
          appBar:
              widget.showAppBar ? AppBar(title: const Text('Weather')) : null,
          drawer: widget.showAppBar ? const AppDrawer() : null,
          body: RefreshIndicator(
            onRefresh: _refreshWeatherData,
            child: _buildWeatherContent(weatherProvider),
          ),
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: 2, // Weather is selected
            onTap: (index) {
              switch (index) {
                case 0: // Home
                  Navigator.pushReplacementNamed(context, '/dashboard');
                  break;
                case 1: // News
                  Navigator.pushReplacementNamed(context, '/news');
                  break;
                case 2: // Weather - already here
                  break;
                case 3: // Calendar
                  Navigator.pushReplacementNamed(context, '/calendar');
                  break;
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildWeatherContent(WeatherProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFd2982a)),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshWeatherData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFd2982a),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    final currentWeather = provider.currentWeather;
    if (currentWeather == null) {
      return const Center(child: Text('No weather data available'));
    }

    return Column(
      children: [
        // Location search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _zipController,
                  decoration: InputDecoration(
                    hintText: 'Enter ZIP code or city',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _updateLocation(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _updateLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd2982a),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Update'),
              ),
            ],
          ),
        ),

        // Tab bar
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFd2982a),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFd2982a),
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'Hourly'),
            Tab(text: 'Daily'),
            Tab(text: 'Alerts'),
          ],
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCurrentTab(provider),
              _buildHourlyTab(provider),
              _buildDailyTab(provider),
              _buildAlertsTab(provider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentTab(WeatherProvider provider) {
    final currentWeather = provider.currentWeather;
    if (currentWeather == null) {
      return const Center(child: Text('No current weather data available'));
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Location name and last updated
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFFd2982a)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.locationName ?? 'Kinston, NC',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last updated: ${DateFormat('h:mm a').format(DateTime.now())}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshWeatherData,
                  color: const Color(0xFFd2982a),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Main weather card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 16.0,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Temperature and conditions
                    Column(
                      children: [
                        Text(
                          '${currentWeather.temperature.round()}°F',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currentWeather.condition,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Feels like ${currentWeather.feelsLike.round()}°F',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    // Weather icon
                    Icon(
                      _getWeatherIcon(currentWeather.condition),
                      size: 80,
                      color: const Color(0xFFd2982a),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Min/Max temps
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTempIndicator(
                      'Low',
                      Icons.arrow_downward,
                      Colors.blue,
                      '${currentWeather.tempMin.round()}°F',
                    ),
                    const SizedBox(width: 32),
                    _buildTempIndicator(
                      'High',
                      Icons.arrow_upward,
                      Colors.red,
                      '${currentWeather.tempMax.round()}°F',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Add weather sponsor banner here - right before weather details
        const WeatherSponsorBanner(),

        const SizedBox(height: 16),

        // Weather details grid
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weather Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildWeatherDetailItem(
                      'Wind',
                      '${currentWeather.windSpeed} mph',
                      Icons.air,
                    ),
                    _buildWeatherDetailItem(
                      'Humidity',
                      '${currentWeather.humidity}%',
                      Icons.water_drop,
                    ),
                    _buildWeatherDetailItem(
                      'Pressure',
                      '${currentWeather.pressure} hPa',
                      Icons.speed,
                    ),
                    _buildWeatherDetailItem(
                      'Visibility',
                      '${(currentWeather.visibility / 1000).toStringAsFixed(1)} km',
                      Icons.visibility,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Sunrise/Sunset card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sun & Moon',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSunriseSunset(
                      'Sunrise',
                      DateFormat('h:mm a').format(currentWeather.sunrise),
                      Icons.wb_sunny,
                      Colors.amber,
                    ),
                    _buildSunriseSunset(
                      'Sunset',
                      DateFormat('h:mm a').format(currentWeather.sunset),
                      Icons.wb_twilight,
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // NWS attribution
        _buildNWSAttribution(),
      ],
    );
  }

  Widget _buildHourlyTab(WeatherProvider provider) {
    final hourlyForecasts = provider.hourlyForecast;

    if (hourlyForecasts.isEmpty) {
      return const Center(child: Text('No hourly forecast available'));
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Today's hourly forecast
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Hourly Forecast',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: math.min(24, hourlyForecasts.length),
                    itemBuilder: (context, index) {
                      final forecast = hourlyForecasts[index];
                      return _buildHourlyForecastItem(forecast);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // NWS attribution
        _buildNWSAttribution(),
      ],
    );
  }

  Widget _buildDailyTab(WeatherProvider provider) {
    final dailyForecasts = provider.dailyForecast;

    if (dailyForecasts.isEmpty) {
      return const Center(child: Text('No daily forecast available'));
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 7-day forecast
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '7-Day Forecast',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: math.min(7, dailyForecasts.length),
                  separatorBuilder:
                      (context, index) => Divider(color: Colors.grey[300]),
                  itemBuilder: (context, index) {
                    final forecast = dailyForecasts[index];
                    return _buildDailyForecastItem(forecast);
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // NWS attribution
        _buildNWSAttribution(),
      ],
    );
  }

  Widget _buildAlertsTab(WeatherProvider provider) {
    final alerts = provider.weatherAlerts;
    final hasAlerts = alerts.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Active alerts
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasAlerts ? Icons.warning_amber : Icons.check_circle,
                      color: hasAlerts ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasAlerts ? 'Active Weather Alerts' : 'No Active Alerts',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (hasAlerts)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: alerts.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return ListTile(
                        title: Text(
                          alert['event'] ?? 'Weather Alert',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(alert['headline'] ?? ''),
                        leading: Icon(
                          _getAlertIcon(alert['severity'] ?? 'Unknown'),
                          color: _getAlertColor(alert['severity'] ?? 'Unknown'),
                        ),
                        onTap: () => _showAlertDetails(context, alert),
                      );
                    },
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.green[300],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No weather alerts for this area at this time.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Weather safety resources
        // (keep the existing code for this part)
        // ...
        const SizedBox(height: 16),
        _buildNWSAttribution(),
      ],
    );
  }

  IconData _getAlertIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'extreme':
        return Icons.warning_amber;
      case 'severe':
        return Icons.warning;
      case 'moderate':
        return Icons.info;
      case 'minor':
        return Icons.info_outline;
      default:
        return Icons.notification_important;
    }
  }

  Color _getAlertColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'extreme':
        return Colors.red;
      case 'severe':
        return Colors.orange;
      case 'moderate':
        return Colors.yellow.shade800;
      case 'minor':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showAlertDetails(BuildContext context, Map<String, dynamic> alert) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(alert['event'] ?? 'Weather Alert'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (alert['description'] != null &&
                      alert['description'].isNotEmpty)
                    Text(alert['description']),
                  const SizedBox(height: 16),
                  if (alert['instruction'] != null &&
                      alert['instruction'].isNotEmpty) ...[
                    const Text(
                      'Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(alert['instruction']),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  // Utility widgets

  Widget _buildTempIndicator(
    String label,
    IconData icon,
    Color color,
    String value,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildWeatherDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFd2982a), size: 20),
          const SizedBox(width: 8.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSunriseSunset(
    String label,
    String time,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildHourlyForecastItem(WeatherForecast forecast) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('h a').format(forecast.date),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Icon(
            _getWeatherIcon(forecast.condition),
            color: const Color(0xFFd2982a),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            '${forecast.temp.round()}°',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (forecast.pop > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.water_drop, size: 12, color: Colors.blue[400]),
                  const SizedBox(width: 2),
                  Text(
                    '${(forecast.pop * 100).round()}%',
                    style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDailyForecastItem(WeatherForecast forecast) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Day name
          SizedBox(
            width: 100,
            child: Text(
              forecast.day,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // Weather icon and condition
          Row(
            children: [
              Icon(
                _getWeatherIcon(forecast.condition),
                color: const Color(0xFFd2982a),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(forecast.condition, style: const TextStyle(fontSize: 14)),
            ],
          ),

          // Temperature range
          Row(
            children: [
              Text(
                '${forecast.tempMin.round()}°',
                style: TextStyle(fontSize: 14, color: Colors.blue[700]),
              ),
              const Text(' / '),
              Text(
                '${forecast.tempMax.round()}°',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNWSAttribution() {
    return GestureDetector(
      onTap: () => _launchURL('https://www.weather.gov/'),
      child: Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(
              'Weather data provided by',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            const Text(
              'National Weather Service',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00416A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods

  void _showLocationSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Search Location'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _zipController,
                  decoration: const InputDecoration(
                    labelText: 'ZIP Code or City Name',
                    hintText: 'e.g. 28501 or Kinston',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _updateLocation();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd2982a),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Search'),
              ),
            ],
          ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open $url')));
      }
    }
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
    } else if (lowerCondition.contains('wind')) {
      return Icons.air;
    } else {
      return Icons.wb_sunny; // Default
    }
  }

  String _getUVIndexDescription(double uvIndex) {
    if (uvIndex < 3) {
      return 'Low';
    } else if (uvIndex < 6) {
      return 'Moderate';
    } else if (uvIndex < 8) {
      return 'High';
    } else if (uvIndex < 11) {
      return 'Very High';
    } else {
      return 'Extreme';
    }
  }
}
