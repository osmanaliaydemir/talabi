import 'package:flutter/material.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/screens/customer/cart_screen.dart';
import 'package:mobile/screens/customer/favorites_screen.dart';
import 'package:mobile/screens/customer/order_history_screen.dart';
import 'package:mobile/screens/shared/profile/profile_screen.dart';
import 'package:mobile/screens/customer/vendor_list_screen.dart';
import 'package:mobile/widgets/connectivity_banner.dart';
import 'package:mobile/widgets/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final List<Widget> _screens = [
    const VendorListScreen(),
    const FavoritesScreen(),
    const CartScreen(),
    const OrderHistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Set auth token if available
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token != null) {
      // Load cart from backend
      final cart = Provider.of<CartProvider>(context, listen: false);
      cart.loadCart();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomNav = Provider.of<BottomNavProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: bottomNav.currentIndex, children: _screens),
          // Floating banner at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: const ConnectivityBanner(),
          ),
        ],
      ),
      bottomNavigationBar: const PersistentBottomNavBar(),
    );
  }
}
