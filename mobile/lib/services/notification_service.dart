import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';

class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get isFirebaseAvailable => _firebaseMessaging != null;

  // Callback for order assignment notifications
  void Function(int orderId)? onOrderAssigned;

  /// Initialize the notification service
  Future<void> init() async {
    await initialize();
  }

  /// Stop the notification service (cleanup)
  void stop() {
    onOrderAssigned = null;
    // Additional cleanup if needed
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Try to initialize Firebase Messaging
    try {
      _firebaseMessaging = FirebaseMessaging.instance;
    } catch (e, stackTrace) {
      LoggerService().warning(
        'Firebase Messaging not available',
        e,
        stackTrace,
      );
      _firebaseMessaging = null;
    }

    // 1. Request Permissions
    await _requestPermission();

    // 2. Initialize Local Notifications
    await _initLocalNotifications();

    // 3. Get FCM Token (only if Firebase is available)
    if (_firebaseMessaging != null) {
      try {
        final token = await _firebaseMessaging!.getToken();
        LoggerService().debug('🔥 FCM Token: $token');

        if (token != null) {
          try {
            final deviceType = Platform.isIOS ? 'iOS' : 'Android';
            await ApiService().registerDeviceToken(token, deviceType);
            LoggerService().info('✅ Device token registered with API');
          } catch (e, stackTrace) {
            LoggerService().error(
              '❌ Failed to register device token',
              e,
              stackTrace,
            );
          }
        }

        // 4. Handle Foreground Messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // 5. Handle Background Message Tap
        FirebaseMessaging.onMessageOpenedApp.listen(
          _handleBackgroundMessageTap,
        );

        // 6. Check if app was opened from a terminated state
        final initialMessage = await _firebaseMessaging!.getInitialMessage();
        if (initialMessage != null) {
          _handleBackgroundMessageTap(initialMessage);
        }
      } catch (e, stackTrace) {
        LoggerService().error(
          'Error initializing Firebase Messaging',
          e,
          stackTrace,
        );
      }
    } else {
      LoggerService().warning(
        '⚠️ Firebase Messaging not available - notifications disabled',
      );
    }

    _isInitialized = true;
  }

  Future<void> _requestPermission() async {
    if (_firebaseMessaging == null) return;

    if (Platform.isIOS) {
      await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle local notification tap
        LoggerService().debug(
          '🔔 Local Notification Tapped: ${details.payload}',
        );
      },
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    LoggerService().debug(
      '🔔 Foreground Message: ${message.notification?.title}',
    );
    LoggerService().debug('🔔 Message Data: ${message.data}');

    // Check if this is an order assignment notification
    if (message.data.containsKey('orderId') &&
        message.data.containsKey('type')) {
      final type = message.data['type'];
      if (type == 'order_assigned' || type == 'ORDER_ASSIGNED') {
        final orderId = int.tryParse(message.data['orderId'].toString());
        if (orderId != null && onOrderAssigned != null) {
          LoggerService().debug(
            '🔔 Triggering onOrderAssigned callback for order #$orderId',
          );
          onOrderAssigned!(orderId);
        }
      }
    }

    if (message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  void _handleBackgroundMessageTap(RemoteMessage message) {
    LoggerService().debug('🔔 Background Message Tapped: ${message.data}');
    // Navigate to specific screen based on data
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // id
            'High Importance Notifications', // title
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }
  }
}
