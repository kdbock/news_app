import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

enum ErrorType {
  network,
  server,
  timeout,
  auth,
  unknown,
}

enum ErrorSeverity {
  low,    // Non-critical, can be logged silently
  medium, // Important but not blocking, show snackbar
  high,   // Critical, show dialog
  critical,
}

class AppErrorHandler {
  // Log errors to analytics and console
  static void logError(Object error, {StackTrace? stackTrace, String? context}) {
    debugPrint('ERROR[$context]: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
    
    // Send to analytics in production
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: context);
    }
  }
  
  // Check network connectivity
  static Future<bool> hasNetworkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  // Get user-friendly error message
  static String getUserFriendlyErrorMessage(Object error, {ErrorType? errorType}) {
    final type = errorType ?? _determineErrorType(error);
    
    switch (type) {
      case ErrorType.network:
        return 'No internet connection. Please check your network settings and try again.';
      case ErrorType.timeout:
        return 'The connection timed out. Please try again.';
      case ErrorType.server:
        return 'We\'re having trouble connecting to our servers. Please try again later.';
      case ErrorType.auth:
        return 'Your session has expired. Please log in again.';
      case ErrorType.unknown:
        return 'An unexpected error occurred. Please try again later.';
    }
  }
  
  // Determine error type from error object
  static ErrorType _determineErrorType(Object error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('socketexception') || 
        errorString.contains('connection refused') ||
        errorString.contains('network is unreachable')) {
      return ErrorType.network;
    } else if (errorString.contains('timeout')) {
      return ErrorType.timeout;
    } else if (errorString.contains('unauthorized') || 
              errorString.contains('unauthenticated') || 
              errorString.contains('permission')) {
      return ErrorType.auth;
    } else if (errorString.contains('500') || 
              errorString.contains('server error') ||
              errorString.contains('bad gateway')) {
      return ErrorType.server;
    } else {
      return ErrorType.unknown;
    }
  }
  
  // Try an operation with automatic retry
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    
    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        if (attempts >= maxRetries) {
          rethrow;
        }
        
        // Check if it's worth retrying based on error type
        final errorType = _determineErrorType(e);
        if (errorType == ErrorType.auth) {
          // Auth errors should not be retried automatically
          rethrow;
        }
        
        // Wait before retrying with exponential backoff
        final delay = Duration(milliseconds: retryDelay.inMilliseconds * attempts);
        await Future.delayed(delay);
      }
    }
  }
}

class ErrorHandler {
  // Handle errors with appropriate UI feedback
  static void handleError(
    BuildContext context,
    String friendlyMessage,
    dynamic error, {
    ErrorSeverity severity = ErrorSeverity.medium,
    VoidCallback? retryAction,
  }) {
    // Log all errors
    debugPrint('ERROR: $friendlyMessage - $error');
    
    switch (severity) {
      case ErrorSeverity.low:
        // Just log
        break;
      
      case ErrorSeverity.medium:
        // Show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyMessage),
            action: retryAction != null ? SnackBarAction(
              label: 'RETRY',
              onPressed: retryAction,
            ) : null,
          ),
        );
        break;
      
      case ErrorSeverity.high:
        // Show dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(friendlyMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('DISMISS'),
              ),
              if (retryAction != null)
                ElevatedButton(
                  onPressed: retryAction,
                  child: const Text('RETRY'),
                ),
            ],
          ),
        );
        break;
      case ErrorSeverity.critical:
        // Show dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Critical Error'),
            content: Text(friendlyMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('DISMISS'),
              ),
              if (retryAction != null)
                ElevatedButton(
                  onPressed: retryAction,
                  child: const Text('RETRY'),
                ),
            ],
          ),
        );
        break;
    }
  }
  
  // Parse Firebase errors into user-friendly messages
  static String getFirebaseErrorMessage(dynamic error) {
    final errorMessage = error.toString().toLowerCase();
    
    if (errorMessage.contains('permission-denied')) {
      return 'You don\'t have permission to perform this action';
    } else if (errorMessage.contains('network-request-failed')) {
      return 'Please check your internet connection';
    } else if (errorMessage.contains('deadline-exceeded')) {
      return 'The operation timed out. Please try again';
    } else {
      return 'An unexpected error occurred. Please try again later';
    }
  }

  // Add this method for standardized ad error handling
  static void handleAdError(
    BuildContext context,
    String userMessage,
    dynamic error, {
    ErrorSeverity severity = ErrorSeverity.medium,
    Function? onRetry,
    String? errorCode,
    StackTrace? stackTrace,
  }) {
    // Log to console
    debugPrint('AD ERROR [$severity]: $userMessage - $error');
    
    // Log to crashlytics for medium+ severity
    if (severity != ErrorSeverity.low) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: userMessage,
        fatal: severity == ErrorSeverity.critical,
        information: [
          'Error Code: $errorCode',
          'Severity: $severity',
          'Area: Advertising',
        ],
      );
    }
    
    // Show user-friendly message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userMessage),
        backgroundColor: _getSeverityColor(severity),
        duration: _getSeverityDuration(severity),
        action: severity != ErrorSeverity.low
            ? SnackBarAction(
                label: 'Report',
                textColor: Colors.white,
                onPressed: () {
                  // Implement additional error reporting flow
                },
              )
            : null,
      ),
    );
  }
  
  static Color _getSeverityColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.grey.shade700;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red.shade900;
    }
  }
  
  static Duration _getSeverityDuration(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return const Duration(seconds: 3);
      case ErrorSeverity.medium:
        return const Duration(seconds: 5);
      case ErrorSeverity.high:
      case ErrorSeverity.critical:
        return const Duration(seconds: 8);
    }
  }
}

Future<void> handleError() async {
  try {
    // Your logic here
  } catch (e) {
    debugPrint('Error: $e');
  }
}

// Example usage (commented out):
/*
void exampleErrorHandling(BuildContext context) async {
  try {
    // await adService.approveAd(ad.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Advertisement approved successfully')),
    );
    // _loadPendingAds();
  } catch (e) {
    ErrorHandler.handleError(
      context,
      'Failed to approve advertisement',
      e,
      // retryAction: () => _approveAd(ad),
    );
  }
}
*/