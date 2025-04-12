// Create this new file

import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';

class DnsResolverClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final Map<String, String> _ipCache = {};
  
  // Known IP addresses for fallback
  static final Map<String, String> knownIps = {
    'www.neusenews.com': '13.33.242.31',
    'www.neusenewssports.com': '54.236.39.101',
    'www.ncpoliticalnews.com': '54.236.39.101',
    'api.openweathermap.org': '99.86.13.12',
  };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final uri = request.url;
    
    // Try to resolve the hostname to an IP address
    String resolvedHost;
    try {
      // Check cache first
      if (_ipCache.containsKey(uri.host)) {
        resolvedHost = _ipCache[uri.host]!;
      } 
      // Check known IPs
      else if (knownIps.containsKey(uri.host)) {
        resolvedHost = knownIps[uri.host]!;
        _ipCache[uri.host] = resolvedHost;
      }
      // Try to resolve using DNS
      else {
        final addresses = await InternetAddress.lookup(uri.host)
            .timeout(const Duration(seconds: 3));
        if (addresses.isNotEmpty) {
          resolvedHost = addresses.first.address;
          _ipCache[uri.host] = resolvedHost; // Cache it
        } else {
          resolvedHost = uri.host; // Fallback to original
        }
      }
      
      // Create new URI with resolved IP
      final resolvedUri = uri.replace(host: resolvedHost);
      
      // Clone the request with the new URI
      final newRequest = http.Request(request.method, resolvedUri)
        ..headers.addAll(request.headers)
        ..headers['Host'] = uri.host; // Keep original hostname in Host header
      
      // Copy the body if it's a POST request
      if (request is http.Request) {
        newRequest.body = (request).body;
      }
      
      return _inner.send(newRequest);
    } catch (e) {
      debugPrint('DNS resolution error: $e');
      // Fallback to original request if resolution fails
      return _inner.send(request);
    }
  }
}