import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/connectivity_service.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Log seviyeleri
enum LogLevel { debug, info, warning, error, fatal }

/// Log kaydı modeli
class LogEntry {
  LogEntry({
    required this.id,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    required this.timestamp,
    this.metadata,
    this.userId,
    this.deviceInfo,
    this.appVersion,
  });

  final String id;
  final LogLevel level;
  final String message;
  final String? error;
  final String? stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String? userId;
  final String? deviceInfo;
  final String? appVersion;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level.name,
      'message': message,
      'error': error,
      'stackTrace': stackTrace,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'userId': userId,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
    };
  }
}

class LoggerService {
  LoggerService._internal();

  factory LoggerService() => _instance;
  static final LoggerService _instance = LoggerService._internal();

  Logger? _logger;
  final List<LogEntry> _errorQueue = [];
  ConnectivityService? _connectivityService;
  AuthProvider? _authProvider;

  bool _isInitialized = false;
  bool _isSending = false;
  Timer? _batchTimer;

  // Hive box for offline storage
  static const String _logBoxName = 'error_logs';
  Box<Map>? _logBox;

  // Device info cache
  String? _deviceInfo;
  String? _appVersion;

  /// Logger servisini başlat
  Future<void> init({
    ConnectivityService? connectivityService,
    AuthProvider? authProvider,
  }) async {
    if (_isInitialized) return;

    _connectivityService = connectivityService;
    _authProvider = authProvider;

    // Logger'ı başlat (sadece henüz initialize edilmemişse)
    _logger ??= Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: kDebugMode ? Level.debug : Level.warning,
    );

    // Hive box'ı aç (offline storage için)
    try {
      _logBox = await Hive.openBox<Map>(_logBoxName);
      // Offline'da kalan logları yükle
      await _loadOfflineLogs();
    } catch (e) {
      if (kDebugMode) {
        _loggerInstance.w('Failed to open log box: $e');
      }
    }

    // Device bilgilerini al
    await _loadDeviceInfo();

    _isInitialized = true;

    // Periyodik olarak queue'daki logları gönder
    _startBatchTimer();
  }

  /// Device bilgilerini yükle
  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        _deviceInfo =
            'Android ${androidInfo.version.release} (${androidInfo.model})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        _deviceInfo = 'iOS ${iosInfo.systemVersion} (${iosInfo.model})';
      } else {
        _deviceInfo = 'Unknown';
      }
    } catch (e) {
      _deviceInfo = 'Unknown';
      _appVersion = 'Unknown';
    }
  }

  /// Offline'da kalan logları yükle
  Future<void> _loadOfflineLogs() async {
    if (_logBox == null) return;

    try {
      final offlineLogs = _logBox!.values.toList();
      if (offlineLogs.isNotEmpty) {
        _loggerInstance.i('📦 Loading ${offlineLogs.length} offline logs');
        for (final logMap in offlineLogs) {
          final logEntry = _mapToLogEntry(logMap);
          if (logEntry != null) {
            _errorQueue.add(logEntry);
          }
        }
        // Queue'daki logları göndermeyi dene
        await _sendQueuedLogs();
      }
    } catch (e) {
      _loggerInstance.w('Failed to load offline logs: $e');
    }
  }

  /// Map'ten LogEntry'ye dönüştür
  LogEntry? _mapToLogEntry(Map map) {
    try {
      return LogEntry(
        id: map['id'] as String,
        level: LogLevel.values.firstWhere(
          (e) => e.name == map['level'],
          orElse: () => LogLevel.error,
        ),
        message: map['message'] as String,
        error: map['error'] as String?,
        stackTrace: map['stackTrace'] as String?,
        timestamp: DateTime.parse(map['timestamp'] as String),
        metadata: map['metadata'] as Map<String, dynamic>?,
        userId: map['userId'] as String?,
        deviceInfo: map['deviceInfo'] as String?,
        appVersion: map['appVersion'] as String?,
      );
    } catch (e) {
      return null;
    }
  }

  /// Batch timer başlat (her 30 saniyede bir gönder)
  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendQueuedLogs();
    });
  }

  /// Logger instance'ı al (lazy initialization)
  Logger get _loggerInstance {
    _logger ??= Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: kDebugMode ? Level.debug : Level.warning,
    );
    return _logger!;
  }

  /// Debug log
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _loggerInstance.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Info log
  void info(String message) {
    _loggerInstance.i(message);
  }

  /// Warning log
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _loggerInstance.w(message, error: error, stackTrace: stackTrace);

    // Warning'leri de kaydet (opsiyonel)
    if (kDebugMode) {
      _addToQueue(LogLevel.warning, message, error, stackTrace);
    }
  }

  /// Error log - API'ye gönder
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _loggerInstance.e(message, error: error, stackTrace: stackTrace);
    _addToQueue(LogLevel.error, message, error, stackTrace);
  }

  /// Fatal log - API'ye gönder (yüksek öncelik)
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _loggerInstance.f(message, error: error, stackTrace: stackTrace);
    _addToQueue(LogLevel.fatal, message, error, stackTrace);

    // Fatal hataları hemen gönder
    _sendQueuedLogs(immediate: true);
  }

  /// Queue'ya ekle
  void _addToQueue(
    LogLevel level,
    String message,
    dynamic error,
    StackTrace? stackTrace, [
    Map<String, dynamic>? metadata,
  ]) {
    // Sadece error ve fatal seviyesindeki logları kaydet
    if (level != LogLevel.error && level != LogLevel.fatal) {
      return;
    }

    final logEntry = LogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      level: level,
      message: message,
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
      timestamp: DateTime.now(),
      metadata: metadata,
      userId: _authProvider?.userId,
      deviceInfo: _deviceInfo,
      appVersion: _appVersion,
    );

    _errorQueue.add(logEntry);

    // Offline storage'a kaydet
    _saveToOfflineStorage(logEntry);

    // Queue çok büyükse eski kayıtları temizle (max 100)
    if (_errorQueue.length > 100) {
      final removed = _errorQueue.removeAt(0);
      _removeFromOfflineStorage(removed.id);
    }

    // Batch gönderim için timer başlat (eğer başlatılmadıysa)
    if (_batchTimer == null || !_batchTimer!.isActive) {
      _startBatchTimer();
    }
  }

  /// Offline storage'a kaydet
  void _saveToOfflineStorage(LogEntry logEntry) {
    if (_logBox == null) return;

    try {
      _logBox!.put(logEntry.id, logEntry.toJson());
    } catch (e) {
      if (kDebugMode) {
        _loggerInstance.w('Failed to save log to offline storage: $e');
      }
    }
  }

  /// Offline storage'dan sil
  void _removeFromOfflineStorage(String id) {
    if (_logBox == null) return;

    try {
      _logBox!.delete(id);
    } catch (e) {
      // Ignore
    }
  }

  /// Queue'daki logları API'ye gönder
  Future<void> _sendQueuedLogs({bool immediate = false}) async {
    // Zaten gönderim yapılıyorsa bekle
    if (_isSending && !immediate) return;

    // Queue boşsa çık
    if (_errorQueue.isEmpty) return;

    // Offline ise bekle (fatal hariç)
    if (_connectivityService != null &&
        !_connectivityService!.isOnline &&
        !immediate) {
      return;
    }

    _isSending = true;

    try {
      // Batch gönderim (max 10 log)
      final logsToSend = _errorQueue.take(10).toList();

      if (logsToSend.isEmpty) {
        _isSending = false;
        return;
      }

      // API'ye gönder
      final success = await _sendLogsToApi(logsToSend);

      if (success) {
        // Başarılı gönderim - queue'dan ve offline storage'dan sil
        for (final log in logsToSend) {
          _errorQueue.remove(log);
          _removeFromOfflineStorage(log.id);
        }
      } else {
        // Başarısız - tekrar denemek için queue'da bırak
        if (kDebugMode) {
          _loggerInstance.w('Failed to send logs, will retry later');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        _loggerInstance.e('Error sending logs: $e');
      }
    } finally {
      _isSending = false;
    }
  }

  /// Logları API'ye gönder
  Future<bool> _sendLogsToApi(List<LogEntry> logs) async {
    try {
      // API endpoint: POST /api/logs/errors
      final response = await ApiService().dio.post(
        '/logs/errors',
        data: {'logs': logs.map((log) => log.toJson()).toList()},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      // API hatası - log gönderiminde hata olmamalı
      if (kDebugMode) {
        _loggerInstance.w('API log send failed: $e');
      }
      return false;
    }
  }

  /// Servisi kapat (cleanup)
  Future<void> dispose() async {
    _batchTimer?.cancel();

    // Son kalan logları gönder
    await _sendQueuedLogs(immediate: true);

    // Box'ı kapat
    await _logBox?.close();
  }
}
