import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/customer/widgets/product_card.dart';
import 'package:mobile/screens/customer/widgets/shared_header.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ApiService _apiService = ApiService();
  List<Product> _favorites = [];
  bool _isLoading = true;
  int? _lastBottomNavIndex;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favoritesData = await _apiService.getFavorites();
      setState(() {
        _favorites = favoritesData
            .map((data) => Product.fromJson(data))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Favoriler yüklenemedi: $e')));
      }
    }
  }

  Future<void> _removeFromFavorites(String productId) async {
    try {
      await _apiService.removeFromFavorites(productId);
      setState(() {
        _favorites.removeWhere((p) => p.id == productId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Favorilerden kaldırıldı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomNav = Provider.of<BottomNavProvider>(context);

    // Check if favorites screen just became visible
    if (bottomNav.currentIndex == 1 && _lastBottomNavIndex != 1) {
      // Screen just became visible, reload favorites
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFavorites();
      });
    }
    _lastBottomNavIndex = bottomNav.currentIndex;

    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          SharedHeader(
            title: localizations.myFavorites,
            subtitle: '${_favorites.length} ${localizations.favorites}',
            icon: Icons.favorite,
          ),
          // Main Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryOrange,
                    ),
                  )
                : _favorites.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz favori ürününüz yok',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final product = _favorites[index];
                      return ProductCard(
                        product: product,
                        width: null,
                        isFavorite: true,
                        rating: '4.7',
                        ratingCount: '2.3k',
                        onFavoriteTap: () => _removeFromFavorites(product.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
