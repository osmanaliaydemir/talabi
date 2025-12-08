import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/customer/widgets/product_card.dart';
import 'package:mobile/widgets/skeleton_loader.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/screens/customer/widgets/home_header.dart';
import 'package:provider/provider.dart';

class PopularProductListScreen extends StatefulWidget {
  const PopularProductListScreen({super.key});

  @override
  State<PopularProductListScreen> createState() =>
      _PopularProductListScreenState();
}

class _PopularProductListScreenState extends State<PopularProductListScreen> {
  final ApiService _apiService = ApiService();
  final Map<String, bool> _favoriteStatus = {};
  late ScrollController _scrollController;

  // Pagination State
  List<Product> _products = [];
  int _currentPage = 1;
  static const int _pageSize = 10;
  bool _isFirstLoad = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int? _currentVendorType;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bottomNav = Provider.of<BottomNavProvider>(context, listen: true);
    final vendorType = bottomNav.selectedCategory == MainCategory.restaurant
        ? 1
        : 2;

    if (_currentVendorType != vendorType) {
      _currentVendorType = vendorType;
      // Vendor type değiştiğinde sayfayı yenile
      // Ancak ilk açılışta initState zaten çalışıyor, tekrar çağırmamak için kontrol.
      if (!_isFirstLoad) {
        _loadProducts(isRefresh: true);
      }
    }
  }

  Future<void> _loadProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isFirstLoad = true;
        _currentPage = 1;
        _hasMoreData = true;
        _products.clear();
        _hasError = false;
        _errorMessage = null;
      });
    }

    try {
      final bottomNav = Provider.of<BottomNavProvider>(context, listen: false);
      final vendorType = bottomNav.selectedCategory == MainCategory.restaurant
          ? 1
          : 2;
      _currentVendorType = vendorType;

      final products = await _apiService.getPopularProducts(
        page: _currentPage,
        pageSize: _pageSize,
        vendorType: vendorType,
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
          _hasError = true;
          _errorMessage = e.toString();
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
      if (mounted) {
        setState(() {
          _favoriteStatus.clear();
          for (var fav in favoritesResult.items) {
            _favoriteStatus[fav.id] = true;
          }
        });
      }
    } catch (e) {
      print('Error loading favorites: $e');
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
          final localizations = AppLocalizations.of(context)!;
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
          final localizations = AppLocalizations.of(context)!;
          ToastMessage.show(
            context,
            message: localizations.addedToFavorites(product.name),
            isSuccess: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: localizations.favoriteOperationFailed(e.toString()),
          isSuccess: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          HomeHeader(
            title: localizations.picksForYou,
            subtitle: _products.isNotEmpty
                ? localizations.productsCount(_products.length)
                : localizations.products,
            leadingIcon: Icons.star,
            showBackButton: true,
            showCart: true,
          ),
          Expanded(
            child: RefreshIndicator(
              color: colorScheme.primary,
              onRefresh: () async {
                await _loadProducts(isRefresh: true);
                await _loadFavoriteStatus();
              },
              child: _isFirstLoad
                  ? GridView.builder(
                      padding: EdgeInsets.all(AppTheme.spacingMedium),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: AppTheme.spacingSmall,
                            mainAxisSpacing: AppTheme.spacingSmall,
                          ),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        return const ProductSkeletonItem();
                      },
                    )
                  : _hasError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppTheme.error,
                          ),
                          SizedBox(height: AppTheme.spacingMedium),
                          Text(
                            '${localizations.error}: $_errorMessage',
                            style: AppTheme.poppins(color: AppTheme.error),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppTheme.spacingMedium),
                          ElevatedButton(
                            onPressed: () => _loadProducts(isRefresh: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(localizations.retry),
                          ),
                        ],
                      ),
                    )
                  : _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_outline,
                            size: 64,
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingMedium),
                          Text(
                            localizations.noProductsYet,
                            style: AppTheme.poppins(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.all(AppTheme.spacingMedium),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.7,
                                  crossAxisSpacing: AppTheme.spacingSmall,
                                  mainAxisSpacing: 4,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final product = _products[index];
                              final isFavorite =
                                  _favoriteStatus[product.id] ?? false;
                              return ProductCard(
                                product: product,
                                width: null, // Full width in grid
                                isFavorite: isFavorite,
                                rating: '4.7', // Placeholder rating
                                ratingCount: '2.3k', // Placeholder count
                                onFavoriteTap: () => _toggleFavorite(product),
                              );
                            }, childCount: _products.length),
                          ),
                        ),
                        if (_isLoadingMore)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 24.0,
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
