import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/screens/customer/product_detail_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/widgets/toast_message.dart';
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

  Future<void> _removeFromFavorites(int productId) async {
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
    final cart = Provider.of<CartProvider>(context);
    final bottomNav = Provider.of<BottomNavProvider>(context);
    final localizationProvider = Provider.of<LocalizationProvider>(
      context,
      listen: false,
    );

    // Check if favorites screen just became visible
    if (bottomNav.currentIndex == 1 && _lastBottomNavIndex != 1) {
      // Screen just became visible, reload favorites
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFavorites();
      });
    }
    _lastBottomNavIndex = bottomNav.currentIndex;

    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with Geometric Background
          _buildHeader(context, localizations, colorScheme),
          // Main Content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.orange))
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
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final product = _favorites[index];
                      return _buildProductCard(
                        context,
                        product,
                        cart,
                        localizationProvider,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations localizations,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade400,
            Colors.orange.shade600,
            Colors.orange.shade800,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              // Favorite Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Title and Count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localizations.myFavorites,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_favorites.length} ${localizations.favorites}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Product product,
    CartProvider cart,
    LocalizationProvider localizationProvider,
  ) {
    final cartItem = cart.items[product.id];
    final quantity = cartItem?.quantity ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProductDetailScreen(productId: product.id, product: product),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Rating and Favorite
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                children: [
                  product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 50),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 50),
                        ),
                  // Rating Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber[600]),
                          const SizedBox(width: 4),
                          const Text(
                            '4.7',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '(2.3k)',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Favorite Icon
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _removeFromFavorites(product.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 20,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '25 dk • Kolay • ${product.vendorName ?? "Talabi"}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            CurrencyFormatter.format(
                              product.price,
                              localizationProvider.currency,
                            ),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        quantity > 0
                            ? Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Sol: Beyaz arka planlı eksi butonu
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.remove,
                                          color: Colors.grey,
                                          size: 14,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () async {
                                          try {
                                            await cart.decreaseQuantity(
                                              product.id,
                                            );
                                            ToastMessage.show(
                                              context,
                                              message:
                                                  '${product.name} miktarı azaltıldı',
                                              isSuccess: true,
                                            );
                                          } catch (e) {
                                            ToastMessage.show(
                                              context,
                                              message: 'Hata: $e',
                                              isSuccess: false,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    // Orta: Gri arka plan üzerinde sayı
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        '$quantity',
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    // Sağ: Turuncu arka planlı artı butonu
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () async {
                                          try {
                                            await cart.increaseQuantity(
                                              product.id,
                                            );
                                            ToastMessage.show(
                                              context,
                                              message:
                                                  '${product.name} miktarı artırıldı',
                                              isSuccess: true,
                                            );
                                          } catch (e) {
                                            ToastMessage.show(
                                              context,
                                              message: 'Hata: $e',
                                              isSuccess: false,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                width: 35,
                                height: 35,
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.add_shopping_cart,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () async {
                                    try {
                                      await cart.addItem(product);
                                      ToastMessage.show(
                                        context,
                                        message:
                                            '${product.name} sepete eklendi',
                                        isSuccess: true,
                                      );
                                    } catch (e) {
                                      ToastMessage.show(
                                        context,
                                        message: 'Hata: $e',
                                        isSuccess: false,
                                      );
                                    }
                                  },
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
