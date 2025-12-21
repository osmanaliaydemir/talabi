import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/settings/data/models/currency.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/widgets/custom_confirmation_dialog.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/features/home/presentation/widgets/shared_header.dart';
import 'package:mobile/features/products/presentation/screens/customer/product_detail_screen.dart';
import 'package:mobile/features/orders/presentation/screens/customer/checkout_screen.dart';
import 'package:mobile/services/analytics_service.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';
import 'package:provider/provider.dart';
import 'package:mobile/widgets/empty_state_widget.dart';
import 'package:mobile/features/coupons/presentation/screens/coupon_list_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cart = Provider.of<CartProvider>(context, listen: false);
      await cart.loadCart();

      if (mounted) {
        final currency = cart.items.isNotEmpty
            ? cart.items.values.first.product.currency.code
            : 'TRY';

        await AnalyticsService.logViewCart(
          totalAmount: cart.totalAmount,
          currency: currency,
          cartItems: cart.items.values.toList(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final localizations = AppLocalizations.of(context)!;

    // Get currency from first item, or default to TRY
    final Currency displayCurrency = cart.items.isNotEmpty
        ? cart.items.values.first.product.currency
        : Currency.try_;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          SharedHeader(
            title: localizations.myCart,
            subtitle: '${cart.itemCount} ${localizations.products}',
            icon: Icons.shopping_cart,
            showBackButton: widget.showBackButton,
            action: cart.itemCount > 0
                ? Semantics(
                    label: localizations.clearCartTitle,
                    button: true,
                    child: GestureDetector(
                      onTap: () {
                        _showClearCartDialog(context, cart);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          // Main Content
          Expanded(
            child: cart.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryOrange,
                    ),
                  )
                : cart.itemCount == 0
                ? EmptyStateWidget(message: localizations.cartEmptyMessage)
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
                          cacheExtent: 500.0, // Optimize cache extent
                          addRepaintBoundaries: true, // Optimize repaints
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
                          border: cart.appliedCoupon != null
                              ? Border.all(color: Colors.green, width: 1)
                              : null,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.local_offer,
                                color: cart.appliedCoupon != null
                                    ? Colors.green
                                    : AppTheme.primaryOrange,
                                size: 20,
                              ),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CouponListScreen(
                                          isSelectionMode: true,
                                        ),
                                  ),
                                );
                                if (result != null && result is String) {
                                  _couponController.text = result;
                                  if (context.mounted) {
                                    _applyCoupon(context, cart, result);
                                  }
                                }
                              },
                              tooltip: 'Kupon Seç',
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: TextField(
                                controller: _couponController,
                                enabled: cart.appliedCoupon == null,
                                decoration: InputDecoration(
                                  hintText: cart.appliedCoupon != null
                                      ? cart.appliedCoupon!.code
                                      : localizations.cartVoucherPlaceholder,
                                  hintStyle: TextStyle(
                                    color: cart.appliedCoupon != null
                                        ? Colors.black87
                                        : Colors.grey[500],
                                    fontWeight: cart.appliedCoupon != null
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    _applyCoupon(context, cart, value);
                                  }
                                },
                              ),
                            ),
                            if (cart.appliedCoupon != null)
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () {
                                  cart.removeCoupon();
                                  _couponController.clear();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Kupon kaldırıldı'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                },
                              )
                            else
                              IconButton(
                                icon: Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  if (_couponController.text.isNotEmpty) {
                                    _applyCoupon(
                                      context,
                                      cart,
                                      _couponController.text,
                                    );
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Order Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Semantics(
                              label:
                                  '${localizations.cartSubtotalLabel}: ${CurrencyFormatter.format(cart.totalAmount, displayCurrency)}',
                              child: _buildSummaryRow(
                                '${localizations.cartSubtotalLabel}:',
                                CurrencyFormatter.format(
                                  cart.totalAmount,
                                  displayCurrency,
                                ),
                                isBold: false,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Semantics(
                              label:
                                  '${localizations.cartDeliveryFeeLabel}: ${CurrencyFormatter.format(2.0, displayCurrency)}',
                              child: _buildSummaryRow(
                                '${localizations.cartDeliveryFeeLabel}:',
                                CurrencyFormatter.format(
                                  2.0, // Fixed delivery fee
                                  displayCurrency,
                                ),
                                isBold: false,
                              ),
                            ),
                            if (cart.discountAmount > 0) ...[
                              const SizedBox(height: 8),
                              Semantics(
                                label:
                                    'İndirim: -${CurrencyFormatter.format(cart.discountAmount, displayCurrency)}',
                                child: _buildSummaryRow(
                                  'İndirim:',
                                  '-${CurrencyFormatter.format(cart.discountAmount, displayCurrency)}',
                                  isBold: false,
                                  valueColor: Colors.green,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Divider(color: Colors.grey[300], height: 1),
                            const SizedBox(height: 8),
                            Semantics(
                              label:
                                  '${localizations.cartTotalAmountLabel}: ${CurrencyFormatter.format(cart.totalAmount + 2.0, displayCurrency)}',
                              child: _buildSummaryRow(
                                '${localizations.cartTotalAmountLabel}:',
                                CurrencyFormatter.format(
                                  cart.totalAmount + 2.0,
                                  displayCurrency,
                                ),
                                isBold: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Checkout Button
                      Container(
                        margin: const EdgeInsets.all(16),
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Semantics(
                          label:
                              '${localizations.placeOrder}, ${localizations.cartTotalAmountLabel}: ${CurrencyFormatter.format(cart.totalAmount + 2.0, displayCurrency)}',
                          button: true,
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Text(
                                    CurrencyFormatter.format(
                                      cart.totalAmount + 2.0,
                                      displayCurrency,
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
                                          final allSameVendor = cart
                                              .items
                                              .values
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

                                          // Log begin_checkout
                                          await AnalyticsService.logBeginCheckout(
                                            totalAmount: cart.totalAmount + 2.0,
                                            currency: displayCurrency.code,
                                            cartItems: cart.items.values
                                                .toList(),
                                          );

                                          if (!context.mounted) return;

                                          // Navigate to checkout screen
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CheckoutScreen(
                                                    cartItems: cart.items,
                                                    vendorId: vendorId,
                                                    subtotal: cart.totalAmount,
                                                    deliveryFee: 2.0,
                                                  ),
                                            ),
                                          );
                                        },
                                  child: Text(
                                    localizations.placeOrder,
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
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    product,
    int quantity,
    CartProvider cart,
  ) {
    final localizations = AppLocalizations.of(context)!;
    return MergeSemantics(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: GestureDetector(
          onTap: () {
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
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: product.imageUrl != null
                    ? OptimizedCachedImage.productThumbnail(
                        imageUrl: product.imageUrl!,
                        width: 100,
                        height: 100,
                        borderRadius: BorderRadius.circular(12),
                        semanticsLabel:
                            '${product.name} ${localizations.productResmi}',
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
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Semantics(
                          label:
                              '${localizations.fiyat}: ${CurrencyFormatter.format(product.price, product.currency)}',
                          child: Text(
                            CurrencyFormatter.format(
                              product.price,
                              product.currency,
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
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
                                Semantics(
                                  label: localizations.adediAzalt,
                                  button: true,
                                  child: Container(
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
                                        } catch (e) {
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
                                    ),
                                  ),
                                ),
                                // Orta: Gri arka plan üzerinde sayı
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Semantics(
                                    label: '${localizations.miktar}: $quantity',
                                    child: Text(
                                      '$quantity',
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                // Sağ: Turuncu arka planlı artı butonu
                                Semantics(
                                  label: localizations.adediArtir,
                                  button: true,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryOrange,
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
                                        } catch (e) {
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
                                    ),
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
                      child: Semantics(
                        label: '4.7 ${localizations.yildiz}',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.orange[700],
                              ),
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

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
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
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _applyCoupon(
    BuildContext context,
    CartProvider cart,
    String code,
  ) async {
    // FocusScope.of(context).unfocus(); // Close keyboard
    try {
      await cart.applyCoupon(code);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kupon başarıyla uygulandı!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showClearCartDialog(BuildContext context, CartProvider cart) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomConfirmationDialog(
          title: localizations.clearCartTitle,
          message: localizations.clearCartMessage,
          confirmText: localizations.clearCartYes,
          cancelText: localizations.clearCartNo,
          icon: Icons.delete_outline,
          iconColor: Colors.red,
          confirmButtonColor: Colors.red,
          onConfirm: () async {
            Navigator.of(context).pop();
            try {
              await cart.clear();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localizations.clearCartSuccess),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localizations.errorWithMessage('$e')),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            }
          },
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
