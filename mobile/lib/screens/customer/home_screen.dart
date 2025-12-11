import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/vendor.dart';
import 'package:mobile/models/promotional_banner.dart';

import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/screens/customer/widgets/product_card.dart';
import 'package:mobile/screens/customer/widgets/special_home_header.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';
import 'package:mobile/screens/customer/category/category_products_screen.dart';
import 'package:mobile/screens/customer/category/categories_screen.dart';
import 'package:mobile/screens/customer/product/popular_product_list_screen.dart';
import 'package:mobile/screens/customer/notifications_screen.dart';
import 'package:mobile/widgets/bouncing_circle.dart';
import 'package:mobile/screens/customer/campaigns/campaigns_screen.dart';
import 'package:mobile/screens/customer/vendor/vendor_list_screen.dart';
import 'package:mobile/screens/customer/vendor/vendor_detail_screen.dart';
import 'package:mobile/screens/customer/search_screen.dart';
import 'package:mobile/screens/customer/profile/addresses_screen.dart';
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

  final Map<String, bool> _favoriteStatus =
      {}; // Track favorite status for each product

  // Banner carousel state
  int _currentBannerIndex = 1; // 2. banner'dan başla (index 1)
  Timer? _bannerTimer;
  List<PromotionalBanner> _banners = [];
  late PageController _bannerPageController;

  // Track current category to detect changes
  MainCategory? _lastCategory;

  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController(
      initialPage: 1, // 2. banner'dan başla (index 1)
      viewportFraction: 0.90, // Show 90% of current + 10% of next
    );
    _loadAddresses();
    _loadFavoriteStatus();

    // Listen to category changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bottomNav = Provider.of<BottomNavProvider>(
          context,
          listen: false,
        );
        bottomNav.addListener(_onCategoryChanged);
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

    setState(() {
      _vendorsFuture = _apiService.getVendors(vendorType: vendorType);
      _popularProductsFuture = _apiService.getPopularProducts(
        page: 1,
        pageSize: 8,
        vendorType: vendorType,
      );
      _categoriesFuture = _apiService.getCategories(
        language: locale,
        vendorType: vendorType,
      );
    });
    _loadBanners(vendorType: vendorType);
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
    } catch (e) {
      if (kDebugMode) {
        print('Error in _onCategoryChanged: $e');
      }
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    // Remove category change listener
    try {
      final bottomNav = Provider.of<BottomNavProvider>(context, listen: false);
      bottomNav.removeListener(_onCategoryChanged);
    } catch (e) {
      // Context might not be available during dispose
    }
    super.dispose();
  }

  Future<void> _loadBanners({int? vendorType}) async {
    try {
      // Önce eski timer'ı iptal et
      _bannerTimer?.cancel();
      _bannerTimer = null;

      final locale = AppLocalizations.of(context)?.localeName ?? 'tr';
      final banners = await _apiService.getBanners(
        language: locale,
        vendorType: vendorType,
      );
      if (mounted) {
        setState(() {
          _banners = banners;
          // 2. banner'dan başla (index 1), eğer 3'ten az banner varsa 0'dan başla
          _currentBannerIndex = banners.length >= 3 ? 1 : 0;
        });
        // Reset page controller to second page (index 1)
        if (_banners.isNotEmpty) {
          // Wait for next frame to ensure page controller is ready
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // 2. banner'dan başla (index 1), eğer 3'ten az banner varsa 0'dan başla
              final startIndex = _banners.length >= 3 ? 1 : 0;
              _bannerPageController.jumpToPage(startIndex);
              setState(() {
                _currentBannerIndex = startIndex;
              });
              // Start timer after page controller is ready
              if (_banners.length > 1) {
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (mounted && _banners.length > 1) {
                    _startBannerTimer();
                  }
                });
              }
            }
          });
        }
      }
    } catch (e) {
      print('Error loading banners: $e');
    }
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    if (_banners.length > 1) {
      // Banner'lar 20 saniye ekranda kalacak
      _bannerTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
        if (mounted &&
            _banners.isNotEmpty &&
            _bannerPageController.hasClients) {
          // Use the current page index from the controller to ensure accuracy
          final currentPage =
              _bannerPageController.page?.round() ?? _currentBannerIndex;
          final nextIndex = (currentPage + 1) % _banners.length;
          _bannerPageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          timer.cancel();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Context hazır olduğunda verileri yükle (sadece ilk kez)
    if (_lastCategory == null) {
      final bottomNav = Provider.of<BottomNavProvider>(context, listen: false);
      final currentCategory = bottomNav.selectedCategory;
      final vendorType = currentCategory == MainCategory.restaurant ? 1 : 2;
      _loadData(vendorType: vendorType);
      _lastCategory = currentCategory;
    } else if (_banners.isEmpty) {
      // Banner'lar yüklenmemiş - sadece banner'ları yükle
      final bottomNav = Provider.of<BottomNavProvider>(context, listen: false);
      final vendorType = bottomNav.selectedCategory == MainCategory.restaurant
          ? 1
          : 2;
      _loadBanners(vendorType: vendorType);
    } else if (_banners.length > 1 && _bannerTimer == null) {
      // Ensure timer is started if banners are already loaded
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _banners.length > 1) {
          _startBannerTimer();
        }
      });
    }
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final favoritesResult = await _apiService.getFavorites();
      setState(() {
        _favoriteStatus.clear();
        for (var fav in favoritesResult.items) {
          _favoriteStatus[fav.id] = true;
        }
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> _loadAddresses() async {
    try {
      final addresses = await _apiService.getAddresses();
      if (mounted) {
        setState(() {
          _addresses = addresses;
          // Find default address or use first one
          if (addresses.isNotEmpty) {
            try {
              _selectedAddress = addresses.firstWhere(
                (addr) => addr['isDefault'] == true,
              );
            } catch (_) {
              _selectedAddress = addresses.first;
            }
          } else {
            _selectedAddress = null;
          }
          _isAddressesLoading = false;
        });
      }
    } catch (e) {
      print('Error loading addresses: $e');
      if (mounted) {
        setState(() {
          _isAddressesLoading = false;
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
        return _AddressBottomSheet(
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
  IconData? _getIconFromString(String? iconString) {
    if (iconString == null || iconString.isEmpty) return null;

    // Remove FontAwesome prefixes (fa-solid fa-, fa-regular fa-, etc.)
    String cleanIconString = iconString.toLowerCase();
    if (cleanIconString.contains('fa-')) {
      final parts = cleanIconString.split('fa-');
      if (parts.length > 1) {
        cleanIconString = parts.last.split(' ').last;
      }
    }

    final iconMap = {
      'restaurant': Icons.restaurant,
      'store': Icons.store,
      'shopping_basket': Icons.shopping_basket,
      'local_drink': Icons.local_drink,
      'cake': Icons.cake,
      'cake-candles': Icons.cake,
      'drumstick-bite': Icons.restaurant_menu,
      'burger': Icons.lunch_dining,
      'pizza-slice': Icons.local_pizza,
      'devices': Icons.devices,
      'checkroom': Icons.checkroom,
      'category': Icons.category,
      'fastfood': Icons.fastfood,
      'shopping_cart': Icons.shopping_cart,
      'coffee': Icons.coffee,
      'lunch_dining': Icons.lunch_dining,
      'bakery_dining': Icons.bakery_dining,
      'local_grocery_store': Icons.local_grocery_store,
      'phone_android': Icons.phone_android,
      'computer': Icons.computer,
      'watch': Icons.watch,
      'tshirt': Icons.checkroom,
      'clothing': Icons.checkroom,
      'shoes': Icons.shopping_bag,
      'home': Icons.home,
      'work': Icons.work,
      'fitness_center': Icons.fitness_center,
      'spa': Icons.spa,
      'beach_access': Icons.beach_access,
      'school': Icons.school,
      'book': Icons.book,
      'music_note': Icons.music_note,
      'movie': Icons.movie,
      'sports_soccer': Icons.sports_soccer,
      'pets': Icons.pets,
      'child_care': Icons.child_care,
      'medical_services': Icons.medical_services,
      'car_repair': Icons.car_repair,
      'build': Icons.build,
    };

    return iconMap[cleanIconString] ??
        iconMap[cleanIconString.replaceAll('-', '_')];
  }

  // Helper to map color string to Color
  Color? _getColorFromString(String? colorString, {Color? primaryColor}) {
    if (colorString == null || colorString.isEmpty) return null;

    try {
      // Try to parse hex color (e.g., "#FF5722" or "FF5722")
      String cleanColorString = colorString.trim();
      if (cleanColorString.startsWith('#')) {
        cleanColorString = cleanColorString.substring(1);
      }
      if (cleanColorString.length == 6) {
        try {
          return Color(int.parse('FF$cleanColorString', radix: 16));
        } catch (e) {
          // If parsing fails, try named colors
        }
      }

      // Named color mapping
      final colorMap = {
        'orange': primaryColor ?? AppTheme.primaryOrange,
        'blue': Colors.blue,
        'green': Colors.green,
        'purple': Colors.purple,
        'pink': Colors.pink,
        'indigo': Colors.indigo,
        'teal': Colors.teal,
        'red': Colors.red,
        'amber': Colors.amber,
        'cyan': Colors.cyan,
        'deepOrange': Colors.deepOrange,
        'deepPurple': Colors.deepPurple,
        'lightBlue': Colors.lightBlue,
        'lightGreen': Colors.lightGreen,
        'lime': Colors.lime,
        'yellow': Colors.yellow,
        'brown': Colors.brown,
        'grey': Colors.grey,
        'gray': Colors.grey,
      };

      return colorMap[cleanColorString.toLowerCase()];
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing color: $colorString - $e');
      }
      return null;
    }
  }

  Widget _buildPromotionalBanner({required ColorScheme colorScheme}) {
    if (_banners.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _bannerPageController,
            itemCount: _banners.length,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
              _startBannerTimer(); // Reset timer on manual swipe
            },
            itemBuilder: (context, index) {
              final currentBanner = _banners[index];
              // Bottom navigation menu renklerini kullan
              // selectedItemColor: primaryOrange, unselectedItemColor: Colors.grey
              // Use header background color for all banners
              final gradientColors = [colorScheme.primary, colorScheme.primary];

              // Her banner için farklı icon
              final List<IconData> bannerIcons = [
                Icons.local_offer,
                Icons.star,
                Icons.shopping_bag,
                Icons.discount,
                Icons.card_giftcard,
                Icons.celebration,
                Icons.percent,
                Icons.flash_on,
                Icons.trending_up,
                Icons.favorite,
              ];
              final iconIndex = index % bannerIcons.length;
              final bannerIcon = bannerIcons[iconIndex];

              return Container(
                margin: EdgeInsets.only(
                  left: AppTheme.spacingXSmall,
                  right: AppTheme.spacingXSmall,
                  top: AppTheme.spacingXSmall,
                  bottom: AppTheme.spacingXSmall,
                ),
                padding: EdgeInsets.only(
                  left: AppTheme.spacingMedium,
                  right: AppTheme.spacingMedium,
                  top: AppTheme.spacingMedium,
                  bottom: AppTheme.spacingMedium,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              currentBanner.title,
                              style: AppTheme.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textOnPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 6),
                          Flexible(
                            child: Text(
                              currentBanner.subtitle,
                              style: AppTheme.poppins(
                                fontSize: 13,
                                color: AppTheme.textOnPrimary.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (currentBanner.buttonText != null) ...[
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                // Handle button action
                                if (currentBanner.buttonAction == 'order') {
                                  // Navigate to order/checkout
                                } else if (currentBanner.buttonAction ==
                                    'discover') {
                                  // Navigate to discover/search
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.cardColor,
                                foregroundColor: colorScheme.primary,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                minimumSize: Size(0, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSmall,
                                  ),
                                ),
                              ),
                              child: Text(
                                currentBanner.buttonText!,
                                style: AppTheme.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    // Icon container - her banner için farklı icon
                    // Icon container - her banner için farklı icon
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            right: -18,
                            bottom: -35,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                BouncingCircle(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                if (currentBanner.imageUrl != null)
                                  ClipOval(
                                    child: CachedNetworkImageWidget(
                                      imageUrl: currentBanner.imageUrl!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      maxWidth: 200,
                                      maxHeight: 200,
                                      errorWidget: Icon(
                                        bannerIcon,
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                else
                                  Icon(
                                    bannerIcon,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Page indicators
        if (_banners.length > 1)
          Padding(
            padding: EdgeInsets.only(
              top: AppTheme.spacingSmall,
              left: AppTheme.spacingMedium,
              right: AppTheme.spacingMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _banners.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentBannerIndex == index
                        ? colorScheme.primary
                        : AppTheme.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Helper to get category icon and color
  Map<String, dynamic> _getCategoryStyle(
    Map<String, dynamic> category, {
    Color? primaryColor,
  }) {
    // Try to use API-provided icon and color first
    final iconString = category['icon'] as String?;
    final colorString = category['color'] as String?;

    IconData? icon;
    Color? color;

    // Map icon string to IconData if provided
    if (iconString != null && iconString.isNotEmpty) {
      icon = _getIconFromString(iconString);
    }

    // Map color string to Color if provided
    if (colorString != null && colorString.isNotEmpty) {
      color = _getColorFromString(colorString, primaryColor: primaryColor);
    }

    // If both icon and color are successfully mapped from API, use them
    if (icon != null && color != null) {
      return {'icon': icon, 'color': color};
    }

    // Fallback to name-based logic if API data is not available or mapping failed
    final name = (category['name'] as String? ?? '').toLowerCase();
    final defaultPrimary = primaryColor ?? AppTheme.primaryOrange;

    if (name.contains('yemek') ||
        name.contains('food') ||
        name.contains('طعام')) {
      return {
        'icon': icon ?? Icons.restaurant,
        'color': color ?? defaultPrimary,
      };
    } else if (name.contains('mağaza') ||
        name.contains('store') ||
        name.contains('متاجر')) {
      return {'icon': icon ?? Icons.store, 'color': color ?? Colors.blue};
    } else if (name.contains('market') ||
        name.contains('grocery') ||
        name.contains('بقالة')) {
      return {
        'icon': icon ?? Icons.shopping_basket,
        'color': color ?? Colors.green,
      };
    } else if (name.contains('içecek') ||
        name.contains('drink') ||
        name.contains('مشروبات')) {
      return {
        'icon': icon ?? Icons.local_drink,
        'color': color ?? Colors.purple,
      };
    } else if (name.contains('tatlı') ||
        name.contains('dessert') ||
        name.contains('حلويات')) {
      return {'icon': icon ?? Icons.cake, 'color': color ?? Colors.pink};
    } else if (name.contains('elektronik') ||
        name.contains('electronic') ||
        name.contains('إلكترونيات')) {
      return {'icon': icon ?? Icons.devices, 'color': color ?? Colors.indigo};
    } else if (name.contains('giyim') ||
        name.contains('clothing') ||
        name.contains('ملابس')) {
      return {'icon': icon ?? Icons.checkroom, 'color': color ?? Colors.teal};
    } else {
      return {'icon': icon ?? Icons.category, 'color': color ?? defaultPrimary};
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<BottomNavProvider>(
      builder: (context, bottomNav, _) {
        // Consumer sadece renkleri güncellemek için kullanılıyor
        // Veri yükleme didChangeDependencies'de yapılıyor
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
                        MaterialPageRoute(builder: (context) => SearchScreen()),
                      );
                    },
                    currentLocation: _selectedAddress != null
                        ? _getAddressDisplayText(
                            _selectedAddress!,
                            localizations,
                          )
                        : null,
                    isAddressesLoading: _isAddressesLoading,
                  ),
                ),
                // Spacing
                SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spacingSmall),
                ),
                // Categories Section
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMedium,
                          vertical: AppTheme.spacingSmall,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              localizations.categories,
                              style: AppTheme.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CategoriesScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                localizations.viewAll,
                                style: AppTheme.poppins(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 100,
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: _categoriesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: colorScheme.primary,
                                ),
                              );
                            }

                            if (snapshot.hasError ||
                                !snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return Center(
                                child: Text(
                                  localizations.categoryNotFound,
                                  style: AppTheme.poppins(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              );
                            }

                            final categories = snapshot.data!;
                            // Sort by displayOrder if available, then by name
                            final sortedCategories =
                                List<Map<String, dynamic>>.from(categories)
                                  ..sort((a, b) {
                                    final orderA =
                                        a['displayOrder'] as int? ?? 999;
                                    final orderB =
                                        b['displayOrder'] as int? ?? 999;
                                    if (orderA != orderB) {
                                      return orderA.compareTo(orderB);
                                    }
                                    final nameA = (a['name'] as String)
                                        .toLowerCase();
                                    final nameB = (b['name'] as String)
                                        .toLowerCase();
                                    return nameA.compareTo(nameB);
                                  });
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMedium,
                              ),
                              cacheExtent:
                                  200.0, // Optimize cache extent for horizontal list
                              addRepaintBoundaries: true, // Optimize repaints
                              itemCount: sortedCategories.length,
                              itemBuilder: (context, index) {
                                final category = sortedCategories[index];
                                return _buildCategoryCard(
                                  category,
                                  colorScheme: colorScheme,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Picks For You Section (Popular Products)
                SliverToBoxAdapter(
                  child: FutureBuilder<List<Product>>(
                    future: _popularProductsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Column(
                          children: [
                            SizedBox(height: AppTheme.spacingSmall),
                            SizedBox(
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      if (snapshot.hasError || !snapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final products = snapshot.data!;
                      if (products.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: AppTheme.spacingSmall),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMedium,
                              vertical: AppTheme.spacingSmall,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  localizations.picksForYou,
                                  style: AppTheme.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PopularProductListScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    localizations.viewAll,
                                    style: AppTheme.poppins(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 220,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingSmall,
                              ),
                              cacheExtent:
                                  200.0, // Optimize cache extent for horizontal list
                              addRepaintBoundaries: true, // Optimize repaints
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return RepaintBoundary(
                                  child: _buildPicksForYouCard(
                                    context,
                                    product,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Promotional Banner Section (Campaigns)
                SliverToBoxAdapter(
                  child: _banners.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMedium,
                                vertical: 0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    localizations.campaigns,
                                    style: AppTheme.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CampaignsScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      localizations.viewAll,
                                      style: AppTheme.poppins(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(
                                left: AppTheme.spacingSmall,
                                right: AppTheme.spacingSmall,
                                bottom: AppTheme.spacingMedium,
                              ),
                              child: _buildPromotionalBanner(
                                colorScheme: colorScheme,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                // Popular Vendors Section
                SliverToBoxAdapter(
                  child: FutureBuilder<List<Vendor>>(
                    future: _vendorsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Column(
                          children: [
                            SizedBox(height: AppTheme.spacingSmall),
                            SizedBox(
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      if (snapshot.hasError || !snapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final vendors = snapshot.data!;
                      if (vendors.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: AppTheme.spacingSmall),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMedium,
                              vertical: AppTheme.spacingSmall,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  localizations.popularVendors,
                                  style: AppTheme.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const VendorListScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    localizations.viewAll,
                                    style: AppTheme.poppins(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingSmall,
                              ),
                              cacheExtent:
                                  200.0, // Optimize cache extent for horizontal list
                              addRepaintBoundaries: true, // Optimize repaints
                              itemCount: vendors.length,
                              itemBuilder: (context, index) {
                                final vendor = vendors[index];
                                return RepaintBoundary(
                                  child: _buildVendorCardHorizontal(
                                    context,
                                    vendor,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Bottom Spacing
                SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spacingLarge),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryImage(String? imageUrl, IconData icon, Color color) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Icon(icon, color: color, size: 30);
    }

    return CachedNetworkImageWidget(
      imageUrl: imageUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      maxWidth: 150,
      maxHeight: 150,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      errorWidget: Icon(icon, color: color, size: 30),
      placeholder: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: color, strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    Map<String, dynamic> category, {
    required ColorScheme colorScheme,
  }) {
    final categoryName = category['name'] as String;
    final style = _getCategoryStyle(
      category,
      primaryColor: colorScheme.primary,
    );
    final icon = style['icon'] as IconData;
    final color = style['color'] as Color;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryProductsScreen(
              categoryName: categoryName,
              categoryId: category['id']?.toString(),
              imageUrl: category['imageUrl']?.toString(),
            ),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: EdgeInsets.symmetric(horizontal: AppTheme.spacing1DotZero),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: _buildCategoryImage(
                category['imageUrl']?.toString(),
                icon,
                color,
              ),
            ),
            SizedBox(height: AppTheme.spacingSmall),
            Text(
              categoryName,
              style: AppTheme.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPicksForYouCard(BuildContext context, Product product) {
    final isFavorite = _favoriteStatus[product.id] ?? false;
    final localizations = AppLocalizations.of(context)!;

    return ProductCard(
      product: product,
      width: 200,
      isFavorite: isFavorite,
      rating: '4.7',
      ratingCount: '2.3k',
      onFavoriteTap: () async {
        try {
          if (isFavorite) {
            await _apiService.removeFromFavorites(product.id);
            setState(() {
              _favoriteStatus[product.id] = false;
            });
            if (mounted) {
              ToastMessage.show(
                context,
                message: localizations.removedFromFavorites(product.name),
                isSuccess: true,
              );
            }
          } else {
            await _apiService.addToFavorites(product.id);
            setState(() {
              _favoriteStatus[product.id] = true;
            });
            if (mounted) {
              ToastMessage.show(
                context,
                message: localizations.addedToFavorites(product.name),
                isSuccess: true,
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ToastMessage.show(
              context,
              message: localizations.favoriteOperationFailed(e.toString()),
              isSuccess: false,
            );
          }
        }
      },
    );
  }

  Widget _buildVendorCardHorizontal(BuildContext context, Vendor vendor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VendorDetailScreen(vendor: vendor),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingSmall),
        child: Container(
          decoration: AppTheme.cardDecoration(
            color: Theme.of(context).cardColor,
            context: context,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: Stack(
                  children: [
                    vendor.imageUrl != null
                        ? OptimizedCachedImage.vendorLogo(
                            imageUrl: vendor.imageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            borderRadius: BorderRadius.zero,
                          )
                        : Container(
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.1,
                            ),
                            child: Icon(
                              Icons.store,
                              size: 50,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                    if (vendor.rating != null && vendor.rating! > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber[600],
                              ),
                              SizedBox(width: 4),
                              Text(
                                vendor.rating!.toStringAsFixed(1),
                                style: AppTheme.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                color: Theme.of(context).cardColor,
                padding: EdgeInsets.all(AppTheme.spacingSmall),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      style: AppTheme.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    if (vendor.address.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              vendor.address,
                              style: AppTheme.poppins(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (vendor.distanceInKm != null) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.navigation,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${vendor.distanceInKm!.toStringAsFixed(1)} km',
                            style: AppTheme.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Address Bottom Sheet Widget
class _AddressBottomSheet extends StatefulWidget {
  final List<dynamic> addresses;
  final Map<String, dynamic>? selectedAddress;
  final ColorScheme colorScheme;
  final Function(Map<String, dynamic>) onAddressSelected;
  final Function(Map<String, dynamic>) onSetDefault;

  const _AddressBottomSheet({
    required this.addresses,
    required this.selectedAddress,
    required this.colorScheme,
    required this.onAddressSelected,
    required this.onSetDefault,
  });

  @override
  State<_AddressBottomSheet> createState() => _AddressBottomSheetState();
}

class _AddressBottomSheetState extends State<_AddressBottomSheet> {
  Map<String, dynamic>? _tempSelectedAddress;

  @override
  void initState() {
    super.initState();
    _tempSelectedAddress = widget.selectedAddress;
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusLarge),
          topRight: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMedium,
              vertical: AppTheme.spacingMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.selectAddress,
                  style: AppTheme.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Address List
          if (widget.addresses.isEmpty)
            Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.location_off,
                    size: 64,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(height: AppTheme.spacingMedium),
                  Text(
                    localizations.noAddressesYet,
                    style: AppTheme.poppins(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingLarge),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddressesScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.colorScheme.primary,
                      foregroundColor: AppTheme.textOnPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLarge,
                        vertical: AppTheme.spacingMedium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                      ),
                    ),
                    child: Text(
                      localizations.addAddress,
                      style: AppTheme.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textOnPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.addresses.length,
                itemBuilder: (context, index) {
                  final address = widget.addresses[index];
                  final isSelected =
                      _tempSelectedAddress?['id'] == address['id'];
                  final isDefault = address['isDefault'] == true;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _tempSelectedAddress = address;
                      });
                      // Update parent state but don't close bottom sheet
                      widget.onAddressSelected(address);
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMedium,
                        vertical: AppTheme.spacingSmall,
                      ),
                      padding: EdgeInsets.all(AppTheme.spacingMedium),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? widget.colorScheme.primary.withValues(alpha: 0.1)
                            : AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? widget.colorScheme.primary
                              : AppTheme.borderColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Address Icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? widget.colorScheme.primary.withValues(
                                      alpha: 0.2,
                                    )
                                  : AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: isSelected
                                  ? widget.colorScheme.primary
                                  : AppTheme.textSecondary,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: AppTheme.spacingMedium),
                          // Address Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        address['title'] ??
                                            localizations.address,
                                        style: AppTheme.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? widget.colorScheme.primary
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isDefault)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.success,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          localizations.defaultLabel,
                                          style: AppTheme.poppins(
                                            color: AppTheme.textOnPrimary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _getAddressDisplayText(
                                    address,
                                    localizations,
                                  ),
                                  style: AppTheme.poppins(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                if (address['fullAddress'] != null &&
                                    address['fullAddress']
                                        .toString()
                                        .isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      address['fullAddress'].toString(),
                                      style: AppTheme.poppins(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary
                                            .withValues(alpha: 0.8),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Check Icon
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: widget.colorScheme.primary,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          // Set Default Button
          if (widget.addresses.isNotEmpty && _tempSelectedAddress != null)
            Padding(
              padding: EdgeInsets.all(AppTheme.spacingMedium),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSetDefault(_tempSelectedAddress!);
                    // Navigator.pop is called inside onSetDefault callback
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: AppTheme.textOnPrimary,
                    padding: EdgeInsets.symmetric(
                      vertical: AppTheme.spacingMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                    ),
                  ),
                  child: Text(
                    localizations.setAsDefault,
                    style: AppTheme.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textOnPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final double collapsedHeight;
  final double paddingTop;
  final VoidCallback onNotificationTap;
  final VoidCallback onLocationTap;
  final String? currentLocation;
  final VoidCallback onSearchTap;
  final bool isAddressesLoading;

  _HomeHeaderDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.paddingTop,
    required this.onNotificationTap,
    required this.onLocationTap,
    required this.currentLocation,
    required this.onSearchTap,
    required this.isAddressesLoading,
  });

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
                    color: Colors.black.withOpacity(0.1),
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
                            color: Colors.white.withOpacity(0.2),
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
