import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/features/products/presentation/screens/customer/product_detail_screen.dart';
import 'package:mobile/features/cart/data/models/cart_item.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';
import 'package:provider/provider.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.width = 200,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.onTap,
    this.onToggleAvailability,
    this.onDelete,
    this.showRating = true,
    this.rating,
    this.ratingCount,
    this.heroTagPrefix,
    this.isCompact = false,
  });

  final Product product;
  final double? width;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onTap;
  final VoidCallback? onToggleAvailability;
  final VoidCallback? onDelete;
  final bool showRating;
  final String? rating;
  final String? ratingCount;
  final String? heroTagPrefix;
  final bool isCompact;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isAddingToCart = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final cart = Provider.of<CartProvider>(context, listen: true);
    final cartItem = _findCartItem(cart);
    final quantity = cartItem?.quantity ?? 0;
    final bool isVendorCard =
        widget.onToggleAvailability != null || widget.onDelete != null;
    final heroTag =
        '${widget.heroTagPrefix ?? 'product_image_'}${widget.product.id}';

    return MergeSemantics(
      child: GestureDetector(
        onTap:
            widget.onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(
                    productId: widget.product.id,
                    product: widget.product,
                    heroTag: heroTag,
                  ),
                ),
              );
            },
        child: Container(
          width: widget.width,
          margin: widget.width != null
              ? const EdgeInsets.symmetric(horizontal: 8)
              : EdgeInsets.zero,
          child: Card(
            elevation: 0,
            color: Colors.transparent,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: RepaintBoundary(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Container(
                    height: widget.isCompact ? 90 : 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        widget.product.imageUrl != null
                            ? Hero(
                                tag: heroTag,
                                child: OptimizedCachedImage.productThumbnail(
                                  imageUrl: widget.product.imageUrl!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  borderRadius: BorderRadius.circular(12),
                                  semanticsLabel:
                                      '${widget.product.name} ${localizations.productResmi}',
                                ),
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, size: 50),
                              ),
                        // Rating Badge
                        // Rating Badge
                        if (widget.showRating &&
                            (widget.product.rating != null &&
                                widget.product.rating! > 0))
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Semantics(
                              label:
                                  '${widget.product.rating?.toStringAsFixed(1)} ${localizations.yildiz}',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.product.rating!.toStringAsFixed(1),
                                      style: AppTheme.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    if (widget.product.reviewCount != null &&
                                        widget.product.reviewCount! > 0) ...[
                                      const SizedBox(width: 2),
                                      Text(
                                        '(${widget.product.reviewCount})',
                                        style: AppTheme.poppins(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Favorite Icon
                        if (widget.onFavoriteTap != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Semantics(
                              label: widget.isFavorite
                                  ? localizations.favorilerdenCikar
                                  : localizations.favorilereEkle,
                              button: true,
                              child: GestureDetector(
                                onTap: () {
                                  if (widget.onFavoriteTap != null) {
                                    widget.onFavoriteTap!();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    widget.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Best Seller Badge
                        if (widget.product.isBestSeller)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Semantics(
                              label: 'Çok Satan Ürün',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF7F00),
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.stars,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      localizations.bestSeller,
                                      style: AppTheme.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Vendor Menu
                        if (isVendorCard)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Semantics(
                              label: localizations.menu,
                              button: true,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.more_vert, size: 16),
                                  onSelected: (value) {
                                    if (value == 'toggle') {
                                      widget.onToggleAvailability?.call();
                                    } else if (value == 'delete') {
                                      widget.onDelete?.call();
                                    }
                                  },
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                        PopupMenuItem<String>(
                                          value: 'toggle',
                                          child: Text(
                                            widget.product.isAvailable
                                                ? localizations.outOfStock
                                                : localizations.inStock,
                                          ),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Text(
                                            localizations.delete,
                                            style: AppTheme.poppins(
                                              color: Colors.red,
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
                  ),
                  const SizedBox(height: 8),
                  // Product Info
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: AppTheme.poppins(
                            fontSize: widget.isCompact ? 14 : 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                          maxLines: widget.isCompact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!widget.isCompact) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.product.description ??
                                '${widget.product.vendorName ?? "Talabi"} • 25 dk',
                            style: AppTheme.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Semantics(
                                label:
                                    '${localizations.fiyat}: ${CurrencyFormatter.format(widget.product.price, widget.product.currency)}',
                                child: Text(
                                  CurrencyFormatter.format(
                                    widget.product.price,
                                    widget.product.currency,
                                  ),
                                  style: AppTheme.poppins(
                                    fontSize: widget.isCompact ? 14 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (!isVendorCard) ...[
                              if (quantity > 0)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Minus button
                                    Semantics(
                                      label: localizations.adediAzalt,
                                      button: true,
                                      child: GestureDetector(
                                        onTap: () async {
                                          if (cartItem?.backendId != null) {
                                            try {
                                              await cart.decreaseQuantity(
                                                cartItem!.backendId!,
                                              );
                                            } catch (e) {
                                              if (context.mounted) {
                                                ToastMessage.show(
                                                  context,
                                                  message: localizations
                                                      .errorWithMessage(
                                                        e.toString(),
                                                      ),
                                                  isSuccess: false,
                                                );
                                              }
                                            }
                                          }
                                        },
                                        child: Container(
                                          width: widget.isCompact ? 22 : 28,
                                          height: widget.isCompact ? 22 : 28,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.remove,
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                            size: widget.isCompact ? 14 : 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Quantity display
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Semantics(
                                        label:
                                            '${localizations.miktar}: $quantity',
                                        child: Text(
                                          '$quantity',
                                          style: AppTheme.poppins(
                                            color: const Color(0xFF1A1A1A),
                                            fontSize: widget.isCompact
                                                ? 12
                                                : 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Plus button
                                    Semantics(
                                      label: localizations.adediArtir,
                                      button: true,
                                      child: GestureDetector(
                                        onTap: () async {
                                          if (cartItem?.backendId != null) {
                                            try {
                                              await cart.increaseQuantity(
                                                cartItem!.backendId!,
                                              );
                                            } catch (e) {
                                              if (context.mounted) {
                                                ToastMessage.show(
                                                  context,
                                                  message: localizations
                                                      .errorWithMessage(
                                                        e.toString(),
                                                      ),
                                                  isSuccess: false,
                                                );
                                              }
                                            }
                                          } else {
                                            // Fallback for non-synced items or logic error
                                            _handleAddTap(cart);
                                          }
                                        },
                                        child: Container(
                                          width: widget.isCompact ? 22 : 28,
                                          height: widget.isCompact ? 22 : 28,
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: widget.isCompact ? 14 : 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Semantics(
                                  label: localizations.sepeteEkle,
                                  button: true,
                                  child: GestureDetector(
                                    onTap: () => _handleAddTap(cart),
                                    child: Container(
                                      width: widget.isCompact ? 22 : 28,
                                      height: widget.isCompact ? 22 : 28,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: _isAddingToCart
                                          ? const Padding(
                                              padding: EdgeInsets.all(6.0),
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Icon(
                                              Icons.add,
                                              color: Colors.white,
                                              size: widget.isCompact ? 14 : 16,
                                            ),
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  CartItem? _findCartItem(CartProvider cart) {
    if (cart.items.isEmpty) return null;

    try {
      // Find item that matches product ID AND has no selected options (base product)
      return cart.items.values.firstWhere((item) {
        return item.product.id == widget.product.id &&
            (item.selectedOptions == null || item.selectedOptions!.isEmpty);
      });
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleAddTap(CartProvider cart) async {
    // If product has required options or any option groups, redirect to detail
    // For now, simplify: if has option groups, go to detail to be safe
    // But Product model here might be summary.
    // Ideally check if summary has optionGroups indicator or just always go to detail if options exist.
    // Assuming simple products can be added directly.

    // Better UX: Always navigate to detail if not sure, OR try to add and if validation fails catch it.
    // Given the context of "Dragon Roll" having variations, we should probably navigate if it has variations.

    // Check if we need to navigate to detail
    if (widget.product.optionGroups.isNotEmpty) {
      final heroTag =
          '${widget.heroTagPrefix ?? 'product_image_'}${widget.product.id}';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(
            productId: widget.product.id,
            product: widget.product,
            heroTag: heroTag,
          ),
        ),
      );
      return;
    }

    if (_isAddingToCart) return;
    setState(() {
      _isAddingToCart = true;
    });

    try {
      await cart.addItem(widget.product, context);
      // Toast removed as per request
    } catch (e) {
      // Error handled by provider (e.g. address required)
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }
}
