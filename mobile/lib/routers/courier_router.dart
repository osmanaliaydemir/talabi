import 'package:flutter/material.dart';
import 'package:mobile/models/courier_order.dart';
import 'package:mobile/screens/courier/courier_active_deliveries_screen.dart';
import 'package:mobile/screens/courier/courier_availability_screen.dart';
import 'package:mobile/screens/courier/courier_edit_profile_screen.dart';
import 'package:mobile/screens/courier/courier_navigation_settings_screen.dart';
import 'package:mobile/screens/courier/courier_notifications_screen.dart';
import 'package:mobile/screens/courier/courier_profile_screen.dart';
import 'package:mobile/screens/courier/delivery_proof_screen.dart';
import 'package:mobile/screens/courier/earnings_screen.dart';
import 'package:mobile/screens/courier/order_detail_screen.dart';
import 'package:mobile/screens/courier/order_map_screen.dart';

/// Courier modülü için route yöneticisi
class CourierRouter {
  /// Courier route'larını generate eder
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/courier/order-detail':
        final orderId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => OrderDetailScreen(orderId: orderId),
        );

      case '/courier/order-map':
        final order = settings.arguments as CourierOrder;
        return MaterialPageRoute(
          builder: (context) => OrderMapScreen(order: order),
        );

      case '/courier/profile':
        return MaterialPageRoute(
          builder: (context) => const CourierProfileScreen(),
        );

      case '/courier/profile/edit':
        return MaterialPageRoute(
          builder: (context) => const CourierEditProfileScreen(),
        );

      case '/courier/notifications':
        return MaterialPageRoute(
          builder: (context) => const CourierNotificationsScreen(),
        );

      case '/courier/earnings':
        return MaterialPageRoute(builder: (context) => const EarningsScreen());

      case '/courier/availability':
        return MaterialPageRoute(
          builder: (context) => const CourierAvailabilityScreen(),
        );

      case '/courier/navigation-settings':
        return MaterialPageRoute(
          builder: (context) => const CourierNavigationSettingsScreen(),
        );

      case '/courier/active-deliveries':
        final initialTab = settings.arguments as int?;
        return MaterialPageRoute(
          builder: (context) =>
              CourierActiveDeliveriesScreen(initialTabIndex: initialTab),
        );

      case '/courier/delivery-proof':
        final orderId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => DeliveryProofScreen(orderId: orderId),
        );

      default:
        return null;
    }
  }
}
