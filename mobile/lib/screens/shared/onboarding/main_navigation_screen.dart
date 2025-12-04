import 'package:flutter/material.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/screens/customer/cart_screen.dart';
import 'package:mobile/screens/customer/favorites_screen.dart';
import 'package:mobile/screens/customer/order/order_history_screen.dart';
import 'package:mobile/screens/customer/profile/profile_screen.dart';
import 'package:mobile/screens/customer/home_screen.dart';
import 'package:mobile/widgets/common/connectivity_banner.dart';
import 'package:mobile/screens/customer/widgets/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const FavoritesScreen(),
    const CartScreen(),
    const OrderHistoryScreen(showBackButton: false),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Load cart after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.token != null && mounted) {
        // Load cart from backend
        final cart = Provider.of<CartProvider>(context, listen: false);
        cart.loadCart();

        // Load notifications
        final notifications = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        notifications.loadNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomNav = Provider.of<BottomNavProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: bottomNav.currentIndex, children: _screens),
          // Floating banner at the top
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConnectivityBanner(),
          ),
        ],
      ),
      bottomNavigationBar: const PersistentBottomNavBar(),
    );
  }
}
