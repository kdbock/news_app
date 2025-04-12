import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NetworkManagerService extends ChangeNotifier {
  // Singleton pattern
  static final NetworkManagerService _instance =
      NetworkManagerService._internal();
  factory NetworkManagerService() => _instance;
  NetworkManagerService._internal();

  // DNS mapping for common services
  static final Map<String, String> _hostToIpMapping = {
    'firestore.googleapis.com': '142.250.177.206',
    'api.weather.gov': '23.70.87.43',
    'api.zippopotam.us': '104.21.234.116',
    'images.squarespace-cdn.com': '151.101.1.61',
    'firebasestorage.googleapis.com': '142.250.177.206',
    'neusenews.com': '75.2.65.87',
    'www.neusenews.com': '75.2.65.87',
    'www.neusenewssports.com': '75.2.65.87',
    'www.ncpoliticalnews.com': '75.2.65.87',
  };

  bool _manualOverride = false;
  bool _isOnline = false;
  bool _dnsWorking = false;
  Timer? _checkTimer;
  final Duration _checkInterval = const Duration(seconds: 30);

  bool get isOnline => _manualOverride || (_isOnline && _dnsWorking);
  bool get isDnsWorking => _dnsWorking;

  // Initialize the service
  Future<void> initialize() async {
    // Check connectivity immediately
    await checkConnectivity();

    // Then start periodic checks
    _checkTimer = Timer.periodic(_checkInterval, (_) => checkConnectivity());

    // Try to restore manual override status from preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      _manualOverride = prefs.getBool('network_manual_override') ?? false;
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  // Check both connectivity and DNS resolution
  Future<bool> checkConnectivity() async {
    try {
      // First check basic connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      _isOnline = connectivityResult != ConnectivityResult.none;

      // Then verify DNS is working by making a real connection
      if (_isOnline) {
        _dnsWorking = await _checkDnsResolution();
      } else {
        _dnsWorking = false;
      }

      notifyListeners();
      return isOnline;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _dnsWorking = false;
      notifyListeners();
      return false;
    }
  }

  // Check if DNS is working by making a real connection
  Future<bool> _checkDnsResolution() async {
    try {
      // Try Google's DNS server first (it's usually reliable)
      final socket = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();

      // Then try an actual HTTP request to confirm
      final response = await http
          .get(
            Uri.parse('https://www.google.com/generate_204'),
            headers: {'Cache-Control': 'no-cache'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 204;
    } catch (e) {
      debugPrint('DNS check failed: $e');
      return false;
    }
  }

  // Force online mode and save state
  Future<void> forceOnlineMode() async {
    _manualOverride = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('network_manual_override', true);
    } catch (e) {
      debugPrint('Failed to save manual override status: $e');
    }

    // Still perform a real check in the background
    checkConnectivity();
  }

  // Reset to automatic detection
  Future<void> resetToAutoDetection() async {
    _manualOverride = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('network_manual_override', false);
    } catch (e) {
      debugPrint('Failed to save manual override status: $e');
    }

    // Perform a check immediately
    await checkConnectivity();
  }

  // Get an IP address for a hostname
  String? getIpForHost(String hostname) {
    return _hostToIpMapping[hostname];
  }

  // Build a host-overriding HTTP client
  HttpClient createDnsAwareHttpClient() {
    final httpClient = HttpClient();

    // Override DNS lookups when needed
    httpClient.badCertificateCallback = ((_, __, ___) => true);

    return httpClient;
  }

  // Create a modified URL that uses IP instead of hostname if needed
  Uri createDnsAwareUri(Uri originalUri) {
    final String resolvedHost =
        _hostToIpMapping[originalUri.host] ?? originalUri.host;

    if (resolvedHost != originalUri.host) {
      // Use IP address instead of hostname
      return Uri(
        scheme: originalUri.scheme,
        host: resolvedHost,
        port: originalUri.port,
        path: originalUri.path,
        query: originalUri.query,
      );
    }
    return originalUri;
  }
}
