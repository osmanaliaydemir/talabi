import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile/services/api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

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

    // 1. Request Permissions
    await _requestPermission();

    // 2. Initialize Local Notifications
    await _initLocalNotifications();

    // 3. Get FCM Token
    final token = await _firebaseMessaging.getToken();
    print('🔥 FCM Token: $token');

    if (token != null) {
      try {
        final deviceType = Platform.isIOS ? 'iOS' : 'Android';
        await ApiService().registerDeviceToken(token, deviceType);
        print('✅ Device token registered with API');
      } catch (e) {
        print('❌ Failed to register device token: $e');
      }
    }

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Handle Background Message Tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // 6. Check if app was opened from a terminated state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessageTap(initialMessage);
    }

    _isInitialized = true;
  }

  Future<void> _requestPermission() async {
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
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
        print('🔔 Local Notification Tapped: ${details.payload}');
      },
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🔔 Foreground Message: ${message.notification?.title}');
    print('🔔 Message Data: ${message.data}');

    // Check if this is an order assignment notification
    if (message.data.containsKey('orderId') &&
        message.data.containsKey('type')) {
      final type = message.data['type'];
      if (type == 'order_assigned' || type == 'ORDER_ASSIGNED') {
        final orderId = int.tryParse(message.data['orderId'].toString());
        if (orderId != null && onOrderAssigned != null) {
          print('🔔 Triggering onOrderAssigned callback for order #$orderId');
          onOrderAssigned!(orderId);
        }
      }
    }

    if (message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  void _handleBackgroundMessageTap(RemoteMessage message) {
    print('🔔 Background Message Tapped: ${message.data}');
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
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // id
            'High Importance Notifications', // title
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }
  }
}
