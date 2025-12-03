import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/review.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/screens/customer/widgets/persistent_bottom_nav_bar.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _product = widget.product;
      _isLoading = false;
      _checkFavorite();
      _loadReviews();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        body: Container(
          color: Colors.white,
          child: Center(child: Text(l10n.productNotFound)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Product Image Background
          Positioned.fill(
            bottom: MediaQuery.of(context).size.height * 0.5,
            child: _product!.imageUrl != null
                ? Hero(
                    tag: 'product-${_product!.id}',
                    child: Image.network(
                      _product!.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 100),
                        );
                      },
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 100),
                  ),
          ),
          // Top Action Buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  // Favorite, Share and Rating Buttons
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 20,
                            color: _isFavorite ? Colors.red : Colors.black,
                          ),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _toggleFavorite,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.share, size: 20),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _shareProduct();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.star_outline,
                            size: 20,
                            color: AppTheme.primaryOrange,
                          ),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _showReviewDialog(isVendor: true);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Bottom Content Card
          DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Product Name and Rating
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _product!.name,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (_product!.vendorName != null)
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.by(_product!.vendorName!),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Rating
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryOrange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '4.7',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Vendor Section
                        Row(
                          children: [
                            // Vendor Icon
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppTheme.vendorPrimary.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.vendorPrimary.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.store,
                                size: 30,
                                color: AppTheme.vendorPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Vendor Name
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _product!.vendorName ?? 'Talabi',
                                    style: AppTheme.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Description
                        Text(
                          AppLocalizations.of(context)!.description,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _product!.description ??
                              AppLocalizations.of(context)!.noDescription,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                          maxLines: _isDescriptionExpanded ? null : 3,
                          overflow: _isDescriptionExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                        if ((_product!.description?.length ?? 0) > 100)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isDescriptionExpanded =
                                    !_isDescriptionExpanded;
                              });
                            },
                            child: Text(
                              _isDescriptionExpanded
                                  ? AppLocalizations.of(context)!.showLess
                                  : AppLocalizations.of(context)!.readMore,
                              style: TextStyle(color: colorScheme.primary),
                            ),
                          ),
                        const SizedBox(height: 24),
                        // Delivery Info Cards
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.delivery_dining,
                                          color: AppTheme.primaryOrange,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.deliveryTime,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '25 min',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.shopping_cart,
                                          color: AppTheme.primaryOrange,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.deliveryType,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _product!.vendorName ?? 'Talabi',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Reviews Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context)!;
                                return Text(
                                  l10n.reviews(_reviews.length),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                            Builder(
                              builder: (context) {
                                final localizations = AppLocalizations.of(
                                  context,
                                );
                                return TextButton(
                                  onPressed: _hasUserReviewed()
                                      ? null
                                      : _showReviewDialog,
                                  child: Text(
                                    localizations?.writeReview ??
                                        'Write a Review',
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingReviews)
                          Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryOrange,
                            ),
                          )
                        else if (_reviews.isEmpty)
                          Text(
                            AppLocalizations.of(context)!.noReviewsYet,
                            style: const TextStyle(color: Colors.grey),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _reviews.length > 3
                                ? 3
                                : _reviews.length,
                            itemBuilder: (context, index) {
                              final review = _reviews[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
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
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
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
                                              color: AppTheme.primaryOrange,
                                              size: 16,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(review.comment),
                                    const SizedBox(height: 4),
                                    Text(
                                      review.createdAt.toString().split(' ')[0],
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        if (_reviews.length > 3)
                          Center(
                            child: TextButton(
                              onPressed: () {
                                // Show all reviews page
                              },
                              child: Text(
                                AppLocalizations.of(context)!.seeAllReviews,
                              ),
                            ),
                          ),
                        const SizedBox(height: 100), // Bottom padding for FAB
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Price
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        CurrencyFormatter.format(
                          _product!.price,
                          _product!.currency,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Add to Cart Button or Quantity Controls
                    Expanded(child: _buildCartButton(context, cart)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const PersistentBottomNavBar(),
    );
  }

  Widget _buildCartButton(BuildContext context, CartProvider cart) {
    final l10n = AppLocalizations.of(context)!;
    final cartItem = cart.items[_product!.id];
    final quantity = cartItem?.quantity ?? 0;

    if (quantity > 0) {
      // Quantity controls
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Minus button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.remove, color: Colors.grey, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                try {
                  await cart.decreaseQuantity(_product!.id);
                } catch (e) {
                  if (context.mounted) {
                    ToastMessage.show(
                      context,
                      message: l10n.errorWithMessage(e.toString()),
                      isSuccess: false,
                    );
                  }
                }
              },
            ),
          ),
          // Quantity display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$quantity',
              style: AppTheme.poppins(
                color: Colors.grey[800],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Plus button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                try {
                  await cart.increaseQuantity(_product!.id);
                } catch (e) {
                  if (context.mounted) {
                    ToastMessage.show(
                      context,
                      message: l10n.errorWithMessage(e.toString()),
                      isSuccess: false,
                    );
                  }
                }
              },
            ),
          ),
        ],
      );
    } else {
      // Add to Cart Button
      return ElevatedButton(
        onPressed: () {
          cart
              .addItem(_product!, context)
              .then((_) {
                ToastMessage.show(
                  context,
                  message: l10n.productAddedToCart(_product!.name),
                  isSuccess: true,
                );
              })
              .catchError((e) {
                // Error is handled by CartProvider (popup shown)
              });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryOrange,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.primaryOrange, width: 2),
          ),
        ),
        child: Text(
          l10n.addToCart,
          style: AppTheme.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryOrange,
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
