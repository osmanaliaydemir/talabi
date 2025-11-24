import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    // Initial check
    await checkConnectivity();

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      // When connectivity changes, check again
      checkConnectivity();
    });
  }

  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasConnection = !results.contains(ConnectivityResult.none);

      // Update state only if it changed
      if (hasConnection != _isOnline) {
        _isOnline = hasConnection;
        _connectivityController.add(_isOnline);
        print(
          '📡 [CONNECTIVITY] Device status: ${_isOnline ? "ONLINE" : "OFFLINE"}',
        );
      }

      return _isOnline;
    } catch (e) {
      print('Error checking connectivity: $e');
      // On error, assume we're online (better UX)
      if (!_isOnline) {
        _isOnline = true;
        _connectivityController.add(true);
      }
      return true;
    }
  }

  void dispose() {
    _connectivityController.close();
  }
}
