class CourierApiEndpoints {
  // Courier Dashboard - Account
  static const String profile = '/couriers/dashboard/account/profile';
  static const String status = '/couriers/dashboard/account/status';
  static const String location = '/couriers/dashboard/account/location';
  static const String vehicleTypes = '/couriers/dashboard/account/vehicle-types';
  static const String checkAvailability =
      '/couriers/dashboard/account/check-availability';

  // Courier Dashboard - Orders
  static const String orders = '/couriers/dashboard/orders';
  static const String activeOrders = '/couriers/dashboard/orders/active';
  static const String ordersHistory = '/couriers/dashboard/orders/history';

  // Courier Dashboard - Earnings
  static const String earningsToday = '/couriers/dashboard/earnings/today';
  static const String earningsWeek = '/couriers/dashboard/earnings/week';
  static const String earningsMonth = '/couriers/dashboard/earnings/month';
  static const String earningsHistory =
      '/couriers/dashboard/earnings/history';

  // Courier Dashboard - Statistics
  static const String statistics = '/couriers/dashboard/statistics';

  // Courier Dashboard - Notifications
  static const String notifications = '/couriers/dashboard/notifications';

  // Helper methods for dynamic endpoints
  static String order(String orderId) => '$orders/$orderId';
  static String orderAccept(String orderId) => '$orders/$orderId/accept';
  static String orderReject(String orderId) => '$orders/$orderId/reject';
  static String orderPickup(String orderId) => '$orders/$orderId/pickup';
  static String orderDeliver(String orderId) => '$orders/$orderId/deliver';
  static String orderProof(String orderId) => '$orders/$orderId/proof';

  static String notificationRead(String id) => '$notifications/$id/read';
  static const String notificationsReadAll = '$notifications/read-all';
}
