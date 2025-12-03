import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/vendor.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/customer/widgets/product_card.dart';
import 'package:mobile/widgets/common/skeleton_loader.dart';
import 'package:mobile/screens/customer/widgets/persistent_bottom_nav_bar.dart';
import 'package:mobile/widgets/common/toast_message.dart';

class ProductListScreen extends StatefulWidget {
  final Vendor vendor;

  const ProductListScreen({super.key, required this.vendor});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Product>> _productsFuture;
  final Map<String, bool> _favoriteStatus = {};

  @override
  void initState() {
    super.initState();
    _productsFuture = _apiService.getProducts(widget.vendor.id);
    _loadFavoriteStatus();
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryOrange,
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
            final l10n = AppLocalizations.of(context)!;
            return Center(
              child: Text(
                '${l10n.error}: ${snapshot.error}',
                style: AppTheme.poppins(color: AppTheme.error),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            final l10n = AppLocalizations.of(context)!;
            return Center(
              child: Text(
                l10n.noProductsYet,
                style: AppTheme.poppins(color: AppTheme.textSecondary),
              ),
            );
          }

          final products = snapshot.data!;
          return RefreshIndicator(
            color: AppTheme.primaryOrange,
            onRefresh: () async {
              setState(() {
                _productsFuture = _apiService.getProducts(widget.vendor.id);
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
                  rating: '4.7',
                  ratingCount: '2.3k',
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
