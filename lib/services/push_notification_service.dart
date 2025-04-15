import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:neusenews/navigation/navigation_service.dart';
import 'package:neusenews/navigation/routes.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class PushNotificationService {
  static const String notificationsEnabledKey = 'push_notifications_enabled';
  static const String breakingNewsEnabledKey = 'breaking_news_enabled';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Local notifications plugin
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Track permission status
  bool _hasPermission = false;

  // Initialize notifications
  Future<void> initialize() async {
    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      _hasPermission =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!_hasPermission) {
        developer.log('User declined notification permissions');
        return;
      }

      // Initialize local notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          _handleNotificationTap(details.payload);
        },
      );

      // Configure FCM handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);

      // Update token
      _updateUserToken();

      // Subscribe to default topics
      _subscribeToDefaultTopics();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      // Check and subscribe to breaking news
      _setupBreakingNewsSubscription();

      developer.log('Push notification service initialized successfully');
    } catch (e) {
      developer.log('Error initializing push notifications: $e');
    }

    // Add a retry mechanism for token retrieval
    int retryCount = 0;
    String? token;
    while (token == null && retryCount < 3) {
      try {
        token = await _messaging.getToken();
        if (token != null) {
          // Add this null check
          _saveTokenToPrefs(token);
          _saveTokenToFirestore(token);
        }
      } catch (e) {
        retryCount++;
        debugPrint('FCM token retrieval attempt $retryCount failed: $e');
        await Future.delayed(Duration(seconds: 5 * retryCount));
      }
    }
  }

  // Subscribe to breaking news specifically
  Future<void> _setupBreakingNewsSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final breakingNewsEnabled = prefs.getBool(breakingNewsEnabledKey) ?? true;

      if (breakingNewsEnabled) {
        await _messaging.subscribeToTopic('breaking_news');
        developer.log('Subscribed to breaking news topic');
      } else {
        await _messaging.unsubscribeFromTopic('breaking_news');
        developer.log('Unsubscribed from breaking news topic');
      }
    } catch (e) {
      developer.log('Error setting up breaking news subscription: $e');
    }
  }

  // Toggle breaking news subscription
  Future<void> toggleBreakingNews(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(breakingNewsEnabledKey, enabled);

      if (enabled) {
        await _messaging.subscribeToTopic('breaking_news');
        developer.log('Subscribed to breaking news');
      } else {
        await _messaging.unsubscribeFromTopic('breaking_news');
        developer.log('Unsubscribed from breaking news');
      }
    } catch (e) {
      developer.log('Error toggling breaking news: $e');
    }
  }

  // Handle foreground message with special handling for breaking news
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      developer.log('Received foreground message: ${message.messageId}');

      final notification = message.notification;
      final data = message.data;

      // Special handling for breaking news
      final bool isBreakingNews = data['type'] == 'breaking_news';

      if (notification != null) {
        // Show breaking news differently
        if (isBreakingNews) {
          _showBreakingNewsNotification(
            title: notification.title ?? 'Breaking News',
            body: notification.body ?? '',
            data: data,
          );
        } else {
          _showInAppNotification(
            title: notification.title ?? 'Neuse News',
            body: notification.body ?? '',
            data: data,
          );
        }
      }
    } catch (e) {
      developer.log('Error handling foreground message: $e');
    }
  }

  // Special notification for breaking news
  void _showBreakingNewsNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Show a high priority notification for breaking news
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'breaking_news_channel',
            'Breaking News',
            channelDescription: 'Urgent breaking news notifications',
            importance: Importance.high,
            priority: Priority.high,
            color: Color(0xFFd2982a),
            ledColor: Color(0xFFd2982a),
            ledOnMs: 500,
            ledOffMs: 500,
            enableLights: true,
            enableVibration: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'breaking_news_sound.wav', // Custom sound file in iOS app
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecond,
        '🔴 $title',
        body,
        notificationDetails,
        payload: jsonEncode(data),
      );

      // Also show in-app alert if app is open
      if (NavigationService.navigatorKey.currentContext != null) {
        _showBreakingNewsInAppAlert(title, body, data);
      }
    } catch (e) {
      developer.log('Error showing breaking news notification: $e');
    }
  }

  // Special in-app alert for breaking news
  void _showBreakingNewsInAppAlert(
    String title,
    String body,
    Map<String, dynamic> data,
  ) {
    if (NavigationService.navigatorKey.currentContext == null) return;

    final context = NavigationService.navigatorKey.currentContext!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'BREAKING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(title)),
              ],
            ),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('DISMISS'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _navigateBasedOnNotification(data);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd2982a),
                  foregroundColor: Colors.white,
                ),
                child: const Text('VIEW DETAILS'),
              ),
            ],
          ),
    );
  }

  // Add the missing method
  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(notificationsEnabledKey, enabled);

      if (enabled) {
        // Re-request permissions if needed
        final settings = await _messaging.getNotificationSettings();
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          await _messaging.requestPermission();
        }
      }

      // Update user preferences in Firestore
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'notificationPreferences.enabled': enabled,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      developer.log('Notifications ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      developer.log('Error setting notification preference: $e');
    }
  }

  // Handle when user taps on notification to open app

  // Handle notification tap from local notification
  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      final data = {'route': payload};
      _navigateBasedOnNotification(data);
    }
  }

  // Show in-app notification
  void _showInAppNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    if (NavigationService.navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(
        NavigationService.navigatorKey.currentContext!,
      ).showSnackBar(
        SnackBar(
          content: Text('$title: $body'),
          action: SnackBarAction(
            label: 'VIEW',
            onPressed: () => _navigateBasedOnNotification(data),
          ),
        ),
      );
    }
  }

  // Navigate based on notification data
  void _navigateBasedOnNotification(Map<String, dynamic> data) {
    try {
      // Extract routing information from notification data
      final String? route = data['route'] as String?;
      final String? id = data['id'] as String?;

      if (route == null) return;

      // Navigate based on the route type
      switch (route) {
        case 'article':
          if (id != null) {
            NavigationService.navigateTo(Routes.article, arguments: {'id': id});
          }
          break;
        case 'weather':
          NavigationService.navigateTo(Routes.weather);
          break;
        case 'event':
          if (id != null) {
            NavigationService.navigateTo(
              Routes.calendar,
              arguments: {'eventId': id},
            );
          } else {
            NavigationService.navigateTo(Routes.calendar);
          }
          break;
        default:
          NavigationService.navigateTo(Routes.dashboard);
      }
    } catch (e) {
      debugPrint('Error navigating from notification: $e');
    }
  }

  // Update FCM token for current user
  Future<void> _updateUserToken() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get the token
      String? token = await _messaging.getToken();

      // Store it in Firestore
      await _firestore.collection('users').doc(currentUser.uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      developer.log('Error updating FCM token: $e');
    }
  }

  // Subscribe to topics
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  // Unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  // Update notification preferences
  Future<void> updateNotificationPreferences({
    required bool breakingNews,
    required bool dailyDigest,
    required bool sportScores,
    required bool weatherAlerts,
    required bool localNewsAlerts,
  }) async {
    try {
      // Update topic subscriptions
      if (breakingNews) {
        await subscribeToTopic('breaking_news');
      } else {
        await unsubscribeFromTopic('breaking_news');
      }

      if (dailyDigest) {
        await subscribeToTopic('daily_digest');
      } else {
        await unsubscribeFromTopic('daily_digest');
      }

      if (sportScores) {
        await subscribeToTopic('sports_scores');
      } else {
        await unsubscribeFromTopic('sports_scores');
      }

      if (weatherAlerts) {
        await subscribeToTopic('weather_alerts');
      } else {
        await unsubscribeFromTopic('weather_alerts');
      }

      if (localNewsAlerts) {
        await subscribeToTopic('local_news');
      } else {
        await unsubscribeFromTopic('local_news');
      }

      // Save preferences to user document
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'notificationPreferences': {
            'breakingNews': breakingNews,
            'dailyDigest': dailyDigest,
            'sportScores': sportScores,
            'weatherAlerts': weatherAlerts,
            'localNewsAlerts': localNewsAlerts,
          },
        });
      }
    } catch (e) {
      print('Error updating notification preferences: $e');
    }
  }

  void _subscribeToDefaultTopics() {
    _messaging.subscribeToTopic('general');
    developer.log('Subscribed to default topics');
  }

  // Handle token refresh
  void _onTokenRefresh(String token) {
    debugPrint('FCM token refreshed');
    // Save the new token
    _saveTokenToPrefs(token);
    _saveTokenToFirestore(token);
  }

  void _handleNotificationOpened(RemoteMessage message) {
    developer.log('Notification opened: ${message.messageId}');
    _navigateBasedOnNotification(message.data);
  }

  Future<void> _saveTokenToFirestore(String token) async {
    if (_auth.currentUser != null) {
      try {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update(
          {
            'fcmTokens': FieldValue.arrayUnion([token]),
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          },
        );
      } catch (e) {
        debugPrint('Error saving FCM token to Firestore: $e');
      }
    }
  }

  void _saveTokenToPrefs(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  // Add to your PushNotificationService class
}

// This must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages here
  print('Handling a background message: ${message.messageId}');
}
