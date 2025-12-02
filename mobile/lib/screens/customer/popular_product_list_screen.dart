import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/common/product_card.dart';
import 'package:mobile/widgets/common/skeleton_loader.dart';
import 'package:mobile/widgets/common/toast_message.dart';
import 'package:mobile/widgets/customer/customer_header.dart';

class PopularProductListScreen extends StatefulWidget {
  const PopularProductListScreen({super.key});

  @override
  State<PopularProductListScreen> createState() =>
      _PopularProductListScreenState();
}

class _PopularProductListScreenState extends State<PopularProductListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Product>> _productsFuture;
  final Map<String, bool> _favoriteStatus = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadFavoriteStatus();
  }

  void _loadProducts() {
    // Limitsiz ürün çekmek için limit parametresini çok yüksek bir değer yapıyoruz
    // veya API'den tüm ürünleri çekiyoruz
    _productsFuture = _apiService.getPopularProducts(limit: 1000);
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          CustomerHeader(
            title: localizations.picksForYou,
            subtitle: localizations.products,
            leadingIcon: Icons.star,
            showBackButton: true,
            showCart: true,
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return GridView.builder(
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
                  );
                } else if (snapshot.hasError) {
                  return Center(
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
                          '${localizations.error}: ${snapshot.error}',
                          style: AppTheme.poppins(color: AppTheme.error),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppTheme.spacingMedium),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _loadProducts();
                            });
                          },
                          child: Text(localizations.retry),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_outline,
                          size: 64,
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
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
                  );
                }

                final products = snapshot.data!;
                return RefreshIndicator(
                  color: AppTheme.primaryOrange,
                  onRefresh: () async {
                    setState(() {
                      _loadProducts();
                    });
                    await _productsFuture;
                    await _loadFavoriteStatus();
                  },
                  child: GridView.builder(
                    padding: EdgeInsets.all(AppTheme.spacingMedium),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: AppTheme.spacingSmall,
                          mainAxisSpacing: AppTheme.spacingSmall,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final isFavorite = _favoriteStatus[product.id] ?? false;
                      return ProductCard(
                        product: product,
                        width: null, // Full width in grid
                        isFavorite: isFavorite,
                        rating: '4.7', // Placeholder rating
                        ratingCount: '2.3k', // Placeholder count
                        onFavoriteTap: () => _toggleFavorite(product),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
