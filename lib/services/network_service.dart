import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:io';
import 'dart:convert';
import 'package:neusenews/services/network_manager_service.dart';

class NetworkService {
  static final NetworkManagerService _networkManager = NetworkManagerService();

  // Get a configured HTTP client
  static http.Client getClient() {
    if (Platform.isAndroid || Platform.isIOS) {
      final httpClient = _networkManager.createDnsAwareHttpClient();
      return IOClient(httpClient);
    }
    return http.Client();
  }

  // Modified GET method that handles DNS issues
  static Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    // Convert URL to URI and let network manager modify it
    final uri = _networkManager.createDnsAwareUri(Uri.parse(url));

    // Use our custom client
    final client = getClient();

    try {
      final modifiedHeaders = headers ?? {};
      // Add Host header with original hostname when using direct IP
      if (uri.host.contains(RegExp(r'\d+\.\d+\.\d+\.\d+'))) {
        final originalUri = Uri.parse(url);
        modifiedHeaders['Host'] = originalUri.host;
      }

      return await client
          .get(uri, headers: modifiedHeaders)
          .timeout(const Duration(seconds: 10));
    } finally {
      client.close();
    }
  }

  // Helper for getting weather coordinates
  static Future<Map<String, double>> getCoordinatesFromZip(
    String zipCode,
  ) async {
    try {
      // Use our DNS-aware GET method
      final response = await NetworkService.get(
        'https://api.zippopotam.us/us/$zipCode',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lat = double.parse(data['places'][0]['latitude']);
        final lon = double.parse(data['places'][0]['longitude']);
        return {'latitude': lat, 'longitude': lon};
      }
      throw Exception('Failed to get coordinates from ZIP code');
    } catch (e) {
      debugPrint('Error getting coordinates from ZIP: $e');
      // Default to Kinston, NC
      return {'latitude': 35.2627, 'longitude': -77.5816};
    }
  }
}
