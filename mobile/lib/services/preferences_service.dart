import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton service for SharedPreferences to avoid multiple disk I/O operations
class PreferencesService {
  static SharedPreferences? _instance;
  static bool _isInitializing = false;
  static final List<Completer<SharedPreferences>> _waitingCompleters = [];

  /// Get the SharedPreferences instance (lazy initialization)
  static Future<SharedPreferences> get instance async {
    if (_instance != null) {
      return _instance!;
    }

    if (_isInitializing) {
      // If already initializing, wait for it to complete
      final completer = Completer<SharedPreferences>();
      _waitingCompleters.add(completer);
      return completer.future;
    }

    return await init();
  }

  /// Initialize SharedPreferences (should be called once at startup)
  static Future<SharedPreferences> init() async {
    if (_instance != null) {
      return _instance!;
    }

    if (_isInitializing) {
      // If already initializing, wait for it to complete
      final completer = Completer<SharedPreferences>();
      _waitingCompleters.add(completer);
      return completer.future;
    }

    _isInitializing = true;

    try {
      _instance = await SharedPreferences.getInstance();
      _isInitializing = false;

      // Complete all waiting futures
      for (final completer in _waitingCompleters) {
        completer.complete(_instance!);
      }
      _waitingCompleters.clear();

      return _instance!;
    } catch (e) {
      _isInitializing = false;
      // Complete all waiting futures with error
      for (final completer in _waitingCompleters) {
        completer.completeError(e);
      }
      _waitingCompleters.clear();
      rethrow;
    }
  }

  /// Check if SharedPreferences is initialized
  static bool get isInitialized => _instance != null;

  /// Get the cached instance (synchronous, returns null if not initialized)
  static SharedPreferences? get cachedInstance => _instance;
}
