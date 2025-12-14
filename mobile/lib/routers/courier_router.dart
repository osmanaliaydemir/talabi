import 'package:flutter/material.dart';
import 'package:mobile/utils/custom_routes.dart';
import 'package:mobile/models/courier_order.dart';
import 'package:mobile/screens/courier/active_deliveries_screen.dart';
import 'package:mobile/screens/courier/availability_screen.dart';
import 'package:mobile/screens/courier/edit_profile_screen.dart';
import 'package:mobile/screens/courier/location_management_screen.dart';
import 'package:mobile/screens/courier/navigation_settings_screen.dart';
import 'package:mobile/screens/courier/notifications_screen.dart';
import 'package:mobile/screens/courier/profile_screen.dart';
import 'package:mobile/screens/courier/delivery_proof_screen.dart';
import 'package:mobile/screens/courier/earnings_screen.dart';
import 'package:mobile/screens/courier/order_detail_screen.dart';
import 'package:mobile/screens/courier/order_map_screen.dart';
import 'package:mobile/services/logger_service.dart';

/// Courier modülü için route yöneticisi
class CourierRouter {
  /// Courier route'larını generate eder
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/courier/order-detail':
        final orderId = settings.arguments as String?;
        if (orderId == null || orderId.isEmpty) {
          LoggerService().warning(
            'CourierRouter: order-detail route called but orderId is null or empty',
          );
          return null;
        }
        LoggerService().info(
          'CourierRouter: Creating OrderDetailScreen with orderId: $orderId',
        );
        return NoSlidePageRoute(
          builder: (context) => OrderDetailScreen(orderId: orderId),
        );

      case '/courier/order-map':
        final order = settings.arguments as CourierOrder;
        return NoSlidePageRoute(
          builder: (context) => OrderMapScreen(order: order),
        );

      case '/courier/profile':
        return NoSlidePageRoute(
          builder: (context) => const CourierProfileScreen(),
        );

      case '/courier/profile/edit':
        return NoSlidePageRoute(
          builder: (context) => const CourierEditProfileScreen(),
        );

      case '/courier/notifications':
        return NoSlidePageRoute(
          builder: (context) => const CourierNotificationsScreen(),
        );

      case '/courier/earnings':
        return NoSlidePageRoute(builder: (context) => const EarningsScreen());

      case '/courier/availability':
        return NoSlidePageRoute(
          builder: (context) => const CourierAvailabilityScreen(),
        );

      case '/courier/navigation-settings':
        return NoSlidePageRoute(
          builder: (context) => const CourierNavigationSettingsScreen(),
        );

      case '/courier/location-management':
        return NoSlidePageRoute(
          builder: (context) => const CourierLocationManagementScreen(),
        );

      case '/courier/active-deliveries':
        final initialTab = settings.arguments as int?;
        return NoSlidePageRoute(
          builder: (context) =>
              CourierActiveDeliveriesScreen(initialTabIndex: initialTab),
        );

      case '/courier/delivery-proof':
        final orderId = settings.arguments as String;
        return NoSlidePageRoute(
          builder: (context) => DeliveryProofScreen(orderId: orderId),
        );

      default:
        return null;
    }
  }
}
