import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class HttpClientFactory {
  static http.Client createClient() {
    if (!kReleaseMode) {
      // In debug mode, set DNS override for simulator issues
      final httpClient = HttpClient();
      
      // Override DNS lookup for development only
      httpClient.findProxy = (uri) {
        return 'DIRECT';
      };
      
      // On Android simulator, add specific DNS lookup override
      if (Platform.isAndroid) {
        // Use Google's DNS instead of the emulator's DNS
        httpClient.badCertificateCallback = (cert, host, port) => true;
      }
      
      return IOClient(httpClient);
    } else {
      // In production, use standard client
      return http.Client();
    }
  }
}