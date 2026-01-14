class AppConstants {
  // Animation Durations
  static const Duration animationDurationShort = Duration(milliseconds: 300);
  static const Duration animationDurationMedium = Duration(milliseconds: 500);
  static const Duration animationDurationLong = Duration(milliseconds: 800);

  // API Checkouts/Limits
  static const int defaultPageSize = 20;
  static const int maxRetries = 3;
  static const Duration apiTimeout = Duration(seconds: 30);

  // Validation
  static const int minPasswordLength = 6;
  static const int minPhoneLength = 10;
}
