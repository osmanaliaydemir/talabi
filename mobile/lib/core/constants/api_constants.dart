class ApiEndpoints {
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyResetCode = '/auth/verify-reset-code';
  static const String confirmEmail = '/auth/confirm-email';
  static const String verifyEmail = '/auth/verify-email';
  static const String verifyEmailCode = '/auth/verify-email-code';
  static const String resendVerification = '/auth/resend-verification';
  static const String resendVerificationCode = '/auth/resend-verification-code';
  static const String deleteAccount = '/auth/delete-account';
  static const String vendorRegister = '/auth/vendor-register';
  static const String courierRegister = '/auth/courier-register';
  static const String externalLogin = '/auth/external-login';
  static const String registerDeviceToken = '/notification/register-device';
  static const String banners = '/banners';
  static const String upload = '/upload';

  // Products
  static const String products = '/products';
  static const String productSearch = '/products/search';
  static const String popularProducts = '/products/popular';
  static const String similarProducts = '/products/similar'; // Base path
  static const String favorites = '/favorites';
  static const String favoriteCheck = '/favorites/check'; // Base path

  // ... (Vendors, Orders, Cart, Location - assume these are fine or updated in prev chunks if needed, but here we focus on Products/Notifications)

  // Reuse existing lines for Vendors... to keep context if I can't jump.
  // Actually I need to match specific block.
  // Let's target Products block first.

  // Vendors
  static const String vendors = '/vendors';
  static const String vendorProducts = '/vendor/products';
  static const String vendorCategories = '/vendor/products/categories';
  static const String vendorProfile = '/vendor/profile';
  static const String vendorProfileImage = '/vendor/profile/image';
  static const String vendorSettingsStatus = '/vendor/profile/status';
  static const String vendorSettings = '/vendor/profile/settings';
  static const String vendorSettingsActive = '/vendor/profile/settings/active';
  static const String vendorCities = '/vendors/cities';
  static const String mapVendors = '/map/vendors';
  static const String vendorDeliveryZones = '/vendor/delivery-zones';
  static const String vendorNotifications = '/vendor/notifications';

  // Orders
  static const String orders = '/orders';
  static const String createOrder = '/orders';
  static const String vendorOrders = '/vendor/orders';
  static const String cancelOrder = '/orders/cancel';
  static const String cancelOrderItem = '/orders/items/cancel';

  // Cart
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';

  // Location / Common
  static const String countries = '/locations/countries';
  static const String cities = '/locations/cities'; // Base path
  static const String districts = '/locations/districts'; // Base path
  static const String localities = '/locations/localities'; // Base path
  static const String courierLocation = '/courier'; // Base path
  static const String mapApiKey = '/map/api-key';
  static const String deliveryTracking = '/map/delivery-tracking';
  static const String apiAutocomplete = '/search/autocomplete';
  static const String legalContent = '/content/legal';

  // Reviews
  static const String reviews = '/reviews';
  static const String reviewsMy = '/reviews/my-reviews';
  static const String reviewsProduct = '/reviews/product'; // Base path
  static const String reviewsVendor = '/reviews/vendor'; // Base path
  static const String reviewsPending = '/reviews/pending';
  static const String reviewsApprove = '/reviews/approve';
  static const String reviewsReject = '/reviews/reject';

  // User
  static const String userProfile = '/profile';
  static const String userPreferences = '/userpreferences';
  static const String userPreferencesSupportedCurrencies =
      '/userpreferences/supported-currencies';
  static const String userPreferencesSupportedLanguages =
      '/userpreferences/supported-languages';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notifications/settings';
  static const String customerNotifications = '/customer/notifications';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static const String courierNotifications = '/courier/notifications';

  // Courier
  static const String courierProfile = '/courier/profile';
  static const String courierStatus = '/courier/status';
  static const String courierStatistics = '/courier/statistics';
  static const String courierActiveOrders = '/courier/orders/active';
  static const String courierOrders =
      '/courier/orders'; // Base for order details, actions
  static const String courierEarningsToday = '/courier/earnings/today';
  static const String courierEarningsWeek = '/courier/earnings/week';
  static const String courierEarningsMonth = '/courier/earnings/month';
  static const String courierEarningsHistory = '/courier/earnings/history';
  static const String courierCheckAvailability = '/courier/check-availability';
  static const String courierOrdersHistory = '/courier/orders/history';
  static const String courierVehicleTypes = '/courier/vehicle-types';
}
