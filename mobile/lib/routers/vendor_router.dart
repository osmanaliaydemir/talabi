import 'package:flutter/material.dart';
import 'package:mobile/utils/custom_routes.dart';
import 'package:mobile/features/profile/presentation/screens/vendor/edit_profile_screen.dart';
import 'package:mobile/features/notifications/presentation/screens/vendor/notifications_screen.dart';
import 'package:mobile/features/orders/presentation/screens/vendor/orders_screen.dart';
import 'package:mobile/features/products/presentation/screens/vendor/products_screen.dart';
import 'package:mobile/features/profile/presentation/screens/vendor/profile_screen.dart';
import 'package:mobile/features/orders/presentation/screens/vendor/order_detail_screen.dart';
import 'package:mobile/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:mobile/features/auth/presentation/screens/vendor/vendor_forgot_password_screen.dart';
import 'package:mobile/features/auth/presentation/screens/vendor/vendor_verify_reset_code_screen.dart';
import 'package:mobile/features/auth/presentation/screens/vendor/vendor_reset_password_screen.dart';

import 'package:mobile/features/dashboard/presentation/widgets/vendor_bottom_nav.dart';

/// Vendor modülü için route yöneticisi
class VendorRouter {
  /// Vendor route'larını generate eder
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/vendor/forgot-password':
        return NoSlidePageRoute(
          builder: (context) => const VendorForgotPasswordScreen(),
        );

      case '/vendor/verify-reset-code':
        return NoSlidePageRoute(
          builder: (context) => const VendorVerifyResetCodeScreen(email: ''),
        );

      case '/vendor/reset-password':
        return NoSlidePageRoute(
          builder: (context) =>
              const VendorResetPasswordScreen(email: '', token: ''),
        );

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

      case '/vendor/order-detail':
        final orderId = settings.arguments as String?;
        if (orderId == null) return null;
        return NoSlidePageRoute(
          builder: (context) => VendorOrderDetailScreen(orderId: orderId),
        );

      case '/vendor/wallet':
        return NoSlidePageRoute(
          builder: (context) => const WalletScreen(
            bottomNavigationBar: VendorBottomNav(currentIndex: 3),
          ),
        );

      default:
        return null;
    }
  }
}
