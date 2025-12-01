import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/search_dtos.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/common/product_card.dart';
import 'package:mobile/widgets/common/skeleton_loader.dart';
import 'package:mobile/widgets/common/toast_message.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryName;
  final int? categoryId;

  const CategoryProductsScreen({
    super.key,
    required this.categoryName,
    this.categoryId,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Product>> _productsFuture;
  final Map<int, bool> _favoriteStatus = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadFavoriteStatus();
  }

  void _loadProducts() {
    _productsFuture = _apiService
        .searchProducts(
          ProductSearchRequestDto(
            category: widget.categoryId == null ? widget.categoryName : null,
            categoryId: widget.categoryId,
            pageSize: 50, // Fetch more items for the category page
          ),
        )
        .then(
          (pagedResult) => pagedResult.items.map((e) => e.toProduct()).toList(),
        );
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final favorites = await _apiService.getFavorites();
      setState(() {
        _favoriteStatus.clear();
        for (var fav in favorites) {
          _favoriteStatus[fav['id']] = true;
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
          ToastMessage.show(
            context,
            message: '${product.name} favorilerden çıkarıldı',
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
            message: '${product.name} favorilere eklendi',
            isSuccess: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.show(
          context,
          message: 'Favori işlemi başarısız: $e',
          isSuccess: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: AppTheme.textOnPrimary,
        title: Text(
          widget.categoryName,
          style: AppTheme.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textOnPrimary,
          ),
        ),
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return GridView.builder(
              padding: EdgeInsets.all(AppTheme.spacingMedium),
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
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Hata: ${snapshot.error}',
                style: AppTheme.poppins(color: AppTheme.error),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                  SizedBox(height: AppTheme.spacingMedium),
                  Text(
                    'Bu kategoride henüz ürün yok.',
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
              padding: EdgeInsets.all(AppTheme.spacingSmall),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 0,
                mainAxisSpacing: 8,
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
    );
  }
}
