class VendorApiEndpoints {
  // Vendor Dashboard - Products
  static const String products = '/vendors/dashboard/products';
  static const String productCategories =
      '/vendors/dashboard/products/categories';

  // Vendor Dashboard - Account
  static const String profile = '/vendors/dashboard/account/profile';
  static const String profileImage = '/vendors/dashboard/account/profile/image';
  static const String settings = '/vendors/dashboard/account/settings';
  static const String settingsActive =
      '/vendors/dashboard/account/settings/active';
  static const String settingsStatus =
      '/vendors/dashboard/account/settings/status';

  // Vendor Dashboard - Orders
  static const String orders = '/vendors/dashboard/orders';

  // Vendor Dashboard - Reports
  static const String reportsSales = '/vendors/dashboard/reports/sales';
  static const String reportsSummary = '/vendors/dashboard/reports/summary';
  static const String reportsHourlySales =
      '/vendors/dashboard/reports/hourly-sales';
  static const String reportsAlerts = '/vendors/dashboard/reports/alerts';

  // Vendor Dashboard - Notifications
  static const String notifications = '/vendors/dashboard/notifications';

  // Vendor Dashboard - Delivery Zones
  static const String deliveryZones = '/vendors/dashboard/delivery-zones';

  // Helper methods for dynamic endpoints
  static String order(String orderId) => '$orders/$orderId';
  static String orderAccept(String orderId) => '$orders/$orderId/accept';
  static String orderReject(String orderId) => '$orders/$orderId/reject';
  static String orderStatus(String orderId) => '$orders/$orderId/status';
  static String orderAvailableCouriers(String orderId) =>
      '$orders/$orderId/available-couriers';
  static String orderAssignCourier(String orderId) =>
      '$orders/$orderId/assign-courier';
  static String orderAutoAssignCourier(String orderId) =>
      '$orders/$orderId/auto-assign-courier';

  static String product(String productId) => '$products/$productId';
  static String productAvailability(String productId) =>
      '$products/$productId/availability';
  static String productPrice(String productId) => '$products/$productId/price';

  static String notificationRead(String id) => '$notifications/$id/read';
  static const String notificationsReadAll = '$notifications/read-all';
}
