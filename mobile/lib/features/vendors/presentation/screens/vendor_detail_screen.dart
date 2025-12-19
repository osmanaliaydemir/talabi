import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/features/vendors/data/models/vendor.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/features/products/presentation/widgets/product_card.dart';
import 'package:mobile/widgets/skeleton_loader.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/features/cart/presentation/screens/cart_screen.dart';
import 'package:provider/provider.dart';
import 'package:mobile/services/logger_service.dart';

class VendorDetailScreen extends StatefulWidget {
  const VendorDetailScreen({
    super.key,
    this.vendor,
    this.vendorId,
    this.vendorName,
    this.vendorImageUrl,
  }) : assert(vendor != null || (vendorId != null && vendorName != null));

  final Vendor? vendor;
  final String? vendorId;
  final String? vendorName;
  final String? vendorImageUrl;

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  final ApiService _apiService = ApiService();

  // Data
  late Vendor _vendor;
  List<Product> _products = [];
  final Map<String, bool> _favoriteStatus = {};

  // Pagination State
  int _currentPage = 1;
  static const int _pageSize = 6;
  bool _isFirstLoad = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    if (widget.vendor != null) {
      _vendor = widget.vendor!;
    } else {
      // Create a temporary/partial vendor object from available info
      _vendor = Vendor(
        id: widget.vendorId!,
        name: widget.vendorName!,
        imageUrl: widget.vendorImageUrl,
        address: '', // Placeholder as address is required but unknown
        rating: null,
      );
    }

    _loadProducts(isRefresh: true);
    _loadFavoriteStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isFirstLoad = true;
        _currentPage = 1;
        _hasMoreData = true;
        _products.clear();
      });
    }

    try {
      final products = await _apiService.getProducts(
        _vendor.id,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _products = products;
          } else {
            _products.addAll(products);
          }

          _isFirstLoad = false;
          _isLoadingMore = false;

          if (products.length < _pageSize) {
            _hasMoreData = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadProducts(isRefresh: false);
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

  Future<void> _toggleFavorite(Product product) async {
    final isFavorite = _favoriteStatus[product.id] ?? false;
    try {
      if (isFavorite) {
        await _apiService.removeFromFavorites(product.id);
        setState(() {
          _favoriteStatus[product.id] = false;
        });
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ToastMessage.show(
            context,
            message: l10n.removedFromFavorites(product.name),
            isSuccess: true,
          );
        }
      } else {
        await _apiService.addToFavorites(product.id);
        setState(() {
          _favoriteStatus[product.id] = true;
        });
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ToastMessage.show(
            context,
            message: l10n.addedToFavorites(product.name),
            isSuccess: true,
          );
        }
      }
    } catch (e, stackTrace) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: l10n.favoriteOperationFailed(e.toString()),
          isSuccess: false,
        );
      }
      LoggerService().error('Error toggling favorite', e, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final cart = Provider.of<CartProvider>(context, listen: true);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryOrange,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CartScreen(showBackButton: true),
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _vendor.name,
                style: AppTheme.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _vendor.imageUrl != null
                      ? OptimizedCachedImage.banner(
                          imageUrl: _vendor.imageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: BorderRadius.zero,
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.store,
                            size: 64,
                            color: Colors.grey[500],
                          ),
                        ),
                  // Gradient overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_vendor.address.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _vendor.address,
                            style: AppTheme.poppins(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (_vendor.rating != null) ...[
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryOrange.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: AppTheme.primaryOrange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _vendor.rating!.toStringAsFixed(1),
                                  style: AppTheme.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: AppTheme.spacingMedium),
                  Text(
                    localizations.products,
                    style: AppTheme.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isFirstLoad)
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMedium,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: AppTheme.spacingSmall,
                  mainAxisSpacing: AppTheme.spacingSmall,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const ProductSkeletonItem(),
                  childCount: 6,
                ),
              ),
            )
          else if (_products.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  localizations.noProductsYet,
                  style: AppTheme.poppins(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMedium,
                vertical: AppTheme.spacingSmall,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: AppTheme.spacingSmall,
                  mainAxisSpacing: AppTheme.spacingSmall,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = _products[index];
                  final isFavorite = _favoriteStatus[product.id] ?? false;
                  return ProductCard(
                    product: product,
                    width: null,
                    isFavorite: isFavorite,
                    rating:
                        '4.7', // Placeholder as Product doesn't have rating yet
                    ratingCount: '2.3k', // Placeholder
                    onFavoriteTap: () => _toggleFavorite(product),
                  );
                }, childCount: _products.length),
              ),
            ),
          if (_isLoadingMore && !_isFirstLoad)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
