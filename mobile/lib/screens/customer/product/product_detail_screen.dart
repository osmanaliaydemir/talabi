import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/review.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/analytics_service.dart';
import 'package:mobile/utils/currency_formatter.dart';

import 'package:mobile/screens/customer/cart_screen.dart';
import 'package:mobile/screens/customer/widgets/product_card.dart';
import 'package:mobile/widgets/common/toast_message.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final Product? product;

  const ProductDetailScreen({super.key, required this.productId, this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();
  Product? _product;
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isDescriptionExpanded = false;
  List<Review> _reviews = [];
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
      final favorites = await _apiService.getFavorites();
      setState(() {
        _isFavorite = favorites.any((f) => f['id'].toString() == _product?.id);
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
      final reviews = await _apiService.getProductReviews(_product!.id);
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      print('Error loading reviews: $e');
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
      // Fetch products from the same vendor
      final products = await _apiService.getProducts(_product!.vendorId);

      // Filter products:
      // 1. Exclude current product
      // 2. If categoryId exists, filter by same category
      // 3. Take first 5
      final similar = products
          .where((p) {
            bool isNotCurrent = p.id != _product!.id;
            bool isSameCategory = _product!.categoryId != null
                ? p.categoryId == _product!.categoryId
                : true;
            return isNotCurrent && isSameCategory;
          })
          .take(5)
          .toList();

      setState(() {
        _similarProducts = similar;
        _isLoadingSimilarProducts = false;
      });
    } catch (e) {
      print('Error loading similar products: $e');
      setState(() {
        _isLoadingSimilarProducts = false;
      });
    }
  }

  bool _hasUserReviewed() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    if (userId == null) return false;
    return _reviews.any((review) => review.userId == userId);
  }

  void _showReviewDialog({bool isVendor = false}) {
    // Kullanıcı daha önce review vermişse, bilgilendirme mesajı göster
    if (!isVendor && _hasUserReviewed()) {
      final localizations = AppLocalizations.of(context);
      if (localizations != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(localizations.alreadyReviewedTitle),
            content: Text(localizations.alreadyReviewedMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(localizations.ok),
              ),
            ],
          ),
        );
      }
      return;
    }

    int rating = 5;
    final commentController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final title = isVendor ? l10n.rateVendor : l10n.writeReview;
    // Store parent context before showing dialog
    final rootContext = context;

    showDialog(
      context: rootContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: AppTheme.primaryOrange,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: l10n.shareYourThoughts,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Close dialog first
                    Navigator.of(dialogContext, rootNavigator: true).pop();

                    try {
                      final product = _product;
                      if (product == null) return;
                      await _apiService.createReview(
                        isVendor ? product.vendorId : product.id,
                        isVendor ? 'Vendor' : 'Product',
                        rating,
                        commentController.text,
                      );
                      if (!isVendor) {
                        _loadReviews();
                      }
                      // Use root context for toast message
                      if (mounted) {
                        final rootL10n = AppLocalizations.of(rootContext)!;
                        ToastMessage.show(
                          rootContext,
                          message: isVendor
                              ? rootL10n.vendorReviewSubmitted
                              : rootL10n.productReviewSubmitted,
                          isSuccess: true,
                        );
                      }
                    } catch (e) {
                      // Use root context for toast message
                      if (mounted) {
                        final rootL10n = AppLocalizations.of(rootContext)!;
                        ToastMessage.show(
                          rootContext,
                          message: '${rootL10n.error}: $e',
                          isSuccess: false,
                        );
                      }
                    } finally {
                      commentController.dispose();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: AppTheme.textOnPrimary,
                  ),
                  child: Text(l10n.submit),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: true);
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        body: Container(
          color: AppTheme.backgroundColor,
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryOrange),
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
              child: Stack(
                children: [
                  // Header Image
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: _product!.imageUrl != null
                        ? Image.network(
                            _product!.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                              );
                            },
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
                                color: Colors.black.withOpacity(0.05),
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
                                            const Icon(
                                              Icons.location_on,
                                              size: 16,
                                              color: Color(0xFFCE181B),
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
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFCE181B),
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
                                  _buildInfoItem(
                                    icon: Icons.star,
                                    iconColor: Colors.orange,
                                    text: '4.9',
                                    subText: '(200+)',
                                  ),
                                  _buildInfoItem(
                                    icon: Icons.access_time_filled,
                                    iconColor: const Color(0xFFCE181B),
                                    text: '10 - 20 min',
                                    subText: l10n.deliveryTime,
                                  ),
                                  _buildInfoItem(
                                    icon: Icons.delivery_dining,
                                    iconColor: Colors.green,
                                    text: 'Free',
                                    subText: l10n.deliveryFee,
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
                                  color: AppTheme.primaryOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Reviews Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.reviews(_reviews.length),
                                style: AppTheme.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                              TextButton(
                                onPressed: _hasUserReviewed()
                                    ? null
                                    : _showReviewDialog,
                                child: Text(
                                  l10n.writeReview,
                                  style: AppTheme.poppins(
                                    color: AppTheme.primaryOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_isLoadingReviews)
                          Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryOrange,
                            ),
                          )
                        else if (_reviews.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              l10n.noReviewsYet,
                              style: AppTheme.poppins(color: Colors.grey),
                            ),
                          )
                        else
                          ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _reviews.length > 3
                                ? 3
                                : _reviews.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final review = _reviews[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          review.userFullName,
                                          style: AppTheme.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(5, (
                                            starIndex,
                                          ) {
                                            return Icon(
                                              starIndex < review.rating
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Colors.orange,
                                              size: 14,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      review.comment,
                                      style: AppTheme.poppins(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        // Similar Products Section
                        if (_isLoadingSimilarProducts)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryOrange,
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
                                return ProductCard(
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
                                              product: _similarProducts[index],
                                            ),
                                      ),
                                    );
                                  },
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
                    color: Colors.black.withOpacity(0.05),
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
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFCE181B),
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
              ToastMessage.show(
                context,
                message: l10n.productAddedToCart(_product!.name),
                isSuccess: true,
              );
            }
          } catch (e) {
            // Error is handled globally by ApiService interceptor
            print('Error adding to cart: $e');
          }
        },
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: const Color(0xFFCE181B),
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
}
