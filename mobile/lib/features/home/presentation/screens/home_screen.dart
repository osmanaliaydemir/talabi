import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/l10n/app_localizations.dart';

import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/features/home/presentation/widgets/special_home_header.dart';
import 'package:mobile/features/home/presentation/widgets/sections/home_category_section.dart';
import 'package:mobile/features/home/presentation/widgets/sections/home_vendor_section.dart';
import 'package:mobile/features/home/presentation/widgets/sections/home_product_section.dart';
import 'package:mobile/features/home/presentation/widgets/sections/home_campaign_section.dart';
import 'package:mobile/features/home/presentation/widgets/home_address_bottom_sheet.dart';

import 'package:mobile/features/categories/presentation/screens/categories_screen.dart';
import 'package:mobile/features/products/presentation/screens/customer/popular_product_list_screen.dart';
import 'package:mobile/features/notifications/presentation/screens/customer/notifications_screen.dart';
import 'package:mobile/features/vendors/presentation/screens/vendor_list_screen.dart';

import 'package:mobile/features/search/presentation/screens/search_screen.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/features/home/presentation/providers/home_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  // Track current category to detect changes
  MainCategory? _lastCategory;

  @override
  void initState() {
    super.initState();

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final homeProvider = context.read<HomeProvider>();

        // Listen to category changes
        Provider.of<BottomNavProvider>(
          context,
          listen: false,
        ).addListener(_onCategoryChanged);

        // Check if data needs loading (e.g. first run)
        if (homeProvider.vendors.isEmpty || homeProvider.addresses.isEmpty) {
          _loadData();
        }
      }
    });
  }

  /// Load data based on current context
  void _loadData() {
    if (!mounted) return;
    final bottomNav = context.read<BottomNavProvider>();
    final vendorType = bottomNav.selectedCategory == MainCategory.restaurant
        ? 1
        : 2;

    final homeProvider = context.read<HomeProvider>();

    // If addresses are empty, load them. The provider checks if already loading.
    // We pass refreshAddress: true only if we really need to fetch addresses.
    // If addresses list is empty, we force refresh.
    homeProvider.loadData(
      vendorType: vendorType,
      refreshAddress: homeProvider.addresses.isEmpty,
    );
  }

  void _onCategoryChanged() {
    if (!mounted) return;

    try {
      final bottomNav = context.read<BottomNavProvider>();
      final currentCategory = bottomNav.selectedCategory;

      // Only reload if category actually changed
      if (_lastCategory != null && _lastCategory != currentCategory) {
        final vendorType = currentCategory == MainCategory.restaurant ? 1 : 2;
        // Delay to avoid setState during bottom sheet animation
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            context.read<HomeProvider>().loadData(vendorType: vendorType);
            _lastCategory = currentCategory;
          }
        });
      }
      _lastCategory = currentCategory;
    } catch (e, stackTrace) {
      LoggerService().error('Error in _onCategoryChanged', e, stackTrace);
    }
  }

  @override
  void dispose() {
    // Remove category change listener
    // Note: accessing Provider.of(listen:false) is generally safe in dispose if context is valid,
    // but context.read is stricter. We'll skip removeListener here relying on BottomNavProvider persistence
    // or garbage collection, as HomeScreen is main screen and likely only disposed on app exit or logout.
    super.dispose();
  }

  /// Public method to refresh addresses from external callers
  void refreshAddresses() {
    // Reload addresses via provider
    final homeProvider = context.read<HomeProvider>();
    homeProvider.loadAddresses().then((_) {
      if (mounted) _loadData();
    });
  }

  void _showAddressBottomSheet() {
    final homeProvider = context.read<HomeProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return HomeAddressBottomSheet(
          addresses: homeProvider.addresses,
          selectedAddress: homeProvider.selectedAddress,
          colorScheme: colorScheme,
          onAddressSelected: (address) {
            homeProvider.setSelectedAddress(address);
            // Reload data with new address context
            _loadData();
          },
          onSetDefault: (address) async {
            await homeProvider.setDefaultAddress(address['id']);
            if (!context.mounted) return;
            Navigator.pop(context);
            // Reload data might enter race condition if setDefaultAddress already reloaded addresses.
            // But doing _loadData ensures content is fresh for new default address.
            _loadData();
          },
        );
      },
    );
  }

  String _getAddressDisplayText(
    Map<String, dynamic> address,
    AppLocalizations localizations,
  ) {
    final district = address['district'] ?? '';
    final city = address['city'] ?? '';
    if (district.isNotEmpty && city.isNotEmpty) {
      return '$district, $city';
    } else if (address['fullAddress'] != null &&
        address['fullAddress'].toString().isNotEmpty) {
      return address['fullAddress'].toString();
    }
    return localizations.address;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Watch provider
    final homeProvider = context.watch<HomeProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: () async {
          _loadData();
          // Artificial delay for better UX if network is too fast
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          slivers: [
            // Header (Sticky)
            SliverPersistentHeader(
              pinned: true,
              delegate: _HomeHeaderDelegate(
                expandedHeight: 310,
                collapsedHeight:
                    kToolbarHeight + MediaQuery.of(context).padding.top,
                paddingTop: MediaQuery.of(context).padding.top,
                onLocationTap: _showAddressBottomSheet,
                onNotificationTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
                onSearchTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
                currentLocation: homeProvider.selectedAddress != null
                    ? _getAddressDisplayText(
                        homeProvider.selectedAddress!,
                        localizations,
                      )
                    : null,
                isAddressesLoading: homeProvider.isAddressesLoading,
              ),
            ),

            // Spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacingSmall),
            ),

            // Categories Section
            SliverToBoxAdapter(
              child: HomeCategorySection(
                categories: homeProvider.categories,
                hasVendors: homeProvider.hasVendors,
                hasProducts: homeProvider.hasProducts,
                isLoading: homeProvider.isLoading,
                onViewAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoriesScreen(),
                    ),
                  );
                },
              ),
            ),

            // Picks For You Section (Popular Products)
            SliverToBoxAdapter(
              child: HomeProductSection(
                products: homeProvider.popularProducts,
                favoriteStatus: homeProvider.favoriteStatus,
                hasVendors: homeProvider.hasVendors,
                isLoading: homeProvider.isLoading,
                onProductsLoaded: (hasProducts) {
                  // Deprecated
                },
                onViewAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PopularProductListScreen(),
                    ),
                  );
                },
                onFavoriteToggle: (product) {
                  homeProvider.toggleFavorite(product.id).catchError((e) {
                    if (context.mounted) {
                      ToastMessage.show(
                        context,
                        message: localizations.favoriteOperationFailed(
                          e.toString(),
                        ),
                        isSuccess: false,
                      );
                    }
                  });
                },
              ),
            ),

            // Promotional Banner Section (Campaigns)
            SliverToBoxAdapter(
              child: HomeCampaignSection(banners: homeProvider.banners),
            ),

            // Popular Vendors Section
            SliverToBoxAdapter(
              child: HomeVendorSection(
                vendors: homeProvider.vendors,
                isLoading: homeProvider.isLoading,
                onVendorsLoaded: (hasVendors) {
                  // Deprecated
                },
                onViewAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorListScreen(),
                    ),
                  );
                },
              ),
            ),

            // Bottom Spacing (Extra space to avoid FAB/BottomNav overlap if any)
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HomeHeaderDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.paddingTop,
    required this.onNotificationTap,
    required this.onLocationTap,
    required this.currentLocation,
    required this.onSearchTap,
    required this.isAddressesLoading,
  });

  final double expandedHeight;
  final double collapsedHeight;
  final double paddingTop;
  final VoidCallback onNotificationTap;
  final VoidCallback onLocationTap;
  final String? currentLocation;
  final VoidCallback onSearchTap;
  final bool isAddressesLoading;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double progress = shrinkOffset / (expandedHeight - collapsedHeight);
    // Show sticky bar later (e.g. > 80% scrolled) to avoid "large header" ghost effect
    final bool showSticky = progress > 0.8;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Full Header (Scrolls away)
        Positioned(
          top: -shrinkOffset,
          left: 0,
          right: 0,
          height: expandedHeight,
          child: SpecialHomeHeader(
            onLocationTap: onLocationTap,
            onNotificationTap: onNotificationTap,
            currentLocation: currentLocation,
            isAddressesLoading: isAddressesLoading,
          ),
        ),

        // Sticky Bar (Fades in)
        if (showSticky)
          Opacity(
            opacity: ((progress - 0.8) * 5.0).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.only(top: paddingTop, left: 16, right: 8),
              alignment: Alignment.center,
              child: SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: [
                    // Address
                    Expanded(
                      child: GestureDetector(
                        onTap: onLocationTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  currentLocation ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Search Icon
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: onSearchTap,
                      tooltip: 'Search',
                    ),
                    // Notification Icon
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                          ),
                          onPressed: onNotificationTap,
                          tooltip: 'Notifications',
                        ),
                        Consumer<NotificationProvider>(
                          builder: (context, notificationProvider, child) {
                            if (notificationProvider.unreadCount > 0) {
                              return Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.fromBorderSide(
                                      BorderSide(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${notificationProvider.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return currentLocation != oldDelegate.currentLocation ||
        isAddressesLoading != oldDelegate.isAddressesLoading ||
        expandedHeight != oldDelegate.expandedHeight ||
        collapsedHeight != oldDelegate.collapsedHeight ||
        paddingTop != oldDelegate.paddingTop;
  }
}
