import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/features/cart/presentation/screens/cart_screen.dart';
import 'package:mobile/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:mobile/features/orders/presentation/screens/customer/order_history_screen.dart';
import 'package:mobile/features/profile/presentation/screens/customer/profile_screen.dart';
import 'package:mobile/features/home/presentation/screens/home_screen.dart';
import 'package:mobile/features/profile/presentation/screens/customer/add_edit_address_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/widgets/connectivity_banner.dart';
import 'package:mobile/widgets/custom_confirmation_dialog.dart';
import 'package:mobile/features/home/presentation/screens/bottom_nav_screen.dart';
import 'package:mobile/features/orders/data/models/order_detail.dart';
import 'package:mobile/features/reviews/presentation/screens/order_feedback_screen.dart';
import 'package:provider/provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final ApiService _apiService = ApiService();
  bool _hasCheckedAddress = false;
  final GlobalKey<HomeScreenState> _homeScreenKey =
      GlobalKey<HomeScreenState>();

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
        Provider.of<CartProvider>(context, listen: false).loadCart().then((_) {
          if (mounted) {
            final cartProvider = Provider.of<CartProvider>(
              context,
              listen: false,
            );
            LoggerService().info(
              '🛒 [SYNC] Cart items count: ${cartProvider.items.length}',
            );

            if (cartProvider.items.isNotEmpty) {
              final firstItem = cartProvider.items.values.first;
              // VendorType: 1 = Restaurant, 2 = Market
              final vendorType = firstItem.product.vendorType;

              LoggerService().info(
                '🛒 [SYNC] First item: ${firstItem.product.name}, VendorType: $vendorType',
              );

              if (vendorType != null) {
                final bottomNav = Provider.of<BottomNavProvider>(
                  context,
                  listen: false,
                );

                LoggerService().info(
                  '🛒 [SYNC] Current Category: ${bottomNav.selectedCategory}, Target VendorType: $vendorType',
                );

                if (vendorType == 1 &&
                    bottomNav.selectedCategory != MainCategory.restaurant) {
                  LoggerService().info(
                    '🛒 [SYNC] Switching to Restaurant mode',
                  );
                  bottomNav.setCategory(MainCategory.restaurant);
                } else if (vendorType == 2 &&
                    bottomNav.selectedCategory != MainCategory.market) {
                  LoggerService().info('🛒 [SYNC] Switching to Market mode');
                  bottomNav.setCategory(MainCategory.market);
                }
              }
            }
          }
        });

        // Load notifications
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).loadNotifications();

        // Check if user has address
        _checkAndShowAddressBottomSheet();

        // Check for unreviewed orders
        _checkUnreviewedOrder();
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
      LoggerService().error('Error checking addresses: $e', e);
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                localizations.addressRequiredMessage,
                style: const TextStyle(
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

  Future<void> _checkUnreviewedOrder() async {
    try {
      final unreviewedOrder = await _apiService.getUnreviewedOrder();
      if (unreviewedOrder != null && mounted) {
        final orderId = unreviewedOrder['id']?.toString();

        if (orderId == null) return;

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => CustomConfirmationDialog(
              title: 'Siparişi Değerlendir',
              message:
                  'Son siparişin nasıldı? Deneyimini paylaşmak ister misin?',
              confirmText: 'Siparişi Değerlendir',
              cancelText: 'Şimdi Değil',
              icon: Icons.star,
              iconColor: Colors.amber,
              confirmButtonColor: AppTheme.primaryOrange,
              onConfirm: () async {
                final navigator = Navigator.of(context)..pop(); // Close dialog
                try {
                  // Fetch full order detail for OrderFeedbackScreen
                  final detailData = await _apiService.getOrderDetailFull(
                    orderId,
                  );
                  final orderDetail = OrderDetail.fromJson(detailData);

                  if (mounted) {
                    navigator.push(
                      MaterialPageRoute(
                        builder: (context) =>
                            OrderFeedbackScreen(orderDetail: orderDetail),
                      ),
                    );
                  }
                } catch (e) {
                  LoggerService().error('Error loading order for feedback: $e');
                }
              },
            ),
          );
        }
      }
    } catch (e) {
      LoggerService().error('Error checking unreviewed order: $e', e);
    }
  }
}
