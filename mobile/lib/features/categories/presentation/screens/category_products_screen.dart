import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/features/search/data/models/search_dtos.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/features/products/presentation/widgets/product_card.dart';
import 'package:mobile/widgets/skeleton_loader.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';
import 'package:provider/provider.dart';

class CategoryProductsScreen extends StatefulWidget {
  const CategoryProductsScreen({
    super.key,
    required this.categoryName,
    this.categoryId,
    this.imageUrl,
  });

  final String categoryName;
  final String? categoryId;
  final String? imageUrl;

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Product>> _productsFuture;
  final Map<String, bool> _favoriteStatus = {};
  int? _productCount;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadFavoriteStatus();
  }

  void _loadProducts() {
    final bottomNav = Provider.of<BottomNavProvider>(context, listen: false);
    final vendorType = bottomNav.selectedCategory == MainCategory.restaurant
        ? 1
        : 2;
    _productsFuture = _apiService
        .searchProducts(
          ProductSearchRequestDto(
            category: widget.categoryId == null ? widget.categoryName : null,
            categoryId: widget.categoryId,
            vendorType: vendorType,
            pageSize: 50, // Fetch more items for the category page
          ),
        )
        .then((pagedResult) {
          final products = pagedResult.items.map((e) => e.toProduct()).toList();
          if (mounted) {
            setState(() {
              _productCount = products.length;
            });
          }
          return products;
        });
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
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<BottomNavProvider>(
        builder: (context, bottomNav, _) {
          // Kategori değiştiğinde verileri yeniden yükle
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // Note: Intentionally avoiding set state loop, logic handled in _loadProducts check?
              // Actually relying on init state mostly, but if tab changes maybe reload?
              // _loadProducts(); // Removing this from build to avoid infinite loop risk if not careful
            }
          });

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                backgroundColor: colorScheme.primary,
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
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.categoryName,
                    style: AppTheme.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                          ? OptimizedCachedImage.banner(
                              imageUrl: widget.imageUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              borderRadius: BorderRadius.zero,
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.primary.withValues(alpha: 0.8),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.category,
                                size: 64,
                                color: Colors.white.withValues(alpha: 0.5),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localizations.products,
                            style: AppTheme.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (_productCount != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                localizations.productsCount(_productCount!),
                                style: AppTheme.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              FutureBuilder<List<Product>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMedium,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
                    );
                  } else if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          '${localizations.error}: ${snapshot.error}',
                          style: AppTheme.poppins(color: AppTheme.error),
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: AppTheme.textSecondary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingMedium),
                            Text(
                              localizations.noProductsYet,
                              style: AppTheme.poppins(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final products = snapshot.data!;
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMedium,
                      vertical: AppTheme.spacingSmall,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: AppTheme.spacingSmall,
                            mainAxisSpacing: AppTheme.spacingSmall,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = products[index];
                        final isFavorite = _favoriteStatus[product.id] ?? false;
                        return ProductCard(
                          product: product,
                          width: null,
                          isFavorite: isFavorite,
                          rating: '4.7', // Placeholder
                          ratingCount: '2.3k', // Placeholder
                          onFavoriteTap: () => _toggleFavorite(product),
                        );
                      }, childCount: products.length),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
