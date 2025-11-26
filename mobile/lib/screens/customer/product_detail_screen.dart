import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/review.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/widgets/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ürün yüklenemedi: $e')));
      }
    }
  }

  Future<void> _checkFavorite() async {
    try {
      final favorites = await _apiService.getFavorites();
      setState(() {
        _isFavorite = favorites.any((f) => f['id'] == _product?.id);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
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
    final title = isVendor ? 'Rate Vendor' : 'Write a Review';
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
                          color: Colors.orange,
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
                    decoration: const InputDecoration(
                      hintText: 'Share your thoughts...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
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
                      // Use root context for snackbar
                      if (mounted) {
                        ScaffoldMessenger.of(rootContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${isVendor ? 'Vendor' : 'Product'} review submitted!',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      // Use root context for snackbar
                      if (mounted) {
                        ScaffoldMessenger.of(
                          rootContext,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    } finally {
                      commentController.dispose();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit'),
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
    final cart = Provider.of<CartProvider>(context, listen: false);
    final localizationProvider = Provider.of<LocalizationProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        body: Container(
          color: Colors.white,
          child: Center(child: CircularProgressIndicator(color: Colors.orange)),
        ),
      );
    }

    if (_product == null) {
      return Scaffold(
        body: Container(
          color: Colors.white,
          child: const Center(child: Text('Ürün bulunamadı')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  // Favorite and Share Buttons
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : Colors.black,
                          ),
                          onPressed: _toggleFavorite,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () {
                            // Share functionality
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
                                      'By ${_product!.vendorName}',
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
                                color: Colors.orange,
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
                        // Profile Section
                        Row(
                          children: [
                            // Profile Picture
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey[200],
                              child: Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Name and ID
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _product!.vendorName ?? 'Talabi',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ID: ${_product!.vendorId}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Chat and Phone Buttons
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.grey[700],
                                ),
                                onPressed: () {
                                  // Chat functionality
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.phone,
                                  color: Colors.grey[700],
                                ),
                                onPressed: () {
                                  // Phone functionality
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.star_outline,
                                  color: Colors.orange,
                                ),
                                onPressed: () {
                                  _showReviewDialog(isVendor: true);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _product!.description ?? 'Açıklama bulunmuyor.',
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
                                  ? 'Daha az göster'
                                  : 'Read more',
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
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Delivery Time',
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
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Delivery Type',
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
                            Text(
                              'Reviews (${_reviews.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
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
                          Center(child: CircularProgressIndicator(color: Colors.orange))
                        else if (_reviews.isEmpty)
                          const Text(
                            'No reviews yet. Be the first to review!',
                            style: TextStyle(color: Colors.grey),
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
                                              color: Colors.orange,
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
                              child: const Text('See All Reviews'),
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
                      color: Colors.black.withOpacity(0.1),
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
                          localizationProvider.currency,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Add to Cart Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          cart.addItem(_product!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${_product!.name} sepete eklendi'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.orange, width: 2),
                          ),
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
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
}
