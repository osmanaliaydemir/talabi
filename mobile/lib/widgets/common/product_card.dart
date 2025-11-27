import 'package:flutter/material.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/screens/customer/product_detail_screen.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:provider/provider.dart';

/// Reusable product card widget for displaying products in a grid/list format.
///
/// Features:
/// - Product image with rating and favorite badges
/// - Product name and metadata
/// - Price display
/// - Add to cart / quantity controls
/// - Favorite toggle functionality
/// - Navigation to product detail screen
class ProductCard extends StatelessWidget {
  final Product product;
  final double? width;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onTap;
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
    this.showRating = true,
    this.rating,
    this.ratingCount,
  });

  @override
  Widget build(BuildContext context) {
    final localizationProvider = Provider.of<LocalizationProvider>(context);
    final cart = Provider.of<CartProvider>(context, listen: true);
    final cartItem = cart.items[product.id];
    final quantity = cartItem?.quantity ?? 0;

    return GestureDetector(
      onTap:
          onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(
                  productId: product.id,
                  product: product,
                ),
              ),
            );
          },
      child: Container(
        width: width,
        margin: width != null
            ? const EdgeInsets.symmetric(horizontal: 8)
            : EdgeInsets.zero,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                    if (showRating)
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
                                rating ?? '4.7',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (ratingCount != null) ...[
                                const SizedBox(width: 2),
                                Text(
                                  '($ratingCount)',
                                  style: TextStyle(
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
                    if (onFavoriteTap != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            // Stop propagation to prevent card tap
                            if (onFavoriteTap != null) {
                              onFavoriteTap!();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
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
                                      // Minus button
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
                                              if (context.mounted) {
                                                ToastMessage.show(
                                                  context,
                                                  message:
                                                      '${product.name} miktarı azaltıldı',
                                                  isSuccess: true,
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ToastMessage.show(
                                                  context,
                                                  message: 'Hata: $e',
                                                  isSuccess: false,
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                      // Quantity display
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
                                      // Plus button
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
                                              if (context.mounted) {
                                                ToastMessage.show(
                                                  context,
                                                  message:
                                                      '${product.name} miktarı artırıldı',
                                                  isSuccess: true,
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ToastMessage.show(
                                                  context,
                                                  message: 'Hata: $e',
                                                  isSuccess: false,
                                                );
                                              }
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
                                        await cart.addItem(product, context);
                                        if (context.mounted) {
                                          ToastMessage.show(
                                            context,
                                            message:
                                                '${product.name} sepete eklendi',
                                            isSuccess: true,
                                          );
                                        }
                                      } catch (e) {
                                        // Error is handled by CartProvider (address popup, etc.)
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
      ),
    );
  }
}
