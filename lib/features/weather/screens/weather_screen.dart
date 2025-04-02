import 'package:flutter/material.dart';
import 'package:neusenews/models/weather_data.dart';
import 'package:neusenews/models/weather_forecast.dart';
import 'package:neusenews/services/weather_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neusenews/widgets/ad_banner.dart';
import 'package:neusenews/models/ad.dart';
import 'package:neusenews/widgets/app_drawer.dart';
import 'dart:async';

class WeatherScreen extends StatefulWidget {
  final bool showAppBar;

  const WeatherScreen({super.key, this.showAppBar = true});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _zipController = TextEditingController(
    text: '28501',
  );

  String _currentZip = '28501'; // Default to Kinston, NC
  String? _locationName;
  WeatherData? _currentWeather;
  List<WeatherForecast> _hourlyForecast = [];
  List<WeatherForecast> _dailyForecast = [];
  Map<String, dynamic>? _airQuality;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  TabController? _tabController;
  final ScrollController _scrollController = ScrollController();
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedZip();

    // Auto refresh every 30 minutes
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      if (mounted) {
        _refreshWeatherData();
      }
    });
  }

  @override
  void dispose() {
    _zipController.dispose();
    _tabController?.dispose();
    _scrollController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedZip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedZip = prefs.getString('weather_zip');

      if (savedZip != null && savedZip.isNotEmpty) {
        setState(() {
          _currentZip = savedZip;
          _zipController.text = savedZip;
        });
      }

      await _loadWeatherData();
    } catch (e) {
      _setError('Failed to load saved location');
    }
  }

  Future<void> _saveZip(String zip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('weather_zip', zip);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _loadWeatherData() async {
    if (_currentZip.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get location name
      _locationName = await _weatherService.getCityFromZip(_currentZip);

      // Run all API calls concurrently using Future.wait
      final results = await Future.wait([
        _weatherService.getCurrentWeather(_currentZip),
        _weatherService.getHourlyForecast(_currentZip),
        _weatherService.getDailyForecast(_currentZip),
        _weatherService.getAirQuality(_currentZip),
      ]);

      if (mounted) {
        setState(() {
          _currentWeather = results[0] as WeatherData;
          _hourlyForecast =
              (results[1] as List<WeatherForecast>)
                  .take(24)
                  .toList(); // Limit to 24 hours
          _dailyForecast = results[2] as List<WeatherForecast>;
          _airQuality = results[3] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      _setError('Error loading weather data: $e');
    }
  }

  Future<void> _refreshWeatherData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      await _loadWeatherData();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _setError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  void _updateZipCode() {
    final zip = _zipController.text.trim();
    if (zip.isEmpty || zip.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 5-digit ZIP code')),
      );
      return;
    }

    setState(() {
      _currentZip = zip;
    });

    _saveZip(zip);
    _loadWeatherData();
  }

  String _formatTemperature(double temp) {
    return '${temp.round()}°F';
  }

  String _getAirQualityLevel(int aqi) {
    switch (aqi) {
      case 1:
        return 'Good';
      case 2:
        return 'Fair';
      case 3:
        return 'Moderate';
      case 4:
        return 'Poor';
      case 5:
        return 'Very Poor';
      default:
        return 'Unknown';
    }
  }

  Color _getAirQualityColor(int aqi) {
    switch (aqi) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getUVIndexLevel(double uvi) {
    if (uvi < 3) {
      return 'Low';
    } else if (uvi < 6) {
      return 'Moderate';
    } else if (uvi < 8) {
      return 'High';
    } else if (uvi < 11) {
      return 'Very High';
    } else {
      return 'Extreme';
    }
  }

  Color _getUVIndexColor(double uvi) {
    if (uvi < 3) {
      return Colors.green;
    } else if (uvi < 6) {
      return Colors.yellow;
    } else if (uvi < 8) {
      return Colors.orange;
    } else if (uvi < 11) {
      return Colors.red;
    } else {
      return Colors.purple;
    }
  }

  String _formatDateTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat.jm().format(dateTime);
  }

  String _getRainChanceText(double pop) {
    final percentage = (pop * 100).round();
    return '$percentage%';
  }

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFd2982a)),
              )
              : _errorMessage != null
              ? _buildErrorView()
              : _buildWeatherContent(),

          // Weather sponsor ad
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: AdBanner(adType: AdType.weather),
          ),
        ],
      ),
    );

    return widget.showAppBar
        ? Scaffold(
          appBar: AppBar(
            title: const Text('Weather'),
            backgroundColor: const Color(0xFFd2982a),
          ),
          drawer: const AppDrawer(),
          body: body,
        )
        : body;
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshWeatherData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFd2982a),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherContent() {
    return RefreshIndicator(
      onRefresh: _refreshWeatherData,
      backgroundColor: Colors.white,
      color: const Color(0xFFd2982a),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current weather header
            _buildCurrentWeatherHeader(),

            const Divider(height: 1),

            // Today's details
            _buildTodayDetails(),

            const SizedBox(height: 16),

            // Air quality card
            if (_airQuality != null) _buildAirQualityCard(),

            const SizedBox(height: 16),

            // Tab controller for hourly/daily forecasts
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(
                      51,
                    ), // Replace withOpacity(0.2) with withAlpha(51) (0.2*255≈51)
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFd2982a),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: const Color(0xFFd2982a),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Hourly Forecast'),
                  Tab(text: '5-Day Forecast'),
                ],
              ),
            ),

            // Tab view content
            SizedBox(
              height: 200,
              child: TabBarView(
                controller: _tabController,
                children: [_buildHourlyForecast(), _buildDailyForecast()],
              ),
            ),

            const SizedBox(height: 24),

            // Weather map section
            _buildWeatherMapSection(),

            const SizedBox(height: 16),

            // Weather Alerts Section (placeholder)
            _buildWeatherAlertsSection(),

            const SizedBox(height: 24),

            // Weather information source
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Weather data provided by OpenWeatherMap',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue[400]!, Colors.blue[700]!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                _locationName ?? 'Location',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _formatTemperature(_currentWeather!.temperature),
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Feels like ${_formatTemperature(_currentWeather!.feelsLike)}',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Image.network(
                      'https://openweathermap.org/img/wn/${_currentWeather!.icon}@2x.png',
                      width: 80,
                      height: 80,
                      errorBuilder:
                          (context, error, stackTrace) => const Icon(
                            Icons.cloud,
                            size: 80,
                            color: Colors.white,
                          ),
                    ),
                    Text(
                      _currentWeather!.condition,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _currentWeather!.description,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWeatherInfoItem(
                Icons.water_drop,
                '${_currentWeather!.humidity}%',
                'Humidity',
              ),
              _buildWeatherInfoItem(
                Icons.air,
                '${_currentWeather!.windSpeed} mph',
                'Wind',
              ),
              _buildWeatherInfoItem(
                Icons.compress,
                '${_currentWeather!.pressure} hPa',
                'Pressure',
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildWeatherInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildTodayDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d2c31),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Visibility',
                  '${(_currentWeather!.visibility / 1000).toStringAsFixed(1)} km',
                  Icons.visibility,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Sunrise',
                  _formatDateTime(_currentWeather!.sunrise),
                  Icons.wb_sunny,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Sunset',
                  _formatDateTime(_currentWeather!.sunset),
                  Icons.nightlight_round,
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFd2982a), size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAirQualityCard() {
    final airQualityData = _airQuality!['list'][0];
    final aqi = airQualityData['main']['aqi'] as int;
    final aqiLevel = _getAirQualityLevel(aqi);
    final aqiColor = _getAirQualityColor(aqi);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.air, color: Color(0xFFd2982a)),
                  const SizedBox(width: 8),
                  const Text(
                    'Air Quality',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: aqiColor.withAlpha(
                        51,
                      ), // Replace withOpacity(0.2) with withAlpha(51)
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: aqiColor),
                    ),
                    child: Text(
                      aqiLevel,
                      style: TextStyle(
                        color: aqiColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAirPollutantItem(
                'Carbon Monoxide (CO)',
                '${airQualityData['components']['co']} μg/m³',
              ),
              _buildAirPollutantItem(
                'Nitrogen Dioxide (NO₂)',
                '${airQualityData['components']['no2']} μg/m³',
              ),
              _buildAirPollutantItem(
                'Ozone (O₃)',
                '${airQualityData['components']['o3']} μg/m³',
              ),
              _buildAirPollutantItem(
                'Sulfur Dioxide (SO₂)',
                '${airQualityData['components']['so2']} μg/m³',
              ),
              _buildAirPollutantItem(
                'Fine Particles (PM2.5)',
                '${airQualityData['components']['pm2_5']} μg/m³',
              ),
              _buildAirPollutantItem(
                'Coarse Particles (PM10)',
                '${airQualityData['components']['pm10']} μg/m³',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAirPollutantItem(String name, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      scrollDirection: Axis.horizontal,
      itemCount: _hourlyForecast.length,
      itemBuilder: (context, index) {
        final forecast = _hourlyForecast[index];
        final hour = DateFormat('ha').format(forecast.date);

        return Container(
          width: 80,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              Text(hour, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Image.network(
                'https://openweathermap.org/img/wn/${forecast.icon}.png',
                width: 40,
                height: 40,
                errorBuilder:
                    (context, error, stackTrace) =>
                        const Icon(Icons.cloud, size: 40, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                _formatTemperature(forecast.temp),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.water_drop, size: 12, color: Colors.blue),
                  const SizedBox(width: 2),
                  Text(
                    _getRainChanceText(forecast.pop),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyForecast() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: _dailyForecast.length,
      itemBuilder: (context, index) {
        final forecast = _dailyForecast[index];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  forecast.day,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Image.network(
                      'https://openweathermap.org/img/wn/${forecast.icon}.png',
                      width: 40,
                      height: 40,
                      errorBuilder:
                          (context, error, stackTrace) => const Icon(
                            Icons.cloud,
                            size: 40,
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(forecast.condition),
                        Row(
                          children: [
                            const Icon(
                              Icons.water_drop,
                              size: 12,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _getRainChanceText(forecast.pop),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.wb_sunny,
                              size: 12,
                              color: _getUVIndexColor(forecast.uvIndex),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'UV: ${forecast.uvIndex.round()}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTemperature(forecast.tempMax),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTemperature(forecast.tempMin),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeatherMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weather Maps',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d2c31),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Open full map view
                },
                child: const Text(
                  'Full Map',
                  style: TextStyle(color: Color(0xFFd2982a)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            scrollDirection: Axis.horizontal,
            children: [
              _buildMapTypeCard('Temperature', 'temp_new', Icons.thermostat),
              _buildMapTypeCard('Clouds', 'clouds_new', Icons.cloud),
              _buildMapTypeCard(
                'Precipitation',
                'precipitation_new',
                Icons.grain,
              ),
              _buildMapTypeCard('Wind Speed', 'wind_new', Icons.air),
              _buildMapTypeCard('Pressure', 'pressure_new', Icons.compress),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapTypeCard(String title, String layer, IconData icon) {
    final lat = 35.2627; // Kinston, NC approximate coordinates
    final lon = -77.5816;
    final zoom = 8;
    final url =
        'https://tile.openweathermap.org/map/$layer/$zoom/$lat/$lon.png?appid=${WeatherService.apiKey}';

    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withAlpha(
                  77,
                ), // Replace withOpacity(0.3) with withAlpha(77) (0.3*255≈77)
                BlendMode.darken,
              ),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAlertsSection() {
    // This is just a placeholder - in a real app, you would fetch actual alerts
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.amber[50],
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'No current weather alerts for this area.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
