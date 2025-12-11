import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/vendor.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/screens/customer/widgets/product_card.dart';
import 'package:mobile/widgets/skeleton_loader.dart';
import 'package:mobile/screens/customer/widgets/persistent_bottom_nav_bar.dart';
import 'package:mobile/widgets/toast_message.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, required this.vendor});
  final Vendor vendor;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ApiService _apiService = ApiService();

  // Data
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
        widget.vendor.id,
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
    } catch (e) {
      LoggerService().error('Error loading favorites: $e', e);
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
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: l10n.favoriteOperationFailed(e.toString()),
          isSuccess: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: AppTheme.textOnPrimary,
        title: Text(
          widget.vendor.name,
          style: AppTheme.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textOnPrimary,
          ),
        ),
      ),
      bottomNavigationBar: const PersistentBottomNavBar(),
      body: RefreshIndicator(
        color: colorScheme.primary,
        onRefresh: () async {
          await _loadProducts(isRefresh: true);
          await _loadFavoriteStatus();
        },
        child: _isFirstLoad
            ? GridView.builder(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return const ProductSkeletonItem();
                },
              )
            : _products.isEmpty
            ? Center(
                child: Text(
                  AppLocalizations.of(context)!.noProductsYet,
                  style: AppTheme.poppins(color: AppTheme.textSecondary),
                ),
              )
            : GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppTheme.spacingSmall),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 8,
                ),
                cacheExtent: 500.0, // Optimize cache extent
                addAutomaticKeepAlives: false, // Improve performance
                addRepaintBoundaries: true, // Optimize repaints
                itemCount: _products.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _products.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final product = _products[index];
                  final isFavorite = _favoriteStatus[product.id] ?? false;
                  return ProductCard(
                    product: product,
                    width: null, // Full width in grid
                    isFavorite: isFavorite,
                    rating: '4.7',
                    ratingCount: '2.3k',
                    onFavoriteTap: () => _toggleFavorite(product),
                  );
                },
              ),
      ),
    );
  }
}
