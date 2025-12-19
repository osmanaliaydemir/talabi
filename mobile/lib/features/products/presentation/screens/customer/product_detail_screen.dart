import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/features/reviews/data/models/review.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/analytics_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/features/cart/presentation/screens/cart_screen.dart';
import 'package:mobile/features/products/presentation/widgets/product_card.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId, this.product});

  final String productId;
  final Product? product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _reviewsSectionKey = GlobalKey();
  Product? _product;
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isDescriptionExpanded = false;
  ProductReviewsSummary? _reviewsSummary;
  bool _isLoadingReviews = false;
  List<Product> _similarProducts = [];
  bool _isLoadingSimilarProducts = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _product = widget.product;
      _isLoading = false;
      _checkFavorite();
      _loadReviews();
      _loadSimilarProducts();
      // Log view_item
      AnalyticsService.logViewItem(product: widget.product!);
    } else {
      _loadProduct();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToReviews() {
    if (_reviewsSectionKey.currentContext != null) {
      Scrollable.ensureVisible(
        _reviewsSectionKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _loadProduct() async {
    try {
      final product = await _apiService.getProduct(widget.productId);
      setState(() {
        _product = product;
        _isLoading = false;
      });
      _checkFavorite();
      _loadReviews();
      _loadSimilarProducts();
      // Log view_item
      AnalyticsService.logViewItem(product: product);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: l10n.productLoadFailed(e.toString()),
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _checkFavorite() async {
    try {
      final favoritesResult = await _apiService.getFavorites();
      setState(() {
        _isFavorite = favoritesResult.items.any((f) => f.id == _product?.id);
      });
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _toggleFavorite() async {
    if (_product == null) return;

    try {
      if (_isFavorite) {
        await _apiService.removeFromFavorites(_product!.id);
      } else {
        await _apiService.addToFavorites(_product!.id);
      }
      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: '${l10n.error}: $e',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _loadReviews() async {
    if (_product == null) return;
    setState(() {
      _isLoadingReviews = true;
    });
    try {
      final summary = await _apiService.getProductReviews(_product!.id);
      setState(() {
        _reviewsSummary = summary;
        _isLoadingReviews = false;
      });
    } catch (e) {
      LoggerService().error('Error loading reviews: $e', e);
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _loadSimilarProducts() async {
    if (_product == null) return;
    setState(() {
      _isLoadingSimilarProducts = true;
    });
    try {
      // API'den aynı kategorideki benzer ürünleri getir
      final similar = await _apiService.getSimilarProducts(
        _product!.id,
        pageSize: 5,
      );

      setState(() {
        _similarProducts = similar;
        _isLoadingSimilarProducts = false;
      });
    } catch (e) {
      LoggerService().error('Error loading similar products: $e', e);
      setState(() {
        _similarProducts = [];
        _isLoadingSimilarProducts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: true);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        body: Container(
          color: AppTheme.backgroundColor,
          child: Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          ),
        ),
      );
    }

    if (_product == null) {
      return Scaffold(
        body: Container(
          color: Colors.white,
          child: Center(child: Text(l10n.productNotFound)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // 1. Scrollable Area (Image + Content)
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Stack(
                children: [
                  // Header Image
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: _product!.imageUrl != null
                        ? OptimizedCachedImage.productImage(
                            imageUrl: _product!.imageUrl!,
                            width: double.infinity,
                            height: 300,
                            borderRadius: BorderRadius.zero,
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.only(top: 220, bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Floating Info Card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _product!.name,
                                          style: AppTheme.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1A1A1A),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 16,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                _product!.vendorName ??
                                                    'Talabi Vendor',
                                                style: AppTheme.poppins(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.map,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(
                                height: 1,
                                color: Color(0xFFEEEEEE),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: _scrollToReviews,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: _buildInfoItem(
                                        icon: Icons.star,
                                        iconColor: Colors.orange,
                                        text: _reviewsSummary != null
                                            ? _reviewsSummary!.averageRating
                                                  .toStringAsFixed(1)
                                            : '0.0',
                                        subText: _reviewsSummary != null
                                            ? '(${_reviewsSummary!.totalRatings}+)'
                                            : '(0+)',
                                      ),
                                    ),
                                  ),
                                  _buildInfoItem(
                                    icon: Icons.access_time_filled,
                                    iconColor: colorScheme.primary,
                                    text: '10 - 20 min',
                                    subText: l10n.deliveryTime,
                                  ),
                                  _buildInfoItem(
                                    icon: Icons.delivery_dining,
                                    iconColor: Colors.green,
                                    text: l10n.talabi,
                                    subText: l10n.delivery,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Description / Recommended Menu Title
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            l10n.description,
                            style: AppTheme.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _product!.description ?? l10n.noDescription,
                            style: AppTheme.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                            maxLines: _isDescriptionExpanded ? null : 3,
                            overflow: _isDescriptionExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                          ),
                        ),
                        if ((_product!.description?.length ?? 0) > 100)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isDescriptionExpanded =
                                      !_isDescriptionExpanded;
                                });
                              },
                              child: Text(
                                _isDescriptionExpanded
                                    ? l10n.showLess
                                    : l10n.readMore,
                                style: AppTheme.poppins(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Similar Products Section
                        if (_isLoadingSimilarProducts)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                              ),
                            ),
                          )
                        else if (_similarProducts.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              l10n.similarProducts,
                              style: AppTheme.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 270,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: _similarProducts.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                // SizedBox ile sarmalayarak width ve height belirt (hit test hatası önlemek için)
                                return SizedBox(
                                  width: 180,
                                  height: 230,
                                  child: ProductCard(
                                    product: _similarProducts[index],
                                    width: 180,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProductDetailScreen(
                                                productId:
                                                    _similarProducts[index].id,
                                                product:
                                                    _similarProducts[index],
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        // Reviews Section
                        Padding(
                          key: _reviewsSectionKey,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Başlık ve Tümü Butonu
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Değerlendirmeler',
                                    style: AppTheme.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  if (_reviewsSummary != null &&
                                      _reviewsSummary!.reviews.isNotEmpty)
                                    TextButton(
                                      onPressed: () {
                                        _showAllReviewsBottomSheet();
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Tümü (${_reviewsSummary!.totalComments})',
                                            style: AppTheme.poppins(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.chevron_right,
                                            size: 18,
                                            color: colorScheme.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_isLoadingReviews)
                                Center(
                                  child: CircularProgressIndicator(
                                    color: colorScheme.primary,
                                  ),
                                )
                              else if (_reviewsSummary == null ||
                                  _reviewsSummary!.reviews.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 0,
                                  ),
                                  child: Text(
                                    l10n.noReviewsYet,
                                    style: AppTheme.poppins(color: Colors.grey),
                                  ),
                                )
                              else ...[
                                // Genel Puan ve İstatistikler
                                Row(
                                  children: [
                                    // Ortalama Puan
                                    Text(
                                      _reviewsSummary!.averageRating
                                          .toStringAsFixed(1),
                                      style: AppTheme.poppins(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Yıldızlar
                                    Row(
                                      children: List.generate(5, (index) {
                                        final rating =
                                            _reviewsSummary!.averageRating;
                                        final fullStars = rating.floor();
                                        final hasHalfStar =
                                            (rating - fullStars) >= 0.5;
                                        if (index < fullStars) {
                                          return const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 24,
                                          );
                                        } else if (index == fullStars &&
                                            hasHalfStar) {
                                          return const Icon(
                                            Icons.star_half,
                                            color: Colors.amber,
                                            size: 24,
                                          );
                                        } else {
                                          return const Icon(
                                            Icons.star_border,
                                            color: Colors.grey,
                                            size: 24,
                                          );
                                        }
                                      }),
                                    ),
                                    const Spacer(),
                                    // Puan ve Yorum Sayısı
                                    Row(
                                      children: [
                                        Text(
                                          '${_reviewsSummary!.totalRatings} puan | ${_reviewsSummary!.totalComments} yorum',
                                          style: AppTheme.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.camera_alt_outlined,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Yorum Listesi (Yatay Slider)
                                SizedBox(
                                  height: 140,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 0,
                                    ),
                                    itemCount:
                                        _reviewsSummary!.reviews.length > 5
                                        ? 5
                                        : _reviewsSummary!.reviews.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (context, index) {
                                      final review =
                                          _reviewsSummary!.reviews[index];
                                      return SizedBox(
                                        width: 300,
                                        child: _buildReviewCard(review, false),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Top Action Buttons
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCircleButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pop(context),
                    ),
                    Row(
                      children: [
                        _buildCircleButton(
                          icon: _isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.black,
                          onTap: _toggleFavorite,
                        ),
                        const SizedBox(width: 12),
                        _buildCircleButton(
                          icon: Icons.share,
                          onTap: _shareProduct,
                        ),
                        const SizedBox(width: 12),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _buildCircleButton(
                              icon: Icons.shopping_cart_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CartScreen(showBackButton: true),
                                  ),
                                );
                              },
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.totalPrice,
                            style: AppTheme.poppins(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(
                              _product!.price,
                              _product!.currency,
                            ),
                            style: AppTheme.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    _buildBottomActionButton(context, cart),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          null, // Removed persistent bottom nav bar to match design focus
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String text,
    required String subText,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 4),
            Text(
              text,
              style: AppTheme.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subText,
          style: AppTheme.poppins(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _buildBottomActionButton(BuildContext context, CartProvider cart) {
    final l10n = AppLocalizations.of(context)!;
    final cartItem = cart.items[_product!.id];
    final quantity = cartItem?.quantity ?? 0;

    if (quantity > 0) {
      final bottomColorScheme = Theme.of(context).colorScheme;
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: bottomColorScheme.primary,
          borderRadius: BorderRadius.circular(100),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.white, size: 20),
              onPressed: () async {
                try {
                  await cart.decreaseQuantity(_product!.id);
                } catch (e) {
                  // Handle error
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            Text(
              '$quantity',
              style: AppTheme.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              onPressed: () async {
                try {
                  await cart.increaseQuantity(_product!.id);
                } catch (e) {
                  // Handle error
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    } else {
      return GestureDetector(
        onTap: () async {
          try {
            await cart.addItem(_product!, context);
            if (context.mounted) {
              // Toast removed as per request
              // ToastMessage.show(
              //   context,
              //   message: l10n.productAddedToCart(_product!.name),
              //   isSuccess: true,
              // );
            }
          } catch (e) {
            // Error is handled globally by ApiService interceptor
            LoggerService().error('Error adding to cart: $e', e);
          }
        },
        child: Builder(
          builder: (context) {
            final addToCartColorScheme = Theme.of(context).colorScheme;
            return Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: addToCartColorScheme.primary,
                borderRadius: BorderRadius.circular(100),
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.addToCart,
                    style: AppTheme.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
  }

  Future<void> _shareProduct() async {
    if (_product == null) return;

    final l10n = AppLocalizations.of(context)!;
    final priceText = CurrencyFormatter.format(
      _product!.price,
      _product!.currency,
    );

    final shareText =
        '${_product!.name}\n'
        '${l10n.price}: $priceText\n'
        '${_product!.description ?? ""}';

    try {
      await Share.share(shareText, subject: _product!.name);
    } catch (e) {
      if (mounted) {
        ToastMessage.show(
          context,
          message: l10n.errorWithMessage(e.toString()),
          isSuccess: false,
        );
      }
    }
  }

  String _formatReviewDate(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _maskUserName(String fullName) {
    if (fullName.isEmpty) return fullName;

    // İsim ve soyisim ayrı ayrı işle
    final parts = fullName.trim().split(' ');
    final maskedParts = parts.map((part) {
      if (part.length <= 4) {
        // 4 veya daha az harf varsa, sadece ilk harfi göster
        return '${part[0]}***';
      } else {
        // İlk 2 ve son 2 harfi göster, ortayı *** ile değiştir
        final firstTwo = part.substring(0, 2);
        final lastTwo = part.substring(part.length - 2);
        return '$firstTwo***$lastTwo';
      }
    }).toList();

    return maskedParts.join(' ');
  }

  void _showAllReviewsBottomSheet() {
    if (_reviewsSummary == null || _reviewsSummary!.reviews.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tüm Değerlendirmeler',
                      style: AppTheme.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Reviews List
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _reviewsSummary!.reviews.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final review = _reviewsSummary!.reviews[index];
                    return _buildReviewCard(review, false);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(Review review, bool isExpanded) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxLines = isExpanded ? null : 2;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Kullanıcı adı, yıldızlar ve tarih
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _maskUserName(review.userFullName),
                      style: AppTheme.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (starIndex) {
                        return Icon(
                          starIndex < review.rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 14,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                _formatReviewDate(review.createdAt),
                style: AppTheme.poppins(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Yorum metni
          Text(
            review.comment,
            style: AppTheme.poppins(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.4,
            ),
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
          ),
          // Devamını Oku butonu (eğer yorum uzunsa)
          if (review.comment.length > 100 && !isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Devamını Oku',
                style: AppTheme.poppins(
                  fontSize: 11,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          // Beden ve Satıcı bilgisi (eğer varsa)
          if (review.vendorName != null) ...[
            const SizedBox(height: 6),
            Text(
              'Satıcı ${review.vendorName}',
              style: AppTheme.poppins(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}
