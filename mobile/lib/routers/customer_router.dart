import 'package:flutter/material.dart';

/// Customer modülü için route yöneticisi
/// Şu an için customer route'ları MainNavigationScreen içinde yönetiliyor
/// Gelecekte buraya customer-specific route'lar eklenebilir
class CustomerRouter {
  /// Customer route'larını generate eder
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Customer-specific route'lar buraya eklenecek
      // Örnek:
      // case '/customer/order-detail':
      //   final orderId = settings.arguments as int;
      //   return MaterialPageRoute(
      //     builder: (context) => CustomerOrderDetailScreen(orderId: orderId),
      //   );

      default:
        return null;
    }
  }
}
