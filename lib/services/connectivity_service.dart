import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  bool _forcedOffline = false;
  final bool _previouslyOnline = true;
  StreamSubscription? _connectivitySubscription;
  
  final _connectivityStreamController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _connectivityStreamController.stream;
  
  bool get isOnline => _isOnline && !_forcedOffline;
  
  ConnectivityService() {
    checkConnection();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }
  
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isOnline = false;
      notifyListeners();
    }
  }
  
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    if (_forcedOffline) {
      _isOnline = false;
      _connectivityStreamController.add(false);
      notifyListeners();
      return;
    }
    
    if (result == ConnectivityResult.none) {
      _isOnline = false;
    } else {
      try {
        final response = await http.get(
          Uri.parse('https://www.google.com/generate_204'),
        ).timeout(const Duration(seconds: 3));
        
        _isOnline = response.statusCode == 204 || response.statusCode == 200;
      } catch (_) {
        try {
          final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
          _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        } catch (_) {
          _isOnline = false;
        }
      }
    }
    
    _connectivityStreamController.add(_isOnline);
    notifyListeners();
  }

  Future<void> checkConnection() async {
    try {
      if (_forcedOffline) {
        _isOnline = false;
        _connectivityStreamController.add(false);
        notifyListeners();
        return;
      }
      
      final hasRealConnectivity = await checkRealConnectivity();
      
      // Update connectivity status
      _isOnline = hasRealConnectivity;
      _connectivityStreamController.add(hasRealConnectivity);
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isOnline = false;
      _connectivityStreamController.add(false);
      notifyListeners();
    }
  }

  // Make sure this method is working as expected
  Future<bool> checkRealConnectivity() async {
    // First check if we have a network interface
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    
    // Try socket connections to reliable DNS servers
    for (final server in ['8.8.8.8', '1.1.1.1']) {
      try {
        final socket = await Socket.connect(
          server, 
          53,  // DNS port
          timeout: const Duration(seconds: 3)
        );
        await socket.close();
        return true;
      } catch (e) {
        debugPrint('Socket test failed for $server: $e');
        // Continue to next server
      }
    }
    
    return false;
  }

  void forceOnlineMode() {
    _forcedOffline = false;
    checkConnection();
  }

  void forceOfflineMode() {
    _forcedOffline = true;
    _isOnline = false;
    _connectivityStreamController.add(false);
    notifyListeners();
  }
  
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityStreamController.close();
    super.dispose();
  }
  
  bool isFeatureAvailableOffline(String feature) {
    if (!_isOnline) {
      switch (feature) {
        case 'news': return true;
        case 'weather': return false;
        case 'calendar': return true;
        case 'admin': return false;
        default: return false;
      }
    }
    return true;
  }

  String getOfflineMessage(String feature) {
    switch (feature) {
      case 'weather': 
        return 'Weather information requires an internet connection.';
      case 'admin': 
        return 'Admin functions are not available offline.';
      case 'submit': 
        return 'Submission features are not available offline.';
      default:
        return 'This feature requires an internet connection.';
    }
  }
}