import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/services/navigation_service.dart';
import 'package:mobile/services/secure_storage_service.dart';

class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get isFirebaseAvailable => _firebaseMessaging != null;

  // Broadcast stream for order assignment notifications
  final _orderAssignedController = StreamController<int>.broadcast();
  Stream<int> get orderAssignedStream => _orderAssignedController.stream;

  // Callback for order assignment notifications (Deprecated - use stream)
  // void Function(int orderId)? onOrderAssigned;

  /// Initialize the notification service
  Future<void> init() async {
    await initialize();
  }

  /// Stop the notification service (cleanup)
  void stop() {
    // onOrderAssigned = null;
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
        if (Platform.isIOS) {
          String? apnsToken = await _firebaseMessaging!.getAPNSToken();
          int retry = 0;
          while (apnsToken == null && retry < 3) {
            await Future.delayed(const Duration(seconds: 1));
            apnsToken = await _firebaseMessaging!.getAPNSToken();
            retry++;
          }
          if (apnsToken == null) {
            LoggerService().warning(
              '⚠️ APNS Token not available (Running on Simulator?). Skipping FCM token request.',
            );
            return;
          }
        }

        try {
          // Add timeout to prevent app hang on startup if APNS is not ready
          final token = await _firebaseMessaging!.getToken().timeout(
            const Duration(seconds: 5),
          );

          if (token != null) {
            try {
              final deviceType = Platform.isIOS ? 'iOS' : 'Android';
              await ApiService().registerDeviceToken(token, deviceType);
            } catch (e, stackTrace) {
              LoggerService().error(
                '❌ Failed to register device token',
                e,
                stackTrace,
              );
              // Don't rethrow, just log and continue
            }
          }
        } catch (e) {
          // Catch generic errors like [firebase_messaging/unknown] which happen on Simulators
          LoggerService().warning(
            '⚠️ Failed to get FCM token (Simulator or Configuration issue): $e',
          );
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
        // Log as warning instead of error to avoid alarming user on startup
        // This is common on Simulators or if Push Capability is missing
        LoggerService().warning(
          'Warning: Firebase Messaging initialization failed (Notifications might be disabled). Error: $e',
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
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) async {
        // Handle local notification tap
        // Debug logları kaldırıldı - sadece warning ve error logları gösteriliyor

        if (details.payload != null) {
          try {
            final Map<String, dynamic> data = json.decode(details.payload!);
            await _handleDataTap(data);
          } catch (e) {
            LoggerService().error('Error handling local notification tap', e);
          }
        }
      },
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Debug logları kaldırıldı - sadece warning ve error logları gösteriliyor

    // Check if this is an order assignment notification
    if (message.data.containsKey('orderId') &&
        message.data.containsKey('type')) {
      final type = message.data['type'];
      if (type == 'order_assigned' || type == 'ORDER_ASSIGNED') {
        final orderId = int.tryParse(message.data['orderId'].toString());
        if (orderId != null) {
          // Add to stream instead of callback
          _orderAssignedController.add(orderId);
        }
      }
    }

    if (message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  Future<void> _handleBackgroundMessageTap(RemoteMessage message) async {
    // Debug logları kaldırıldı - sadece warning ve error logları gösteriliyor
    await _handleDataTap(message.data);
  }

  /// Handles tap on notification data (either from FCM or Local Notification)
  Future<void> _handleDataTap(Map<String, dynamic> data) async {
    if (data.containsKey('orderId')) {
      final orderId = data['orderId'].toString();

      final role = await SecureStorageService.instance.getRole();
      // Info logları kaldırıldı - sadece warning ve error logları gösteriliyor

      if (role == null) {
        LoggerService().warning('🔔 No role found, cannot deep link');
        return;
      }

      final normalizedRole = role.toLowerCase();

      if (normalizedRole == 'customer') {
        NavigationService.navigateTo(
          '/customer/order-detail',
          arguments: orderId,
        );
      } else if (normalizedRole == 'vendor') {
        NavigationService.navigateTo(
          '/vendor/order-detail',
          arguments: orderId,
        );
      } else if (normalizedRole == 'courier') {
        NavigationService.navigateTo(
          '/courier/order-detail',
          arguments: orderId,
        );
      } else {
        LoggerService().warning('🔔 Unknown role for deep linking: $role');
      }
    }
  }

  Future<void> showManualNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'order_updates_channel', // Changed ID to ensure fresh channel config
      'Order Updates',
      channelDescription: 'Notifications for new and updated orders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // presentBanner: true, // dependent on iOS version/settings
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond, // unique ID
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    // ... existing implementation reused or refactored
    final notification = message.notification;
    // ...
    if (notification != null) {
      await showManualNotification(
        title: notification.title ?? '',
        body: notification.body ?? '',
        payload: json.encode(message.data),
      );
    }
  }
}
