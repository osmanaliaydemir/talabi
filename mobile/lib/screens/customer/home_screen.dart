import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/vendor.dart';
import 'package:mobile/models/promotional_banner.dart';
import 'package:mobile/screens/customer/product_list_screen.dart';
import 'package:mobile/screens/customer/search_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/common/toast_message.dart';
import 'package:mobile/widgets/common/product_card.dart';
import 'package:mobile/widgets/customer/customer_header.dart';
import 'package:mobile/screens/customer/category_products_screen.dart';
import 'package:mobile/screens/customer/categories_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Vendor>> _vendorsFuture;
  late Future<List<Product>> _popularProductsFuture;
  late Future<List<Map<String, dynamic>>> _categoriesFuture;
  List<dynamic> _addresses = [];
  Map<String, dynamic>? _selectedAddress;
  bool _isLoadingAddresses = false;
  final Map<String, bool> _favoriteStatus =
      {}; // Track favorite status for each product

  // Banner carousel state
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  List<PromotionalBanner> _banners = [];
  late PageController _bannerPageController;

  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController(
      initialPage: 0,
      viewportFraction: 0.90, // Show 90% of current + 10% of next
    );
    _vendorsFuture = _apiService.getVendors();
    _popularProductsFuture = _apiService.getPopularProducts(limit: 8);
    _loadAddresses();
    _loadFavoriteStatus();
    _loadBanners();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    try {
      final locale = AppLocalizations.of(context)?.localeName ?? 'tr';
      final banners = await _apiService.getBanners(language: locale);
      if (mounted) {
        setState(() {
          _banners = banners;
          _currentBannerIndex = 0;
        });
        // Reset page controller to first page
        if (_banners.isNotEmpty) {
          _bannerPageController.jumpToPage(0);
          // Start timer after a short delay to ensure page controller is ready
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _banners.length > 1) {
              _startBannerTimer();
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
      // First change happens after 3 seconds, then continues every 3 seconds
      _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted && _banners.isNotEmpty) {
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
    final locale = AppLocalizations.of(context)?.localeName;
    _categoriesFuture = _apiService.getCategories(language: locale);
    // Only reload banners if they haven't been loaded yet or locale changed
    if (_banners.isEmpty) {
      _loadBanners(); // Reload banners when locale changes
    }
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final favorites = await _apiService.getFavorites();
      setState(() {
        _favoriteStatus.clear();
        for (var fav in favorites) {
          _favoriteStatus[fav['id'].toString()] = true;
        }
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoadingAddresses = true;
    });
    try {
      final addresses = await _apiService.getAddresses();
      setState(() {
        _addresses = addresses;
        // Find default address or use first one
        _selectedAddress = addresses.firstWhere(
          (addr) => addr['isDefault'] == true,
          orElse: () => addresses.isNotEmpty ? addresses.first : null,
        );
        _isLoadingAddresses = false;
      });
    } catch (e) {
      print('Error loading addresses: $e');
      setState(() {
        _isLoadingAddresses = false;
      });
    }
  }

  void _showAddressBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddressBottomSheet(
        addresses: _addresses,
        selectedAddress: _selectedAddress,
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
      ),
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

  // Helper to map icon string to IconData
  IconData? _getIconFromString(String? iconString) {
    if (iconString == null || iconString.isEmpty) return null;

    final iconMap = {
      'restaurant': Icons.restaurant,
      'store': Icons.store,
      'shopping_basket': Icons.shopping_basket,
      'local_drink': Icons.local_drink,
      'cake': Icons.cake,
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

    return iconMap[iconString.toLowerCase()];
  }

  // Helper to map color string to Color
  Color? _getColorFromString(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;

    // Try to parse hex color (e.g., "#FF5722" or "FF5722")
    if (colorString.startsWith('#')) {
      colorString = colorString.substring(1);
    }
    if (colorString.length == 6) {
      try {
        return Color(int.parse('FF$colorString', radix: 16));
      } catch (e) {
        // If parsing fails, try named colors
      }
    }

    // Named color mapping
    final colorMap = {
      'orange': AppTheme.primaryOrange,
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

    return colorMap[colorString.toLowerCase()];
  }

  Widget _buildPromotionalBanner() {
    if (_banners.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
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
                    colors: [AppTheme.lightOrange, AppTheme.darkOrange],
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
                                foregroundColor: AppTheme.primaryOrange,
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
                                  color: AppTheme.primaryOrange,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    // Placeholder for image
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.textOnPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                      ),
                      child: currentBanner.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                              child: Image.network(
                                currentBanner.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.fastfood,
                                    size: 40,
                                    color: AppTheme.textOnPrimary.withValues(
                                      alpha: 0.8,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.fastfood,
                              size: 40,
                              color: AppTheme.textOnPrimary.withValues(
                                alpha: 0.8,
                              ),
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
                        ? AppTheme.primaryOrange
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
  Map<String, dynamic> _getCategoryStyle(Map<String, dynamic> category) {
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
      color = _getColorFromString(colorString);
    }

    // If both icon and color are successfully mapped from API, use them
    if (icon != null && color != null) {
      return {'icon': icon, 'color': color};
    }

    // Fallback to name-based logic if API data is not available or mapping failed
    final name = (category['name'] as String).toLowerCase();

    if (name.contains('yemek') ||
        name.contains('food') ||
        name.contains('طعام')) {
      return {
        'icon': icon ?? Icons.restaurant,
        'color': color ?? AppTheme.primaryOrange,
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
      return {'icon': icon ?? Icons.category, 'color': color ?? Colors.orange};
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Header
          CustomerHeader(
            title: localizations.discover,
            subtitle: 'Find your favorite products',
            leadingIcon: Icons.explore,
            showCart: true,
            showAddress: true,
            selectedAddress: _selectedAddress,
            isLoadingAddress: _isLoadingAddresses,
            onAddressTap: _showAddressBottomSheet,
          ),
          // Main Content
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryOrange,
              onRefresh: () async {
                setState(() {
                  _vendorsFuture = _apiService.getVendors();
                  _popularProductsFuture = _apiService.getPopularProducts(
                    limit: 8,
                  );
                  _categoriesFuture = _apiService.getCategories(
                    language: AppLocalizations.of(context)?.localeName,
                  );
                });
                await _loadAddresses();
                await _loadFavoriteStatus();
                await _loadBanners();
              },
              child: CustomScrollView(
                slivers: [
                  // Search and Filter
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMedium,
                        vertical: AppTheme.spacingSmall,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: AppTheme.inputBoxDecoration()
                                  .copyWith(
                                    border: Border.all(
                                      color: AppTheme.borderColor,
                                      width: 1.0,
                                    ),
                                  ),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: localizations.search,
                                  hintStyle: AppTheme.poppins(
                                    color: AppTheme.textHint,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: AppTheme.textSecondary,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingMedium,
                                    vertical: AppTheme.spacingSmall,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SearchScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: AppTheme.spacingSmall),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryOrange,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.tune,
                                color: AppTheme.textOnPrimary,
                              ),
                              onPressed: () {
                                // Open filter
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Promotional Banner
                  SliverToBoxAdapter(
                    child: _banners.isEmpty
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: EdgeInsets.only(
                              top: AppTheme.spacingSmall,
                              bottom: AppTheme.spacingSmall,
                            ),
                            child: _buildPromotionalBanner(),
                          ),
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
                                    color: AppTheme.primaryOrange,
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
                                    color: AppTheme.primaryOrange,
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
                                  horizontal: AppTheme.spacingSmall,
                                ),
                                itemCount: sortedCategories.length,
                                itemBuilder: (context, index) {
                                  final category = sortedCategories[index];
                                  return _buildCategoryCard(category);
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
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryOrange,
                              ),
                            ),
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
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMedium,
                                vertical: AppTheme.spacingSmall,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    onPressed: () {},
                                    child: Text(
                                      localizations.viewAll,
                                      style: AppTheme.poppins(
                                        color: AppTheme.primaryOrange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 240,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingSmall,
                                ),
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  final product = products[index];
                                  return _buildPicksForYouCard(
                                    context,
                                    product,
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: AppTheme.spacingMedium),
                          ],
                        );
                      },
                    ),
                  ),
                  // Popular Vendors Section
                  SliverToBoxAdapter(
                    child: FutureBuilder<List<Vendor>>(
                      future: _vendorsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryOrange,
                              ),
                            ),
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
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMedium,
                                vertical: AppTheme.spacingSmall,
                              ),
                              child: Text(
                                localizations.popularVendors,
                                style: AppTheme.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 200,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingSmall,
                                ),
                                itemCount: vendors.length,
                                itemBuilder: (context, index) {
                                  final vendor = vendors[index];
                                  return _buildVendorCardHorizontal(
                                    context,
                                    vendor,
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: AppTheme.spacingMedium),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryImage(String? imageUrl, IconData icon, Color color) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Icon(icon, color: color, size: 30);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Image.network(
        imageUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(icon, color: color, size: 30);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                color: color,
                strokeWidth: 2,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final categoryName = category['name'] as String;
    final style = _getCategoryStyle(category);
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
            ),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingSmall),
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
            builder: (context) => ProductListScreen(vendor: vendor),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingSmall),
        child: Container(
          decoration: AppTheme.cardDecoration(),
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
                        ? Image.network(
                            vendor.imageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppTheme.textSecondary.withValues(
                                  alpha: 0.1,
                                ),
                                child: Icon(
                                  Icons.store,
                                  size: 50,
                                  color: AppTheme.textSecondary,
                                ),
                              );
                            },
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
                            color: AppTheme.cardColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
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
              Padding(
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
  final Function(Map<String, dynamic>) onAddressSelected;
  final Function(Map<String, dynamic>) onSetDefault;

  const _AddressBottomSheet({
    required this.addresses,
    required this.selectedAddress,
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
                            ? AppTheme.primaryOrange.withValues(alpha: 0.1)
                            : AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryOrange
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
                                  ? AppTheme.primaryOrange.withValues(
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
                                  ? AppTheme.primaryOrange
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
                                              ? AppTheme.primaryOrange
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
                              color: AppTheme.primaryOrange,
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
                    backgroundColor: AppTheme.primaryOrange,
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
