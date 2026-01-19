import 'package:flutter/foundation.dart';

/// Application configuration based on environment.
///
/// Environment can be set via `--dart-define=ENV=prod` during build/run.
/// If not set, defaults to:
/// - `dev` in debug mode
/// - `prod` in release mode
class AppConfig {
  AppConfig._();

  static const String _env = String.fromEnvironment(
    'ENV',
    defaultValue: kDebugMode ? 'dev' : 'prod',
  );

  static String get environment => _env;

  static bool get isDev => _env == 'dev';
  static bool get isStaging => _env == 'staging';
  static bool get isProd => _env == 'prod';

  /// API base URL based on environment.
  static String get apiBaseUrl {
    switch (_env) {
      case 'prod':
        return 'https://api.talabygo.com/api';
      case 'staging':
        // Add staging URL when available
        // return 'https://talabi.runasp.net/api';
        return 'https://api.talabygo.com/api';
      case 'dev':
      default:
        //return 'https://talabi.runasp.net/api';
        return 'https://api.talabygo.com/api';
    }
  }
}
