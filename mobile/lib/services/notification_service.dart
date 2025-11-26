import 'dart:developer' as developer;
import 'package:signalr_core/signalr_core.dart';
import 'package:mobile/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  HubConnection? _hubConnection;
  Function(int orderId)? onOrderAssigned;
  bool _isConnecting = false;
  bool _isConnected = false;

  Future<void> init() async {
    if (_isConnecting || _isConnected) {
      developer.log(
        'NotificationService: Already connecting or connected',
        name: 'Courier',
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      developer.log(
        'NotificationService: No token found, skipping SignalR connection',
        name: 'Courier',
      );
      return;
    }

    // Build hub URL - ensure WSS for HTTPS
    // Constants.apiBaseUrl = 'https://talabi.runasp.net/api'
    // We need: 'wss://talabi.runasp.net/hubs/notifications'
    var baseUrl = Constants.apiBaseUrl;
    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4); // Remove '/api'
    }

    // Convert HTTP/HTTPS to WS/WSS
    if (baseUrl.startsWith('https://')) {
      baseUrl = baseUrl.replaceFirst('https://', 'wss://');
    } else if (baseUrl.startsWith('http://')) {
      baseUrl = baseUrl.replaceFirst('http://', 'ws://');
    }

    final hubUrl = '$baseUrl/hubs/notifications';

    developer.log(
      'NotificationService: Initializing SignalR connection',
      name: 'Courier',
    );
    developer.log('NotificationService: Hub URL: $hubUrl', name: 'Courier');

    _isConnecting = true;

    try {
      _hubConnection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            HttpConnectionOptions(
              accessTokenFactory: () async {
                developer.log(
                  'NotificationService: Getting access token',
                  name: 'Courier',
                );
                return token;
              },
              logging: (level, message) {
                developer.log('SignalR [$level]: $message', name: 'Courier');
              },
              skipNegotiation: false,
              transport: HttpTransportType.webSockets,
            ),
          )
          .withAutomaticReconnect()
          .build();

      // Connection state callbacks
      _hubConnection?.onclose((error) {
        _isConnected = false;
        _isConnecting = false;
        developer.log(
          'NotificationService: Connection closed${error != null ? " - Error: $error" : ""}',
          name: 'Courier',
        );
      });

      _hubConnection?.onreconnecting((error) {
        _isConnected = false;
        developer.log(
          'NotificationService: Reconnecting${error != null ? " - Error: $error" : ""}',
          name: 'Courier',
        );
      });

      _hubConnection?.onreconnected((connectionId) {
        _isConnected = true;
        _isConnecting = false;
        developer.log(
          'NotificationService: Reconnected - ConnectionId: $connectionId',
          name: 'Courier',
        );
      });

      // Register for order assignment notifications
      _hubConnection?.on('ReceiveOrderAssignment', (arguments) {
        developer.log(
          'NotificationService: ReceiveOrderAssignment received - Arguments: $arguments',
          name: 'Courier',
        );
        if (onOrderAssigned != null &&
            arguments != null &&
            arguments.isNotEmpty) {
          try {
            final orderId = arguments[0] is int
                ? arguments[0] as int
                : int.parse(arguments[0].toString());
            developer.log(
              'NotificationService: Calling onOrderAssigned with OrderId: $orderId',
              name: 'Courier',
            );
            onOrderAssigned!(orderId);
          } catch (e, stackTrace) {
            developer.log(
              'NotificationService: ERROR parsing order assignment - $e',
              name: 'Courier',
              error: e,
              stackTrace: stackTrace,
            );
          }
        }
      });

      // Also listen for NewOrderAssigned (from hub method)
      _hubConnection?.on('NewOrderAssigned', (arguments) {
        developer.log(
          'NotificationService: NewOrderAssigned received - Arguments: $arguments',
          name: 'Courier',
        );
        if (onOrderAssigned != null &&
            arguments != null &&
            arguments.isNotEmpty) {
          try {
            final data = arguments[0] as Map<String, dynamic>;
            final orderId = data['OrderId'] as int? ?? data['orderId'] as int?;
            if (orderId != null) {
              developer.log(
                'NotificationService: Calling onOrderAssigned with OrderId: $orderId',
                name: 'Courier',
              );
              onOrderAssigned!(orderId);
            }
          } catch (e, stackTrace) {
            developer.log(
              'NotificationService: ERROR parsing new order assignment - $e',
              name: 'Courier',
              error: e,
              stackTrace: stackTrace,
            );
          }
        }
      });

      developer.log(
        'NotificationService: Starting connection...',
        name: 'Courier',
      );
      await _hubConnection?.start();
      _isConnected = true;
      _isConnecting = false;
      developer.log(
        'NotificationService: SignalR Connected successfully - ConnectionId: ${_hubConnection?.connectionId}',
        name: 'Courier',
      );
    } catch (e, stackTrace) {
      _isConnecting = false;
      _isConnected = false;
      developer.log(
        'NotificationService: ERROR connecting to SignalR - $e',
        name: 'Courier',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - allow app to continue without SignalR
    }
  }

  Future<void> stop() async {
    if (_hubConnection != null) {
      developer.log(
        'NotificationService: Stopping SignalR connection',
        name: 'Courier',
      );
      try {
        await _hubConnection?.stop();
        _isConnected = false;
        _isConnecting = false;
        developer.log(
          'NotificationService: SignalR connection stopped',
          name: 'Courier',
        );
      } catch (e, stackTrace) {
        developer.log(
          'NotificationService: ERROR stopping SignalR - $e',
          name: 'Courier',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  bool get isConnected => _isConnected;
}
