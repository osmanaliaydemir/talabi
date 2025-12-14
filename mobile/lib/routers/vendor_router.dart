import 'package:flutter/material.dart';
import 'package:mobile/utils/custom_routes.dart';
import 'package:mobile/screens/vendor/edit_profile_screen.dart';
import 'package:mobile/screens/vendor/notifications_screen.dart';
import 'package:mobile/screens/vendor/orders_screen.dart';
import 'package:mobile/screens/vendor/products_screen.dart';
import 'package:mobile/screens/vendor/profile_screen.dart';

/// Vendor modülü için route yöneticisi
class VendorRouter {
  /// Vendor route'larını generate eder
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/vendor/orders':
        return NoSlidePageRoute(
          builder: (context) => const VendorOrdersScreen(),
        );

      case '/vendor/notifications':
        return NoSlidePageRoute(
          builder: (context) => const VendorNotificationsScreen(),
        );

      case '/vendor/products':
        return NoSlidePageRoute(
          builder: (context) => const VendorProductsScreen(),
        );

      case '/vendor/profile':
        return NoSlidePageRoute(
          builder: (context) => const VendorProfileScreen(),
        );

      case '/vendor/profile/edit':
        return NoSlidePageRoute(
          builder: (context) => const VendorEditProfileScreen(),
        );

      default:
        return null;
    }
  }
}
