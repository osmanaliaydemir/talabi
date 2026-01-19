import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/services/secure_storage_service.dart';

class SignalRService {
  HubConnection? _hubConnection;
  final SecureStorageService _secureStorage = SecureStorageService.instance;

  // Streams suitable for UI to listen to
  final _orderAssignedController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onOrderAssigned =>
      _orderAssignedController.stream;

  bool get isConnected => _hubConnection?.state == HubConnectionState.connected;

  Future<void> init() async {
    final token = await _secureStorage.getToken();
    if (token == null) return;

    final hubUrl =
        '${AppConfig.apiBaseUrl.replaceAll('/api', '')}/hubs/notifications';

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          HttpConnectionOptions(
            accessTokenFactory: () async => token,
            logging: (level, message) => debugPrint('SignalR: $message'),
          ),
        )
        .withAutomaticReconnect()
        .build();

    _hubConnection!.onclose((error) {
      debugPrint('SignalR Connection Closed: $error');
    });

    _hubConnection!.onreconnecting((error) {
      debugPrint('SignalR Reconnecting: $error');
    });

    _hubConnection!.onreconnected((connectionId) {
      debugPrint('SignalR Reconnected: $connectionId');
      _registerHandlers(); // Re-register handlers if needed
    });

    _registerHandlers();
  }

  void _registerHandlers() {
    if (_hubConnection == null) return;

    // Listen for "NewOrderAssigned" event
    _hubConnection!.on('NewOrderAssigned', (arguments) {
      debugPrint('SignalR: NewOrderAssigned event received: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _orderAssignedController.add(data);
      }
    });

    // Listen for "ReceiveOrderAssignment" event (Method used in SignalRNotificationService)
    _hubConnection!.on('ReceiveOrderAssignment', (arguments) {
      debugPrint('SignalR: ReceiveOrderAssignment event received: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _orderAssignedController.add(data);
      }
    });

    // Listen for "OrderAssigned" event (Alternative name used in SignalRNotificationService)
    _hubConnection!.on('OrderAssigned', (arguments) {
      debugPrint('SignalR: OrderAssigned event received: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _orderAssignedController.add(data);
      }
    });
  }

  Future<void> startConnection() async {
    if (_hubConnection == null) {
      await init();
    }

    if (_hubConnection?.state == HubConnectionState.disconnected) {
      try {
        await _hubConnection!.start();
        debugPrint('SignalR Connected');
        await _joinCourierGroup();
      } catch (e) {
        debugPrint('SignalR Connection Error: $e');
      }
    }
  }

  Future<void> _joinCourierGroup() async {
    final userId = await _secureStorage.getUserId();
    if (userId != null &&
        _hubConnection?.state == HubConnectionState.connected) {
      // Ideally the server adds the user to the group based on the token logic,
      // but if there's a specific method to call like "JoinCourierGroup", call it here.
      // Based on NotificationHub.cs, there is a method JoinCourierGroup(string courierId)
      try {
        await _hubConnection!.invoke('JoinCourierGroup', args: [userId]);
        debugPrint('Joined Courier Group: $userId');
      } catch (e) {
        debugPrint('Error joining courier group: $e');
      }
    }
  }

  Future<void> stopConnection() async {
    if (_hubConnection?.state == HubConnectionState.connected) {
      await _hubConnection!.stop();
      debugPrint('SignalR Disconnected');
    }
  }
}
