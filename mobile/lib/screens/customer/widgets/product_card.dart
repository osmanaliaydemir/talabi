import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/screens/customer/product/product_detail_screen.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/widgets/common/toast_message.dart';
import 'package:mobile/widgets/common/cached_network_image_widget.dart';
import 'package:provider/provider.dart';

class ProductCard extends StatefulWidget {
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
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isAddingToCart = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final cart = Provider.of<CartProvider>(context, listen: true);
    final cartItem = cart.items[widget.product.id];
    final quantity = cartItem?.quantity ?? 0;
    final bool isVendorCard =
        widget.onToggleAvailability != null || widget.onDelete != null;

    return GestureDetector(
      onTap:
          widget.onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(
                  productId: widget.product.id,
                  product: widget.product,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    widget.product.imageUrl != null
                        ? OptimizedCachedImage.productThumbnail(
                            imageUrl: widget.product.imageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            borderRadius: BorderRadius.circular(12),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 50),
                          ),
                    // Rating Badge
                    if (widget.showRating)
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
                              Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.rating ?? '4.7',
                                style: AppTheme.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              if (widget.ratingCount != null) ...[
                                const SizedBox(width: 2),
                                Text(
                                  '(${widget.ratingCount})',
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
                    // Favorite Icon
                    if (widget.onFavoriteTap != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            if (widget.onFavoriteTap != null) {
                              widget.onFavoriteTap!();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
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
                    // Best Seller Badge
                    Positioned(
                      bottom: 0,
                      left: 0,
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
                              'Best Seller',
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
                    // Vendor Menu
                    if (isVendorCard)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
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
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Product Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: AppTheme.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            CurrencyFormatter.format(
                              widget.product.price,
                              widget.product.currency,
                            ),
                            style: AppTheme.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isVendorCard) ...[
                          if (quantity > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Minus button
                                GestureDetector(
                                  onTap: () async {
                                    try {
                                      await cart.decreaseQuantity(
                                        widget.product.id,
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        ToastMessage.show(
                                          context,
                                          message: localizations
                                              .errorWithMessage(e.toString()),
                                          isSuccess: false,
                                        );
                                      }
                                    }
                                  },
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      color: Theme.of(context).primaryColor,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                // Quantity display
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    '$quantity',
                                    style: AppTheme.poppins(
                                      color: const Color(0xFF1A1A1A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Plus button
                                GestureDetector(
                                  onTap: () async {
                                    try {
                                      await cart.increaseQuantity(
                                        widget.product.id,
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        ToastMessage.show(
                                          context,
                                          message: localizations
                                              .errorWithMessage(e.toString()),
                                          isSuccess: false,
                                        );
                                      }
                                    }
                                  },
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            GestureDetector(
                              onTap: () async {
                                if (_isAddingToCart) return;

                                setState(() {
                                  _isAddingToCart = true;
                                });

                                try {
                                  await cart.addItem(widget.product, context);
                                  if (mounted) {
                                    ToastMessage.show(
                                      context,
                                      message:
                                          '${widget.product.name} ${localizations.addToCart}',
                                      isSuccess: true,
                                    );
                                  }
                                } catch (e) {
                                  // Error is handled by CartProvider
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isAddingToCart = false;
                                    });
                                  }
                                }
                              },
                              child: Container(
                                width: 28,
                                height: 28,
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
                                    : const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 16,
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
    );
  }
}
