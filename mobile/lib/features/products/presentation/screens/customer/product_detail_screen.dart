import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/products/data/models/product.dart';

import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/features/cart/presentation/screens/cart_screen.dart';
import 'package:mobile/features/products/presentation/widgets/product_card.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';
import 'package:mobile/widgets/custom_confirmation_dialog.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:mobile/features/home/presentation/providers/home_provider.dart';
import 'package:mobile/features/products/presentation/providers/product_detail_provider.dart';
import 'package:mobile/utils/location_extractor.dart';

class ProductDetailScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ProductDetailProvider(productId: productId, initialProduct: product)
            ..loadProduct(refreshOnly: product != null),
      child: _ProductDetailContent(heroTag: heroTag),
    );
  }
}

class _ProductDetailContent extends StatefulWidget {
  const _ProductDetailContent({this.heroTag});

  final String? heroTag;

  @override
  State<_ProductDetailContent> createState() => _ProductDetailContentState();
}

class _ProductDetailContentState extends State<_ProductDetailContent> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _reviewsSectionKey = GlobalKey();
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _checkSimilarProductsLoad();
  }

  void _checkSimilarProductsLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final homeProvider = context.read<HomeProvider>();
      final productProvider = context.read<ProductDetailProvider>();

      if (homeProvider.selectedAddress != null) {
        final location = LocationExtractor.fromAddress(
          homeProvider.selectedAddress,
        );
        if (productProvider.similarProducts.isEmpty) {
          productProvider.loadSimilarProducts(
            userLatitude: location.latitude ?? 0.0,
            userLongitude: location.longitude ?? 0.0,
          );
        }
      } else if (homeProvider.addresses.isEmpty &&
          !homeProvider.isAddressesLoading &&
          homeProvider.addresses.isEmpty) {
        // Attempt to load addresses if missing (e.g. direct link)
        homeProvider.loadAddresses().then((_) {
          if (mounted && homeProvider.selectedAddress != null) {
            final location = LocationExtractor.fromAddress(
              homeProvider.selectedAddress,
            );
            productProvider.loadSimilarProducts(
              userLatitude: location.latitude ?? 0.0,
              userLongitude: location.longitude ?? 0.0,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleWriteReview() async {
    final productProvider = context.read<ProductDetailProvider>();
    final product = productProvider.product;
    if (product == null) return;

    final l10n = AppLocalizations.of(context)!;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final canReview = await productProvider.canReview();
      if (!mounted) return;
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
      if (!mounted) return;
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
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
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
                        onPressed: () => Navigator.pop(dialogContext),
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
                          final productProvider = context
                              .read<ProductDetailProvider>();
                          try {
                            await productProvider.createReview(
                              rating,
                              commentController.text,
                            );
                            if (!mounted) return;
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            ToastMessage.show(
                              context,
                              message: l10n.reviewCreatedSuccessfully,
                              isSuccess: true,
                            );
                          } catch (e) {
                            if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<ProductDetailProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildSkeleton(context);
        }

        final product = provider.product;
        if (product == null) {
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
              // 1. Scrollable Area
              Positioned.fill(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          // Header Image
                          SizedBox(
                            height: 300,
                            width: double.infinity,
                            child: product.imageUrl != null
                                ? Hero(
                                    tag:
                                        widget.heroTag ??
                                        'product_image_${product.id}',
                                    child: OptimizedCachedImage.productImage(
                                      imageUrl: product.imageUrl!,
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

                          // Content Card Overlap
                          Container(
                            margin: const EdgeInsets.only(top: 220),
                            padding: const EdgeInsets.only(bottom: 100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Info Card
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style: AppTheme.poppins(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(
                                                      0xFF1A1A1A,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.location_on,
                                                      size: 16,
                                                      color:
                                                          colorScheme.primary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        product.vendorName ??
                                                            l10n.talabi,
                                                        style: AppTheme.poppins(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[500],
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
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
                                            child: _buildInfoItem(
                                              icon: Icons.star,
                                              iconColor: Colors.orange,
                                              text:
                                                  ((provider.reviewsSummary?.averageRating ??
                                                                  0.0) >
                                                              0
                                                          ? provider
                                                                .reviewsSummary!
                                                                .averageRating
                                                          : (product.rating ??
                                                                0.0))
                                                      .toStringAsFixed(1),
                                              subText:
                                                  '(${(provider.reviewsSummary?.totalRatings ?? 0) > 0 ? provider.reviewsSummary!.totalRatings : product.reviewCount} +)',
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildInfoItem(
                                              icon: Icons.access_time_filled,
                                              iconColor: colorScheme.primary,
                                              text: l10n.deliveryTimeRange,
                                              subText: l10n.deliveryTime,
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildInfoItem(
                                              icon: Icons.delivery_dining,
                                              iconColor: Colors.green,
                                              text: l10n.talabi,
                                              subText: l10n.delivery,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Description
                                if (product.description != null &&
                                    product.description!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.description,
                                          style: AppTheme.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          product.description!,
                                          style: AppTheme.poppins(
                                            color: Colors.grey[600],
                                            height: 1.5,
                                          ),
                                          maxLines: _isDescriptionExpanded
                                              ? null
                                              : 3,
                                          overflow: _isDescriptionExpanded
                                              ? TextOverflow.visible
                                              : TextOverflow.ellipsis,
                                        ),
                                        if ((product.description?.length ?? 0) >
                                            100)
                                          TextButton(
                                            onPressed: () => setState(
                                              () => _isDescriptionExpanded =
                                                  !_isDescriptionExpanded,
                                            ),
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            child: Text(
                                              _isDescriptionExpanded
                                                  ? 'Daha az'
                                                  : 'Daha fazla',
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                const SizedBox(height: 24),

                                // Similar Products
                                if (provider.similarProducts.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.similarProducts,
                                          style: AppTheme.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          height: 240,
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount:
                                                provider.similarProducts.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(width: 12),
                                            itemBuilder: (context, index) {
                                              return SizedBox(
                                                width: 160,
                                                child: ProductCard(
                                                  product: provider
                                                      .similarProducts[index],
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            ProductDetailScreen(
                                                              productId: provider
                                                                  .similarProducts[index]
                                                                  .id,
                                                              product: provider
                                                                  .similarProducts[index],
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
                                    ),
                                  ),

                                const SizedBox(height: 24),

                                // Reviews
                                // Reviews
                                Container(
                                  key: _reviewsSectionKey,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            l10n.reviews(
                                              provider
                                                      .reviewsSummary
                                                      ?.totalRatings ??
                                                  0,
                                            ),
                                            style: AppTheme.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (provider.isLoadingReviews)
                                            const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (provider
                                              .reviewsSummary
                                              ?.reviews
                                              .isNotEmpty ??
                                          false) ...[
                                        const SizedBox(height: 12),
                                        // Display up to 3 reviews
                                        ...(provider.reviewsSummary?.reviews ??
                                                [])
                                            .take(3)
                                            .map(
                                              (review) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 12,
                                                ),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          CircleAvatar(
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[200],
                                                            radius: 16,
                                                            child: Icon(
                                                              Icons.person,
                                                              size: 16,
                                                              color: Colors
                                                                  .grey[500],
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Text(
                                                            review.userFullName,
                                                            style:
                                                                AppTheme.poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14,
                                                                ),
                                                          ),
                                                          const Spacer(),
                                                          const Icon(
                                                            Icons.star,
                                                            size: 14,
                                                            color: Colors.amber,
                                                          ),
                                                          const SizedBox(
                                                            width: 2,
                                                          ),
                                                          Text(
                                                            review.rating
                                                                .toString(),
                                                            style:
                                                                AppTheme.poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (review
                                                          .comment
                                                          .isNotEmpty)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 8,
                                                              ),
                                                          child: Text(
                                                            review.comment,
                                                            style:
                                                                AppTheme.poppins(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                      .grey[700],
                                                                ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                      ],
                                      if (provider
                                              .reviewsSummary
                                              ?.reviews
                                              .isEmpty ??
                                          true)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 20,
                                          ),
                                          child: Text(
                                            l10n.noReviewsYet,
                                            style: AppTheme.poppins(
                                              color: Colors.grey[500],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 12),
                                      TextButton(
                                        onPressed: _handleWriteReview,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 24,
                                          ),
                                          backgroundColor: AppTheme
                                              .primaryOrange
                                              .withValues(alpha: 0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          l10n.writeAReview,
                                          style: const TextStyle(
                                            color: AppTheme.primaryOrange,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 100), // Space for bottom bar
                    ],
                  ),
                ),
              ),

              // Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: PoolingHeader(
                    isFavorite: provider.isFavorite,
                    onFavoriteTap: () => provider.toggleFavorite(),
                    onBackTap: () => Navigator.pop(context),
                    onShareTap: () =>
                        Share.share('Check out ${product.name} on Talabi!'),
                  ),
                ),
              ),

              // Bottom Action Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                    top: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.totalPrice,
                              style: AppTheme.poppins(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${product.price.toStringAsFixed(2)} ${product.currency.symbol}',
                              style: AppTheme.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 3,
                        child: Consumer<CartProvider>(
                          builder: (context, cartProvider, child) {
                            final cartItem = cartProvider.getCartItem(
                              product.id,
                            );

                            if (cartItem != null) {
                              return Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        cartProvider.decreaseQuantity(
                                          cartItem.backendId ?? '',
                                        );
                                      },
                                      child: Container(
                                        width: 56,
                                        height: double.infinity,
                                        color: colorScheme.primary,
                                        child: const Icon(
                                          Icons.remove,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          '${cartItem.quantity}',
                                          style: AppTheme.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        cartProvider.increaseQuantity(
                                          cartItem.backendId ?? '',
                                        );
                                      },
                                      child: Container(
                                        width: 56,
                                        height: double.infinity,
                                        color: colorScheme.primary,
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ElevatedButton(
                              onPressed: () {
                                // Calculate options inside onPressed to ensure latest state
                                final selectedOptionsList =
                                    <Map<String, dynamic>>[];
                                for (final group in product.optionGroups) {
                                  final selectedIds =
                                      provider.selectedOptions[group.id];
                                  if (selectedIds != null) {
                                    for (final option in group.options) {
                                      if (selectedIds.contains(option.id)) {
                                        selectedOptionsList.add({
                                          'groupId': group.id,
                                          'groupName': group.name,
                                          'optionId': option.id,
                                          'valueName': option.name,
                                          'priceAdjustment':
                                              option.priceAdjustment,
                                        });
                                      }
                                    }
                                  }
                                }

                                cartProvider.addItem(
                                  product,
                                  context,
                                  selectedOptions: selectedOptionsList,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                l10n.addToCart,
                                style: AppTheme.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(subText, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
      ],
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class PoolingHeader extends StatelessWidget {
  const PoolingHeader({
    super.key,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onBackTap,
    required this.onShareTap,
  });
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onBackTap;
  final VoidCallback onShareTap;
  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cartItemCount = cartProvider.itemCount;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(icon: Icons.arrow_back, onTap: onBackTap),
          Row(
            children: [
              _buildCircleButton(icon: Icons.share, onTap: onShareTap),
              const SizedBox(width: 12),
              _buildCircleButton(
                icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.black,
                onTap: onFavoriteTap,
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
                  if (cartItemCount > 0)
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
                          '$cartItemCount',
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
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
