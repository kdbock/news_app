import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

class ImageValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ImageValidationResult({required this.isValid, this.errorMessage});
}

class ImageValidationException implements Exception {
  final String message;
  
  ImageValidationException(this.message);
  
  @override
  String toString() => message;
}

class ImageValidator {
  static Future<ImageValidationResult> validateImage(
    File imageFile, {
    required String aspectRatioType,
    int maxSizeKB = 5120, // 5MB
    int minWidth = 200,
    int minHeight = 200,
    int maxWidth = 2000,
    int maxHeight = 2000,
    double? aspectRatio,
    double aspectRatioTolerance = 0.1,
  }) async {
    try {
      // Check file size
      final int fileSizeKB = await imageFile.length() ~/ 1024;
      if (fileSizeKB > maxSizeKB) {
        return ImageValidationResult(
          isValid: false,
          errorMessage:
              'Image size exceeds ${maxSizeKB ~/ 1024} MB. Please choose a smaller image.',
        );
      }

      // Set aspect ratio based on type if not explicitly provided
      aspectRatio ??= _getAspectRatioFromType(aspectRatioType);

      // Decode image to get dimensions
      final bytes = await imageFile.readAsBytes();
      final completer = Completer<ImageValidationResult>();

      // Fix the decodeImageFromList call by using it properly
      ui.decodeImageFromList(bytes, (ui.Image image) {
        final width = image.width;
        final height = image.height;
        
        // Check dimensions
        if (width < minWidth || height < minHeight) {
          completer.complete(ImageValidationResult(
            isValid: false,
            errorMessage: 'Image dimensions too small. Minimum size: ${minWidth}x$minHeight px',
          ));
          return;
        }
        
        if (width > maxWidth || height > maxHeight) {
          completer.complete(ImageValidationResult(
            isValid: false,
            errorMessage: 'Image dimensions too large. Maximum size: ${maxWidth}x$maxHeight px',
          ));
          return;
        }
        
        // Check aspect ratio if specified
        if (aspectRatio != null) {
          final actualRatio = width / height;
          if ((actualRatio - aspectRatio).abs() > aspectRatioTolerance) {
            completer.complete(ImageValidationResult(
              isValid: false,
              errorMessage: 'Image aspect ratio should be approximately $aspectRatio',
            ));
            return;
          }
        }
        
        // All checks passed
        completer.complete(ImageValidationResult(
          isValid: true,
        ));
      });

      return completer.future;
    } catch (e) {
      return ImageValidationResult(
        isValid: false,
        errorMessage: 'Error validating image: $e',
      );
    }
  }
  
  // Helper method to determine aspect ratio based on type
  static double? _getAspectRatioFromType(String aspectRatioType) {
    switch (aspectRatioType.toLowerCase()) {
      case 'square':
        return 1.0;
      case 'landscape':
        return 16/9;
      case 'portrait':
        return 3/4;
      case 'banner':
        return 2.5;
      case 'free':
      default:
        return null;
    }
  }
  
  // Helper method for ad dimensions
  static Map<String, int> getDimensionsForAdType(String adType) {
    switch (adType.toLowerCase()) {
      case 'title_sponsor':
        return {
          'minWidth': 600,
          'minHeight': 300,
          'maxWidth': 1200,
          'maxHeight': 600,
        };
      case 'banner_ad':
        return {
          'minWidth': 728,
          'minHeight': 90,
          'maxWidth': 1456,
          'maxHeight': 180,
        };
      case 'in_feed':
        return {
          'minWidth': 300,
          'minHeight': 300,
          'maxWidth': 1000,
          'maxHeight': 1000,
        };
      default:
        return {
          'minWidth': 200,
          'minHeight': 200,
          'maxWidth': 2000,
          'maxHeight': 2000,
        };
    }
  }
}
