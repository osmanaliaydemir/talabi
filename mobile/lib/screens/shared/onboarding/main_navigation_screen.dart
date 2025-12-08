import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/screens/customer/cart_screen.dart';
import 'package:mobile/screens/customer/favorites_screen.dart';
import 'package:mobile/screens/customer/order/order_history_screen.dart';
import 'package:mobile/screens/customer/profile/profile_screen.dart';
import 'package:mobile/screens/customer/home_screen.dart';
import 'package:mobile/screens/customer/profile/add_edit_address_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/connectivity_banner.dart';
import 'package:mobile/screens/customer/widgets/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final ApiService _apiService = ApiService();
  bool _hasCheckedAddress = false;
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();

  @override
  Widget build(BuildContext context) {
    final bottomNav = Provider.of<BottomNavProvider>(context);

    // HomeScreen zaten VendorType'a göre dinamik olarak çalışıyor
    final homeScreen = HomeScreen(key: _homeScreenKey);

    final List<Widget> screens = [
      homeScreen,
      const FavoritesScreen(),
      const CartScreen(),
      const OrderHistoryScreen(showBackButton: false),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: bottomNav.currentIndex, children: screens),
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

        // Check if user has address
        _checkAndShowAddressBottomSheet();
      }
    });
  }

  Future<void> _checkAndShowAddressBottomSheet() async {
    if (_hasCheckedAddress) return;
    
    try {
      final addresses = await _apiService.getAddresses();
      if (!mounted) return;
      
      _hasCheckedAddress = true;
      
      // If no addresses, show bottom sheet
      if (addresses.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showRequiredAddressBottomSheet();
          }
        });
      }
    } catch (e) {
      print('Error checking addresses: $e');
      // Don't block user if check fails
      _hasCheckedAddress = true;
    }
  }

  Future<void> _showRequiredAddressBottomSheet() async {
    final localizations = AppLocalizations.of(context)!;

    await showModalBottomSheet(
      context: context,
      isDismissible: false, // Zorunlu - kapatılamaz
      enableDrag: false, // Zorunlu - sürüklenemez
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                localizations.addressRequiredTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                localizations.addressRequiredMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Add Address button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddEditAddressScreen(),
                      ),
                    );
                    // After adding address, check again
                    if (result == true && mounted) {
                      _hasCheckedAddress = false;
                      _checkAndShowAddressBottomSheet();
                      // Refresh home screen addresses
                      _homeScreenKey.currentState?.refreshAddresses();
                    }
                  },
                  icon: const Icon(Icons.add_location_alt),
                  label: Text(
                    localizations.addAddress,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
