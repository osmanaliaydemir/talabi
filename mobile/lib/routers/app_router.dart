import 'package:flutter/material.dart';
// Import routers normally - Flutter's tree-shaking will remove unused code
// For true lazy loading, we use a factory pattern that only instantiates routers when needed
import 'package:mobile/routers/courier_router.dart';
import 'package:mobile/routers/customer_router.dart';
import 'package:mobile/routers/vendor_router.dart';
import 'package:mobile/screens/customer/auth/login_screen.dart';
import 'package:mobile/screens/courier/login_screen.dart';
import 'package:mobile/screens/vendor/login_screen.dart';

/// Ana uygulama router'ı
/// Tüm route'ları koordine eder ve role-based routing sağlar
/// Route'lar lazy load edilir - sadece gerektiğinde yüklenir
class AppRouter {
  // Cache for frequently used routes to avoid repeated string comparisons
  static const String _loginRoute = '/login';
  static const String _courierLoginRoute = '/courier/login';
  static const String _vendorLoginRoute = '/vendor/login';
  static const String _courierPrefix = '/courier/';
  static const String _vendorPrefix = '/vendor/';
  static const String _customerPrefix = '/customer/';

  /// Route'un hangi modüle ait olduğunu belirler ve ilgili router'a yönlendirir
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final routeName = settings.name;

    if (routeName == null) {
      return null;
    }

    // Shared/Auth route'ları - Most common routes first
    if (routeName == _loginRoute) {
      return MaterialPageRoute(builder: (context) => const LoginScreen());
    }

    // Courier login route
    if (routeName == _courierLoginRoute) {
      return MaterialPageRoute(
        builder: (context) => const CourierLoginScreen(),
      );
    }

    // Vendor login route
    if (routeName == _vendorLoginRoute) {
      return MaterialPageRoute(builder: (context) => const VendorLoginScreen());
    }

    // Courier route'ları - Lazy load (only instantiate when needed)
    if (routeName.startsWith(_courierPrefix)) {
      return CourierRouter.generateRoute(settings);
    }

    // Vendor route'ları - Lazy load (only instantiate when needed)
    if (routeName.startsWith(_vendorPrefix)) {
      return VendorRouter.generateRoute(settings);
    }

    // Customer route'ları - Lazy load (only instantiate when needed)
    if (routeName.startsWith(_customerPrefix)) {
      return CustomerRouter.generateRoute(settings);
    }

    // Bilinmeyen route'lar için null döndür
    // MaterialApp'in onUnknownRoute'u devreye girer
    return null;
  }
}
