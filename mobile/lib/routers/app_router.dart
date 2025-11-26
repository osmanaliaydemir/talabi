import 'package:flutter/material.dart';
import 'package:mobile/routers/courier_router.dart';
import 'package:mobile/routers/customer_router.dart';
import 'package:mobile/routers/vendor_router.dart';
import 'package:mobile/screens/shared/auth/login_screen.dart';
import 'package:mobile/screens/courier/courier_login_screen.dart';
import 'package:mobile/screens/vendor/vendor_login_screen.dart';

/// Ana uygulama router'ı
/// Tüm route'ları koordine eder ve role-based routing sağlar
class AppRouter {
  /// Route'un hangi modüle ait olduğunu belirler ve ilgili router'a yönlendirir
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final routeName = settings.name;

    if (routeName == null) {
      return null;
    }

    // Shared/Auth route'ları
    if (routeName == '/login') {
      return MaterialPageRoute(builder: (context) => const LoginScreen());
    }

    // Courier login route
    if (routeName == '/courier/login') {
      return MaterialPageRoute(
        builder: (context) => const CourierLoginScreen(),
      );
    }

    // Vendor login route
    if (routeName == '/vendor/login') {
      return MaterialPageRoute(builder: (context) => const VendorLoginScreen());
    }

    // Courier route'ları
    if (routeName.startsWith('/courier/')) {
      return CourierRouter.generateRoute(settings);
    }

    // Vendor route'ları
    if (routeName.startsWith('/vendor/')) {
      return VendorRouter.generateRoute(settings);
    }

    // Customer route'ları
    if (routeName.startsWith('/customer/')) {
      return CustomerRouter.generateRoute(settings);
    }

    // Bilinmeyen route'lar için null döndür
    // MaterialApp'in onUnknownRoute'u devreye girer
    return null;
  }
}
