import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:connectivity_plus/connectivity_plus.dart';

class ImageOptimizationService {
  // Singleton pattern
  static final ImageOptimizationService _instance = ImageOptimizationService._internal();
  factory ImageOptimizationService() => _instance;
  ImageOptimizationService._internal();

  // Custom cache manager with longer duration
  static const String key = 'optimizedImageCache';
  static final CacheManager _cacheManager = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
  
  // Directory for storing processed images
  Directory? _cacheDirectory;
  
  // Image size settings based on network quality
  final Map<NetworkQuality, int> _maxWidthByNetworkQuality = {
    NetworkQuality.poor: 320,    // Very low quality
    NetworkQuality.fair: 480,    // Low quality
    NetworkQuality.good: 720,    // Medium quality
    NetworkQuality.excellent: 1080, // High quality
  };
  
  // Initialize the service
  Future<void> initialize() async {
    try {
      _cacheDirectory = await getTemporaryDirectory();
    } catch (e) {
      debugPrint('Error initializing image optimization service: $e');
    }
  }
  
  // Get optimized image URL (either local cache or with resize parameters)
  Future<String> getOptimizedImageUrl(String originalUrl, {int? maxWidth}) async {
    if (originalUrl.isEmpty) return originalUrl;
    
    try {
      // Check network quality to determine appropriate image size
      final networkQuality = await _checkNetworkQuality();
      final targetWidth = maxWidth ?? _maxWidthByNetworkQuality[networkQuality] ?? 720;
      
      // Try to get from cache first
      final String cacheKey = '${originalUrl}_w$targetWidth';
      final cachedFile = await _cacheManager.getFileFromCache(cacheKey);
      
      if (cachedFile != null) {
        debugPrint('Using cached optimized image: ${cachedFile.file.path}');
        return cachedFile.file.path;
      }
      
      // Check if the URL already has an image optimization service
      if (_isImageServiceUrl(originalUrl)) {
        // Generate optimized URL directly
        return _generateOptimizedUrl(originalUrl, targetWidth);
      }
      
      // For regular URLs, download & optimize locally
      final File? optimizedFile = await _downloadAndOptimize(
        originalUrl,
        targetWidth,
        cacheKey,
      );
      
      if (optimizedFile != null) {
        return optimizedFile.path;
      }
    } catch (e) {
      debugPrint('Error optimizing image: $e');
    }
    
    // Fall back to original URL if optimization fails
    return originalUrl;
  }
  
  // Check if URL is from an image optimization service
  bool _isImageServiceUrl(String url) {
    final optimizationServices = [
      'imgix.net',
      'cloudinary.com',
      'res.cloudinary.com',
      'imagekit.io',
      'images.weserv.nl',
      'i.imgur.com',
    ];
    
    return optimizationServices.any((service) => url.contains(service));
  }
  
  // Generate optimized URL for known image services
  String _generateOptimizedUrl(String originalUrl, int targetWidth) {
    if (originalUrl.contains('cloudinary.com') || 
        originalUrl.contains('res.cloudinary.com')) {
      // Cloudinary transformation
      final uri = Uri.parse(originalUrl);
      final pathSegments = List<String>.from(uri.pathSegments);
      
      // Insert transformation
      if (!pathSegments.contains('upload')) {
        return originalUrl;
      }
      
      final uploadIndex = pathSegments.indexOf('upload');
      pathSegments.insert(uploadIndex + 1, 'w_$targetWidth,q_auto:good');
      
      return uri.replace(pathSegments: pathSegments).toString();
    } 
    else if (originalUrl.contains('images.weserv.nl')) {
      // Images.weserv.nl
      final uri = Uri.parse(originalUrl);
      final queryParams = Map<String, String>.from(uri.queryParameters);
      
      queryParams['w'] = targetWidth.toString();
      if (!queryParams.containsKey('q')) {
        queryParams['q'] = '85';
      }
      
      return uri.replace(queryParameters: queryParams).toString();
    }
    else if (originalUrl.contains('i.imgur.com')) {
      // Imgur
      final suffix = originalUrl.split('.').last;
      if (targetWidth <= 320) {
        return originalUrl.replaceAll('.$suffix', 's.$suffix'); // Small thumbnail
      } else if (targetWidth <= 640) {
        return originalUrl.replaceAll('.$suffix', 'm.$suffix'); // Medium thumbnail
      } else if (targetWidth <= 1024) {
        return originalUrl.replaceAll('.$suffix', 'l.$suffix'); // Large thumbnail
      }
    }
    
    // Default: pass through original URL
    return originalUrl;
  }
  
  // Download and optimize an image locally
  Future<File?> _downloadAndOptimize(
    String url,
    int targetWidth,
    String cacheKey,
  ) async {
    try {
      // Download the image
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return null;
      }
      
      // Create a temporary file
      final tempFilePath = path.join(
        _cacheDirectory!.path,
        'temp_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(response.bodyBytes);
      
      // Process the image (resize & compress)
      final processedFile = await _processImage(tempFile, targetWidth);
      if (processedFile == null) {
        await tempFile.delete();
        return null;
      }
      
      // Save to cache
      await _cacheManager.putFile(
        url,
        processedFile.readAsBytesSync(),
        key: cacheKey,
      );
      
      // Clean up temporary file
      await tempFile.delete();
      
      // Return the cached file
      final cachedFile = await _cacheManager.getFileFromCache(cacheKey);
      return cachedFile?.file;
    } catch (e) {
      debugPrint('Error downloading and optimizing image: $e');
      return null;
    }
  }
  
  // Process an image (resize & compress)
  Future<File?> _processImage(File inputFile, int targetWidth) async {
    try {
      // Read image
      final bytes = await inputFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;
      
      // Skip processing if image is already smaller than target width
      if (image.width <= targetWidth) {
        return inputFile;
      }
      
      // Calculate target height to maintain aspect ratio
      final targetHeight = (image.height * targetWidth / image.width).round();
      
      // Resize image
      final resized = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.average,
      );
      
      // Encode as JPEG with quality based on network conditions
      final networkQuality = await _checkNetworkQuality();
      final jpegQuality = _getJpegQualityForNetwork(networkQuality);
      final processedBytes = img.encodeJpg(resized, quality: jpegQuality);
      
      // Save to a new file
      final outputPath = path.join(
        _cacheDirectory!.path,
        'opt_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(processedBytes);
      
      return outputFile;
    } catch (e) {
      debugPrint('Error processing image: $e');
      return null;
    }
  }
  
  // Check network quality
  Future<NetworkQuality> _checkNetworkQuality() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      // No connection
      if (connectivityResult == ConnectivityResult.none) {
        return NetworkQuality.poor;
      }
      
      // Cellular connection - be more conservative with data
      if (connectivityResult == ConnectivityResult.mobile) {
        return NetworkQuality.fair;
      }
      
      // WiFi or ethernet - assume good connection
      return NetworkQuality.excellent;
    } catch (e) {
      // Default to good quality if we can't check
      return NetworkQuality.good;
    }
  }
  
  // Get appropriate JPEG quality based on network
  int _getJpegQualityForNetwork(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.poor:
        return 60; // Lower quality for poor networks
      case NetworkQuality.fair:
        return 75;
      case NetworkQuality.good:
        return 85;
      case NetworkQuality.excellent:
        return 92;
    }
  }
  
  // Clear the cache
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }
}

// Network quality enum
enum NetworkQuality {
  poor,
  fair,
  good,
  excellent
}