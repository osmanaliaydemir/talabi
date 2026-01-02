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
import 'package:mobile/widgets/skeleton_loader.dart';
import 'package:mobile/widgets/custom_confirmation_dialog.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.product,
    this.heroTag,
  });

  final String productId;
  final Product? product;
  final String? heroTag;

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
      if (!mounted || !context.mounted) return;
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
      if (!mounted || !context.mounted) return;
      setState(() {
        _isLoading = false;
      });
      final l10n = AppLocalizations.of(context)!;
      ToastMessage.show(
        context,
        message: l10n.productLoadFailed(e.toString()),
        isSuccess: false,
      );
    }
  }

  Future<void> _checkFavorite() async {
    try {
      final favoritesResult = await _apiService.getFavorites();
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ToastMessage.show(
        context,
        message: '${l10n.error}: $e',
        isSuccess: false,
      );
    }
  }

  Future<void> _loadReviews() async {
    if (_product == null) return;
    setState(() {
      _isLoadingReviews = true;
    });
    try {
      final summary = await _apiService.getProductReviews(_product!.id);
      if (!mounted || !context.mounted) return;
      setState(() {
        _reviewsSummary = summary;
        _isLoadingReviews = false;
      });
    } catch (e) {
      // 404 is expected for products without reviews, treated as empty
      if (!mounted || !context.mounted) return;
      setState(() {
        _isLoadingReviews = false;
        _reviewsSummary = ProductReviewsSummary(
          averageRating: _product?.rating ?? 0.0,
          totalRatings: _product?.reviewCount ?? 0,
          totalComments: 0,
          reviews: [],
        );
      });
      // Only log non-404 errors to avoid noise
      if (!e.toString().contains('404')) {
        LoggerService().error('Error loading reviews: $e', e);
      }
    }
  }

  Future<void> _handleWriteReview() async {
    if (_product == null) return;

    final l10n = AppLocalizations.of(context)!;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final canReview = await _apiService.canReviewProduct(_product!.id);
      if (!mounted || !context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (canReview) {
        _showReviewPopup();
      } else {
        showDialog(
          context: context,
          builder: (context) => CustomConfirmationDialog(
            title: l10n.error,
            message: l10n.mustOrderToReview,
            confirmText: l10n.ok,
            onConfirm: () => Navigator.pop(context),
            icon: Icons.info_outline,
            iconColor: AppTheme.primaryOrange,
            confirmButtonColor: AppTheme.primaryOrange,
          ),
        );
      }
    } catch (e) {
      if (!mounted || !context.mounted) return;
      Navigator.pop(context);
      ToastMessage.show(context, message: e.toString(), isSuccess: false);
    }
  }

  void _showReviewPopup() {
    final l10n = AppLocalizations.of(context)!;
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: AppTheme.primaryOrange,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.writeAReview,
                  style: AppTheme.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => setDialogState(() => rating = index + 1),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: l10n.comment,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: AppTheme.poppins(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await _apiService.createReview(
                              _product!.id,
                              'Product',
                              rating,
                              commentController.text,
                            );
                            if (!mounted || !context.mounted) return;
                            Navigator.pop(context);
                            _loadReviews();
                            ToastMessage.show(
                              context,
                              message: l10n.reviewCreatedSuccessfully,
                              isSuccess: true,
                            );
                          } catch (e) {
                            if (!mounted || !context.mounted) return;
                            ToastMessage.show(
                              context,
                              message: e.toString(),
                              isSuccess: false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.send,
                          style: AppTheme.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // Header Image Skeleton
          SkeletonLoader(width: double.infinity, height: 300, borderRadius: 0),

          // Content Skeleton
          Padding(
            padding: EdgeInsets.only(top: 220),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Floating Card
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0D000000), // 5% opacity black
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SkeletonLoader(width: 150, height: 24),
                                  SizedBox(height: 8),
                                  SkeletonLoader(width: 100, height: 16),
                                ],
                              ),
                              SkeletonLoader(
                                width: 40,
                                height: 40,
                                borderRadius: 20,
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          SkeletonLoader(width: double.infinity, height: 1),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SkeletonLoader(width: 60, height: 20),
                              SkeletonLoader(width: 80, height: 20),
                              SkeletonLoader(width: 60, height: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Description Skeleton
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(width: 120, height: 20),
                      SizedBox(height: 12),
                      SkeletonLoader(width: double.infinity, height: 14),
                      SizedBox(height: 8),
                      SkeletonLoader(width: double.infinity, height: 14),
                      SizedBox(height: 8),
                      SkeletonLoader(width: 200, height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Back Button
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Icon(Icons.arrow_back)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

      if (!mounted || !context.mounted) return;
      setState(() {
        _similarProducts = similar;
        _isLoadingSimilarProducts = false;
      });
    } catch (e) {
      if (!mounted || !context.mounted) return;
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
      return _buildSkeleton(context);
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
                        ? Hero(
                            tag:
                                widget.heroTag ??
                                'product_image_${_product!.id}',
                            child: OptimizedCachedImage.productImage(
                              imageUrl: _product!.imageUrl!,
                              width: double.infinity,
                              height: 300,
                              borderRadius: BorderRadius.zero,
                            ),
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
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _scrollToReviews,
                                      child: Semantics(
                                        label:
                                            '${(_reviewsSummary?.averageRating ?? _product?.rating ?? 0.0).toStringAsFixed(1)} ${l10n.yildiz}, ${_reviewsSummary?.totalRatings ?? _product?.reviewCount ?? 0} ${l10n.degerlendirme}',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: _buildInfoItem(
                                            icon: Icons.star,
                                            iconColor: Colors.orange,
                                            text:
                                                ((_reviewsSummary?.averageRating ??
                                                                0.0) >
                                                            0
                                                        ? _reviewsSummary!
                                                              .averageRating
                                                        : (_product?.rating ??
                                                              0.0))
                                                    .toStringAsFixed(1),
                                            subText:
                                                '(${(_reviewsSummary?.totalRatings ?? 0) > 0 ? _reviewsSummary!.totalRatings : (_product?.reviewCount ?? 0)}+)',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Semantics(
                                      label:
                                          '${l10n.deliveryTime}: 10 - 20 min',
                                      child: _buildInfoItem(
                                        icon: Icons.access_time_filled,
                                        iconColor: colorScheme.primary,
                                        text: '10 - 20 min',
                                        subText: l10n.deliveryTime,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Semantics(
                                      label: '${l10n.delivery}: ${l10n.talabi}',
                                      child: _buildInfoItem(
                                        icon: Icons.delivery_dining,
                                        iconColor: Colors.green,
                                        text: l10n.talabi,
                                        subText: l10n.delivery,
                                      ),
                                    ),
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
                                    heroTagPrefix: 'similar_product_',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetailScreen(
                                            productId:
                                                _similarProducts[index].id,
                                            product: _similarProducts[index],
                                            heroTag:
                                                'similar_product_${_similarProducts[index].id}',
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
                                    l10n.reviewsTitle,
                                    style: AppTheme.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: _handleWriteReview,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      (_reviewsSummary == null ||
                                              _reviewsSummary!.reviews.isEmpty)
                                          ? l10n.beTheFirstToReview
                                          : l10n.writeAReview,
                                      style: AppTheme.poppins(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (_reviewsSummary != null &&
                                      _reviewsSummary!.reviews.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 1,
                                      height: 12,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: _showAllReviewsBottomSheet,
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
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Icon(
                                            Icons.chevron_right,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
                                  padding: const EdgeInsets.only(
                                    bottom: 40,
                                    top: 20,
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.star_border,
                                            size: 32,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          l10n.noReviewsYet,
                                          style: AppTheme.poppins(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
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
                    Semantics(
                      label: l10n.back,
                      button: true,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, size: 20),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Semantics(
                          label: _isFavorite
                              ? l10n.favorilerdenCikar
                              : l10n.favorilereEkle,
                          button: true,
                          child: GestureDetector(
                            onTap: _toggleFavorite,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isFavorite ? Colors.red : Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Semantics(
                          label: l10n.share,
                          button: true,
                          child: GestureDetector(
                            onTap: _shareProduct,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.share, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Semantics(
                              label: l10n.cart,
                              button: true,
                              child: _buildCircleButton(
                                icon: Icons.shopping_cart_outlined,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CartScreen(
                                        showBackButton: true,
                                      ),
                                    ),
                                  );
                                },
                              ),
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
                      child: Semantics(
                        label:
                            '${l10n.totalPrice}: ${CurrencyFormatter.format(_product!.price, _product!.currency)}',
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: AppTheme.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subText,
          style: AppTheme.poppins(fontSize: 12, color: Colors.grey[500]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
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
            Semantics(
              label: l10n.adediAzalt,
              button: true,
              child: IconButton(
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
            ),
            const SizedBox(width: 16),
            Semantics(
              label: '${l10n.miktar}: $quantity',
              child: Text(
                '$quantity',
                style: AppTheme.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Semantics(
              label: l10n.adediArtir,
              button: true,
              child: IconButton(
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
            return Semantics(
              label: l10n.sepeteEkle,
              button: true,
              child: Container(
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
      if (mounted && context.mounted) {
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
