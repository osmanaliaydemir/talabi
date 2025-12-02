import 'package:flutter/material.dart';
import 'package:mobile/screens/customer/order_history_screen.dart';
import 'package:mobile/screens/customer/order_detail_screen.dart';
import 'package:mobile/screens/shared/onboarding/main_navigation_screen.dart';

/// Customer modülü için route yöneticisi
class CustomerRouter {
  /// Customer route'larını generate eder
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/customer/home':
        return MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(),
        );

      case '/customer/orders':
        return MaterialPageRoute(
          builder: (context) => const OrderHistoryScreen(),
        );

      case '/customer/order-detail':
        final orderId = settings.arguments as String?;
        if (orderId == null) return null;
        return MaterialPageRoute(
          builder: (context) => OrderDetailScreen(orderId: orderId),
        );

      default:
        return null;
    }
  }
}
