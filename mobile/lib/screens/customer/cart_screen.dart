import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final localizationProvider = Provider.of<LocalizationProvider>(context);
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          _buildHeader(context, localizations, colorScheme, cart),
          // Main Content
          Expanded(
            child: cart.isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.orange))
                : cart.itemCount == 0
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations.cartEmptyMessage,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                            top: 16,
                            left: 16,
                            right: 16,
                            bottom: 16,
                          ),
                          itemCount: cart.items.length,
                          itemBuilder: (context, index) {
                            final cartItem = cart.items.values.toList()[index];
                            final product = cartItem.product;
                            final isLastItem = index == cart.items.length - 1;

                            return Column(
                              children: [
                                _buildCartItem(
                                  context,
                                  product,
                                  cartItem.quantity,
                                  cart,
                                  localizationProvider,
                                ),
                                if (!isLastItem)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: CustomPaint(
                                      painter: DashedLinePainter(),
                                      child: const SizedBox(
                                        width: double.infinity,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      // Voucher Code Section
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_offer,
                              color: Colors.grey[700],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText:
                                      localizations.cartVoucherPlaceholder,
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Order Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              '${localizations.cartSubtotalLabel}:',
                              CurrencyFormatter.format(
                                cart.totalAmount,
                                localizationProvider.currency,
                              ),
                              isBold: false,
                            ),
                            const SizedBox(height: 8),
                            _buildSummaryRow(
                              '${localizations.cartDeliveryFeeLabel}:',
                              CurrencyFormatter.format(
                                2.0, // Fixed delivery fee
                                localizationProvider.currency,
                              ),
                              isBold: false,
                            ),
                            const SizedBox(height: 8),
                            Divider(color: Colors.grey[300], height: 1),
                            const SizedBox(height: 8),
                            _buildSummaryRow(
                              '${localizations.cartTotalAmountLabel}:',
                              CurrencyFormatter.format(
                                cart.totalAmount + 2.0,
                                localizationProvider.currency,
                              ),
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                      // Checkout Button
                      Container(
                        margin: const EdgeInsets.all(16),
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Text(
                                  CurrencyFormatter.format(
                                    cart.totalAmount + 2.0,
                                    localizationProvider.currency,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextButton(
                                onPressed: cart.itemCount == 0
                                    ? null
                                    : () async {
                                        // Get vendor ID from first item
                                        final firstItem =
                                            cart.items.values.first;
                                        final vendorId =
                                            firstItem.product.vendorId;

                                        // Check if all items are from the same vendor
                                        final allSameVendor = cart.items.values
                                            .every(
                                              (item) =>
                                                  item.product.vendorId ==
                                                  vendorId,
                                            );

                                        if (!allSameVendor) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                localizations
                                                    .cartSameVendorWarning,
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        // Prepare order items
                                        final orderItems = <int, int>{};
                                        for (var item in cart.items.values) {
                                          orderItems[item.product.id] =
                                              item.quantity;
                                        }

                                        try {
                                          // Show loading
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => const Center(
                                              child: CircularProgressIndicator(
                                                color: Colors.orange,
                                              ),
                                            ),
                                          );

                                          // Create order
                                          final apiService = ApiService();
                                          final order = await apiService
                                              .createOrder(
                                                vendorId,
                                                orderItems,
                                              );

                                          // Hide loading
                                          if (context.mounted)
                                            Navigator.pop(context);

                                          // Clear cart
                                          cart.clear();

                                          // Show success
                                          if (context.mounted) {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text(
                                                  localizations
                                                      .orderPlacedTitle,
                                                ),
                                                content: Text(
                                                  localizations
                                                      .orderPlacedMessage(
                                                        '${order.id}',
                                                        CurrencyFormatter.format(
                                                          order.totalAmount,
                                                          localizationProvider
                                                              .currency,
                                                        ),
                                                      ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text(
                                                      localizations.ok,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          // Hide loading
                                          if (context.mounted)
                                            Navigator.pop(context);

                                          // Show error
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  localizations
                                                      .errorWithMessage('$e'),
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                child: Text(
                                  localizations.checkout,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
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
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations localizations,
    ColorScheme colorScheme,
    CartProvider cart,
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
              // Cart Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shopping_cart,
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
                      localizations.myCart,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cart.itemCount} ${localizations.products}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete Button
              if (cart.itemCount > 0)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    _showClearCartDialog(context, cart);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    product,
    int quantity,
    CartProvider cart,
    LocalizationProvider localizationProvider,
  ) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: product.imageUrl != null
                ? Image.network(
                    product.imageUrl!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Icon(Icons.fastfood, size: 50),
                      );
                    },
                  )
                : Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                    child: const Icon(Icons.fastfood, size: 50),
                  ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.productByVendor(
                        product.vendorName ?? localizations.vendor,
                      ),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(
                        product.price,
                        localizationProvider.currency,
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Quantity Selector
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
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
                              decoration: BoxDecoration(
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
                                    await cart.decreaseQuantity(product.id);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            localizations.errorWithMessage(
                                              '$e',
                                            ),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
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
                              decoration: BoxDecoration(
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
                                    await cart.increaseQuantity(product.id);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            localizations.errorWithMessage(
                                              '$e',
                                            ),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Rating - Sağ üst köşe
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.orange[700]),
                        const SizedBox(width: 2),
                        Text(
                          '4.7',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cart) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.clearCartTitle),
          content: Text(localizations.clearCartMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                localizations.clearCartNo,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await cart.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localizations.clearCartSuccess),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localizations.errorWithMessage('$e')),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(
                localizations.clearCartYes,
                style: const TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Dashed Line Painter
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
