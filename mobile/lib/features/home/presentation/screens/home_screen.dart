import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/features/vendors/data/models/vendor.dart';
import 'package:mobile/features/campaigns/data/models/campaign.dart';
import 'package:mobile/services/api_service.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Vendor>> _vendorsFuture;
  late Future<List<Product>> _popularProductsFuture;
  late Future<List<Map<String, dynamic>>> _categoriesFuture;
  List<dynamic> _addresses = [];
  Map<String, dynamic>? _selectedAddress;
  bool _isAddressesLoading = true;

  // Track vendor/product states for conditional rendering
  bool _hasVendors = false;
  bool _hasProducts = false;

  final Map<String, bool> _favoriteStatus =
      {}; // Track favorite status for each product

  // Campaigns state
  List<Campaign> _banners = [];

  // Track current category to detect changes
  MainCategory? _lastCategory;

  @override
  void initState() {
    super.initState();
    // Initialize futures with empty lists to prevent null errors
    _vendorsFuture = Future.value(<Vendor>[]);
    _popularProductsFuture = Future.value(<Product>[]);
    _categoriesFuture = Future.value(<Map<String, dynamic>>[]);
    _loadAddresses();
    _loadFavoriteStatus();

    // Listen to category changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<BottomNavProvider>(
          context,
          listen: false,
        ).addListener(_onCategoryChanged);
      }
    });
  }

  /// VendorType'a göre verileri yükle
  void _loadData({int? vendorType}) {
    // Eğer vendorType parametre olarak verilmediyse, provider'dan al
    if (vendorType == null) {
      final bottomNav = Provider.of<BottomNavProvider>(context, listen: false);
      vendorType = bottomNav.selectedCategory == MainCategory.restaurant
          ? 1
          : 2;
    }
    final locale = AppLocalizations.of(context)?.localeName;

    // Get location from selected address
    double? userLatitude;
    double? userLongitude;
    if (_selectedAddress != null) {
      userLatitude = _selectedAddress!['latitude'] != null
          ? double.tryParse(_selectedAddress!['latitude'].toString())
          : null;
      userLongitude = _selectedAddress!['longitude'] != null
          ? double.tryParse(_selectedAddress!['longitude'].toString())
          : null;
    }

    setState(() {
      _vendorsFuture = _apiService.getVendors(
        vendorType: vendorType,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );
      _popularProductsFuture = _apiService.getPopularProducts(
        page: 1,
        pageSize: 8,
        vendorType: vendorType,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );
      _categoriesFuture = _apiService.getCategories(
        language: locale,
        vendorType: vendorType,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );
    });
    _loadCampaigns(vendorType: vendorType);
  }

  void _onCategoryChanged() {
    if (!mounted) return;

    try {
      final bottomNav = Provider.of<BottomNavProvider>(context, listen: false);
      final currentCategory = bottomNav.selectedCategory;

      // Only reload if category actually changed
      if (_lastCategory != null && _lastCategory != currentCategory) {
        final vendorType = currentCategory == MainCategory.restaurant ? 1 : 2;
        // Delay to avoid setState during bottom sheet animation
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _loadData(vendorType: vendorType);
            _lastCategory = currentCategory;
          }
        });
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error in _onCategoryChanged', e, stackTrace);
    }
  }

  @override
  void dispose() {
    // Remove category change listener
    try {
      Provider.of<BottomNavProvider>(
        context,
        listen: false,
      ).removeListener(_onCategoryChanged);
    } catch (e) {
      // Context might not be available during dispose
    }
    super.dispose();
  }

  Future<void> _loadCampaigns({int? vendorType}) async {
    try {
      String? cityId;
      String? districtId;

      if (_selectedAddress != null) {
        if (_selectedAddress!['cityId'] != null) {
          cityId = _selectedAddress!['cityId'].toString();
        }
        if (_selectedAddress!['districtId'] != null) {
          districtId = _selectedAddress!['districtId'].toString();
        }
      }

      final campaigns = await _apiService.getCampaigns(
        vendorType: vendorType,
        cityId: cityId,
        districtId: districtId,
      );
      if (mounted) {
        setState(() {
          _banners = campaigns;
        });
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error loading campaigns', e, stackTrace);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Context hazır olduğunda verileri yükle (sadece ilk kez)
    // Adresler yüklendikten sonra verileri yükle - _loadAddresses içinde yapılıyor
    // Burada sadece banner'ları kontrol et
    if (_banners.isEmpty && !_isAddressesLoading) {
      // Banner'lar yüklenmemiş - sadece banner'ları yükle
      final bottomNav = Provider.of<BottomNavProvider>(context, listen: false);
      final vendorType = bottomNav.selectedCategory == MainCategory.restaurant
          ? 1
          : 2;
      _loadCampaigns(vendorType: vendorType);
    }
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final favoritesResult = await _apiService.getFavorites();
      setState(() {
        _favoriteStatus.clear();
        for (final fav in favoritesResult.items) {
          _favoriteStatus[fav.id] = true;
        }
      });
    } catch (e, stackTrace) {
      LoggerService().error('Error loading favorites', e, stackTrace);
    }
  }

  Future<void> _loadAddresses() async {
    try {
      final addresses = await _apiService.getAddresses();
      if (mounted) {
        Map<String, dynamic>? selectedAddress;
        if (addresses.isNotEmpty) {
          try {
            selectedAddress = addresses.firstWhere(
              (addr) => addr['isDefault'] == true,
            );
          } catch (_) {
            selectedAddress = addresses.first;
          }
        }

        setState(() {
          _addresses = addresses;
          _selectedAddress = selectedAddress;
          _isAddressesLoading = false;
        });

        // Adresler yüklendikten sonra verileri yükle (konum bilgisi için gerekli)
        // WidgetsBinding.instance.addPostFrameCallback kullanarak setState'in tamamlanmasını bekle
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadData();
          }
        });
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error loading addresses', e, stackTrace);
      if (mounted) {
        setState(() {
          _isAddressesLoading = false;
        });
        // Hata olsa bile verileri yüklemeyi dene (konum olmadan)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadData();
          }
        });
      }
    }
  }

  /// Public method to refresh addresses from external callers
  void refreshAddresses() {
    _loadAddresses();
  }

  void _showAddressBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return HomeAddressBottomSheet(
          addresses: _addresses,
          selectedAddress: _selectedAddress,
          colorScheme: colorScheme,
          onAddressSelected: (address) {
            setState(() {
              _selectedAddress = address;
            });
            // Don't close bottom sheet, just update selection
          },
          onSetDefault: (address) async {
            await _setDefaultAddress(address);
            if (!context.mounted) return;
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _setDefaultAddress(Map<String, dynamic> address) async {
    try {
      await _apiService.setDefaultAddress(address['id']);
      // Reload addresses to get updated default status
      await _loadAddresses();
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: localizations.defaultAddressUpdated,
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: localizations.addressUpdateFailed(e.toString()),
          isSuccess: false,
        );
      }
    }
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

  // Helper to map icon string to IconData

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        color: colorScheme.primary,
        onRefresh: () async {
          final bottomNav = Provider.of<BottomNavProvider>(
            context,
            listen: false,
          );
          final vendorType =
              bottomNav.selectedCategory == MainCategory.restaurant ? 1 : 2;
          _loadData(vendorType: vendorType);
          await _loadAddresses();
          await _loadFavoriteStatus();
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
                currentLocation: _selectedAddress != null
                    ? _getAddressDisplayText(_selectedAddress!, localizations)
                    : null,
                isAddressesLoading: _isAddressesLoading,
              ),
            ),
            // Spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacingSmall),
            ),
            // Categories Section (only show if vendors and products exist)
            SliverToBoxAdapter(
              child: HomeCategorySection(
                categoriesFuture: _categoriesFuture,
                hasVendors: _hasVendors,
                hasProducts: _hasProducts,
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
            // Picks For You Section (Popular Products) (only show if vendors exist)
            SliverToBoxAdapter(
              child: HomeProductSection(
                productsFuture: _popularProductsFuture,
                favoriteStatus: _favoriteStatus,
                hasVendors: _hasVendors,
                onProductsLoaded: (hasProducts) {
                  setState(() {
                    _hasProducts = hasProducts;
                  });
                },
                onViewAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PopularProductListScreen(),
                    ),
                  );
                },
                onFavoriteToggle: (product) async {
                  final isFavorite = _favoriteStatus[product.id] ?? false;
                  try {
                    if (isFavorite) {
                      await _apiService.removeFromFavorites(product.id);
                      setState(() {
                        _favoriteStatus[product.id] = false;
                      });
                    } else {
                      await _apiService.addToFavorites(product.id);
                      setState(() {
                        _favoriteStatus[product.id] = true;
                      });
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ToastMessage.show(
                      context,
                      message: localizations.favoriteOperationFailed(
                        e.toString(),
                      ),
                      isSuccess: false,
                    );
                  }
                },
              ),
            ),
            // Promotional Banner Section (Campaigns)
            SliverToBoxAdapter(child: HomeCampaignSection(banners: _banners)),
            // Popular Vendors Section
            SliverToBoxAdapter(
              child: HomeVendorSection(
                vendorsFuture: _vendorsFuture,
                onVendorsLoaded: (hasVendors) {
                  setState(() {
                    _hasVendors = hasVendors;
                  });
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
            // Bottom Spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacingLarge),
            ),
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
