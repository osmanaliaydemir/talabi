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

    String baseUrl = AppConfig.apiBaseUrl;
    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    }
    final hubUrl = '$baseUrl/hubs/notifications';

    // 403 Hatasını (Negotiate Block) aşmak için:
    // 1. skipNegotiation: true (Negotiate isteği atma)
    // 2. transport: HttpTransportType.webSockets (Doğrudan WS aç)
    // 3. Token'ı sadece URL'den gönder (accessTokenFactory'yi null yap, conflict olmasın)
    final hubUrlWithToken = '$hubUrl?access_token=$token';

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          hubUrlWithToken,
          HttpConnectionOptions(
            transport: HttpTransportType.webSockets,
            skipNegotiation: true,
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
        // Normalize field names (C# uses PascalCase, Dart uses camelCase)
        final normalizedData = <String, dynamic>{
          'orderId': data['OrderId'] ?? data['orderId'],
          'languageCode': data['LanguageCode'] ?? data['languageCode'],
        };
        _orderAssignedController.add(normalizedData);
      }
    });

    // Listen for "ReceiveOrderAssignment" event (Method used in SignalRNotificationService)
    _hubConnection!.on('ReceiveOrderAssignment', (arguments) {
      debugPrint('SignalR: ReceiveOrderAssignment event received: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        // Normalize field names (C# uses PascalCase, Dart uses camelCase)
        final normalizedData = <String, dynamic>{
          'orderId': data['OrderId'] ?? data['orderId'],
          'languageCode': data['LanguageCode'] ?? data['languageCode'],
        };
        _orderAssignedController.add(normalizedData);
      }
    });

    // Listen for "OrderAssigned" event (Alternative name used in SignalRNotificationService)
    _hubConnection!.on('OrderAssigned', (arguments) {
      debugPrint('SignalR: OrderAssigned event received: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        // Normalize field names (C# uses PascalCase, Dart uses camelCase)
        final normalizedData = <String, dynamic>{
          'orderId': data['OrderId'] ?? data['orderId'],
          'languageCode': data['LanguageCode'] ?? data['languageCode'],
        };
        _orderAssignedController.add(normalizedData);
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
      } catch (e) {
        debugPrint('SignalR Connection Error: $e');
      }
    }
  }

  /// Kurye ID'si ile gruba katılır (profil yüklendikten sonra çağrılmalı)
  Future<void> joinCourierGroupWithId(String courierId) async {
    if (courierId.isNotEmpty &&
        _hubConnection?.state == HubConnectionState.connected) {
      try {
        await _hubConnection!.invoke('JoinCourierGroup', args: [courierId]);
        debugPrint('Joined Courier Group with courierId: $courierId');
      } catch (e) {
        debugPrint('Error joining courier group with courierId: $e');
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
