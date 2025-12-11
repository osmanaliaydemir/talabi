import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mobile/services/connectivity_service.dart';
import 'package:mobile/services/logger_service.dart';

class ConnectivityProvider with ChangeNotifier {
  ConnectivityProvider(this._connectivityService) {
    _init();
  }

  final ConnectivityService _connectivityService;
  StreamSubscription<bool>? _subscription;
  bool _isOnline = true;
  DateTime? _lastOnlineTime;

  bool get isOnline => _isOnline;
  DateTime? get lastOnlineTime => _lastOnlineTime;

  Future<void> _init() async {
    // Listen to connectivity changes first
    _subscription = _connectivityService.connectivityStream.listen((isOnline) {
      if (_isOnline != isOnline) {
        _isOnline = isOnline;
        if (isOnline) {
          _lastOnlineTime = DateTime.now();
        }
        notifyListeners();
        LoggerService().debug(
          '📡 [CONNECTIVITY] Status changed: ${isOnline ? "ONLINE" : "OFFLINE"}',
        );
      }
    });

    // Initial check after setting up listener
    _isOnline = await _connectivityService.checkConnectivity();
    if (_isOnline) {
      _lastOnlineTime = DateTime.now();
    }
    notifyListeners();
    LoggerService().debug(
      '📡 [CONNECTIVITY] Initial status: ${_isOnline ? "ONLINE" : "OFFLINE"}',
    );
  }

  Future<void> checkConnectivity() async {
    _isOnline = await _connectivityService.checkConnectivity();
    if (_isOnline) {
      _lastOnlineTime = DateTime.now();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
