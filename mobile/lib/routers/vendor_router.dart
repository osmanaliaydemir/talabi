import 'package:flutter/material.dart';
import 'package:mobile/screens/vendor/vendor_edit_profile_screen.dart';
import 'package:mobile/screens/vendor/vendor_orders_screen.dart';
import 'package:mobile/screens/vendor/vendor_products_screen.dart';
import 'package:mobile/screens/vendor/vendor_profile_screen.dart';

/// Vendor modülü için route yöneticisi
class VendorRouter {
  /// Vendor route'larını generate eder
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/vendor/orders':
        return MaterialPageRoute(
          builder: (context) => const VendorOrdersScreen(),
        );

      case '/vendor/products':
        return MaterialPageRoute(
          builder: (context) => const VendorProductsScreen(),
        );

      case '/vendor/profile':
        return MaterialPageRoute(
          builder: (context) => const VendorProfileScreen(),
        );

      case '/vendor/profile/edit':
        return MaterialPageRoute(
          builder: (context) => const VendorEditProfileScreen(),
        );

      default:
        return null;
    }
  }
}
