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
import 'package:mobile/services/version_check_service.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/features/products/presentation/widgets/product_card.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/features/campaigns/data/models/campaign.dart';
import 'package:mobile/features/cart/data/models/cart_item.dart';
import 'package:mobile/features/products/data/models/product.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int? _currentVendorType;
  Campaign? _upsellCampaign;
  double? _upsellRemainingAmount;
  final Map<String, bool> _favoriteStatus = {};
  bool _isLoadingFavorites = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cart = Provider.of<CartProvider>(context, listen: false);
      // Main load handling moved to didChangeDependencies to support switching
      await cart.loadCart();
      _loadFavorites();
      _checkUpsellOpportunities(cart); // Check for upsell after load

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

  Future<void> _checkUpsellOpportunities(CartProvider cart) async {
    if (cart.items.isEmpty) return;

    // If a campaign is already selected, maybe don't upsell?
    // Or upsell a better one? For now, if no campaign selected.
    if (cart.selectedCampaign != null) {
      if (mounted) {
        setState(() {
          _upsellCampaign = null;
        });
      }
      return;
    }

    try {
      final bottomNav = Provider.of<BottomNavProvider>(context, listen: false);
      final vendorType = bottomNav.selectedCategory == MainCategory.restaurant
          ? 1
          : 2;

      // We need city/district for correct campaigns usually, but let's try generic fetch or use stored location
      // ApiService.getCampaigns takes optional city/district.
      // Ideally we get them from address or user location.
      // For simplicity/speed, let's just fetch by vendorType for now as "Discovery".
      // Backend validates anyway.
      final campaigns = await ApiService().getCampaigns(vendorType: vendorType);

      Campaign? bestCandidate;
      double minRemaining = double.infinity;

      for (final c in campaigns) {
        if (c.minCartAmount != null && c.minCartAmount! > cart.totalAmount) {
          final remaining = c.minCartAmount! - cart.totalAmount;
          // Threshold: Suggest if within 30% or 200 units?
          // Let's say if remaining is < 50% of current total or < 200.
          if (remaining > 0 && remaining < 200) {
            // Simple threshold check
            if (remaining < minRemaining) {
              minRemaining = remaining;
              bestCandidate = c;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _upsellCampaign = bestCandidate;
          _upsellRemainingAmount = minRemaining;
        });
      }
    } catch (e) {
      // Ignore errors silently for upsell
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bottomNav = Provider.of<BottomNavProvider>(context, listen: true);
    final vendorType = bottomNav.selectedCategory == MainCategory.restaurant
        ? 1
        : 2;

    if (_currentVendorType != vendorType) {
      _currentVendorType = vendorType;
      // Fetch recommendations when vendor type changes
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Kullanıcının default adresini al (konum kontrolü için)
        double? userLatitude;
        double? userLongitude;
        try {
          final addresses = await ApiService().getAddresses();
          if (addresses.isNotEmpty) {
            Map<String, dynamic>? defaultAddress;
            try {
              defaultAddress =
                  addresses.firstWhere(
                        (addr) =>
                            addr['isDefault'] == true ||
                            addr['IsDefault'] == true,
                      )
                      as Map<String, dynamic>?;
            } catch (_) {
              defaultAddress = addresses.first as Map<String, dynamic>;
            }

            if (defaultAddress != null) {
              userLatitude = defaultAddress['latitude'] != null
                  ? double.tryParse(defaultAddress['latitude'].toString())
                  : null;
              userLongitude = defaultAddress['longitude'] != null
                  ? double.tryParse(defaultAddress['longitude'].toString())
                  : null;
            }
          }
        } catch (e) {
          // Adres yüklenemediyse devam et (backend default adresi kullanacak)
        }

        // Async gap'ten sonra mounted kontrolü yap
        if (!mounted) return;

        Provider.of<CartProvider>(context, listen: false).fetchRecommendations(
          type: vendorType,
          lat: userLatitude,
          lon: userLongitude,
        );
      });
    }
  }

  Future<void> _loadFavorites() async {
    if (_isLoadingFavorites) return;
    setState(() => _isLoadingFavorites = true);
    try {
      final favoritesResult = await ApiService().getFavorites();
      if (mounted) {
        setState(() {
          _favoriteStatus.clear();
          for (final fav in favoritesResult.items) {
            _favoriteStatus[fav.id.toString()] = true;
          }
        });
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error loading favorites in cart', e, stackTrace);
    } finally {
      if (mounted) setState(() => _isLoadingFavorites = false);
    }
  }

  Future<void> _toggleFavorite(Product product) async {
    final productId = product.id.toString();
    final isFav = _favoriteStatus[productId] ?? false;

    try {
      if (isFav) {
        await ApiService().removeFromFavorites(productId);
      } else {
        await ApiService().addToFavorites(productId);
      }
      if (mounted) {
        setState(() {
          _favoriteStatus[productId] = !isFav;
        });
        ToastMessage.show(
          context,
          message: !isFav ? 'Favorilere eklendi' : 'Favorilerden çıkarıldı',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.show(context, message: 'Hata: $e', isSuccess: false);
      }
    }
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
                ? ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      const SizedBox(height: 20),
                      EmptyStateWidget(
                        message: localizations.cartEmptyMessage,
                        subMessage: localizations.cartEmptySubMessage,
                        actionLabel: localizations.startShopping,
                        onAction: () {
                          // Navigate to Home tab
                          Provider.of<BottomNavProvider>(
                            context,
                            listen: false,
                          ).setIndex(0);
                        },
                        isCompact: true,
                      ),
                      if (cart.recommendations.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: 16,
                          ),
                          child: Text(
                            cart.recommendationTitle ??
                                localizations.recommendedForYou,
                            style: AppTheme.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        _buildRecommendationsVertical(cart, localizations),
                      ],
                    ],
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
                          cacheExtent: 500.0, // Optimize cache extent
                          addRepaintBoundaries: true, // Optimize repaints
                          itemCount: cart.items.length,
                          itemBuilder: (context, index) {
                            final cartItem = cart.items.values.toList()[index];
                            final product = cartItem.product;
                            final isLastItem = index == cart.items.length - 1;

                            return Column(
                              children: [
                                _SlidableCartItem(
                                  key: ValueKey(
                                    cartItem.backendId ?? product.id,
                                  ),
                                  onDelete: () {
                                    if (cartItem.backendId != null) {
                                      cart.removeItem(cartItem.backendId!);
                                    }
                                  },
                                  onFavorite: () => _toggleFavorite(product),
                                  isFavorite:
                                      _favoriteStatus[product.id] ?? false,
                                  child: _buildCartItem(
                                    context,
                                    cartItem,
                                    cart,
                                  ),
                                ),
                                if (!isLastItem)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical:
                                          12, // Slightly more space for the dashed line
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

                      const SizedBox(height: 16),
                      _buildFreeDeliveryProgressBar(
                        cart,
                        localizations,
                        displayCurrency,
                      ),

                      if (_upsellCampaign != null &&
                          _upsellRemainingAmount != null)
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.saved_search,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _upsellCampaign!.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      localizations.upsellMessage(
                                        CurrencyFormatter.format(
                                          _upsellRemainingAmount!,
                                          displayCurrency,
                                        ),
                                      ),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
                                  '${localizations.cartTotalAmountLabel}: ${CurrencyFormatter.format(cart.totalAmount, displayCurrency)}',
                              child: _buildSummaryRow(
                                '${localizations.cartTotalAmountLabel}:',
                                CurrencyFormatter.format(
                                  cart.totalAmount,
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
                              '${localizations.placeOrder}, ${localizations.cartTotalAmountLabel}: ${CurrencyFormatter.format(cart.totalAmount, displayCurrency)}',
                          button: true,
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Text(
                                    CurrencyFormatter.format(
                                      cart.totalAmount,
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
                                          if (!context.mounted) return;
                                          // Check for updates before proceeding
                                          final isVersionValid =
                                              await VersionCheckService()
                                                  .checkVersion(
                                                    context,
                                                    allowDismissal: true,
                                                  );
                                          if (!isVersionValid) return;
                                          if (!context.mounted) return;

                                          // Check minimum cart amount
                                          try {
                                            final minCartAmountStr =
                                                await ApiService()
                                                    .getSystemSetting(
                                                      'MinCartAmount',
                                                    );
                                            if (minCartAmountStr != null) {
                                              final minCartAmount =
                                                  double.tryParse(
                                                    minCartAmountStr,
                                                  );
                                              if (minCartAmount != null &&
                                                  cart.totalAmount <
                                                      minCartAmount) {
                                                if (!context.mounted) return;

                                                String message;
                                                if (localizations.localeName ==
                                                    'tr') {
                                                  message =
                                                      'Minimum sipariş tutarı: ${CurrencyFormatter.format(minCartAmount, displayCurrency)}';
                                                } else if (localizations
                                                        .localeName ==
                                                    'ar') {
                                                  message =
                                                      'الحد الأدنى للطلب: ${CurrencyFormatter.format(minCartAmount, displayCurrency)}';
                                                } else {
                                                  message =
                                                      'Minimum order amount: ${CurrencyFormatter.format(minCartAmount, displayCurrency)}';
                                                }

                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(message),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                                return;
                                              }
                                            }
                                          } catch (e) {
                                            // Ignore error
                                          }

                                          if (!context.mounted) return;

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
                                            totalAmount: cart.totalAmount,
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
                                                    subtotal:
                                                        cart.subtotalAmount,
                                                    deliveryFee:
                                                        cart.deliveryFee,
                                                    discountAmount:
                                                        cart.discountAmount,
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
    CartItem cartItem,
    CartProvider cart,
  ) {
    final localizations = AppLocalizations.of(context)!;
    final product = cartItem.product;
    return MergeSemantics(
      child: Container(
        margin: EdgeInsets.zero,
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
              // Product Image with Favorite Icon
              Stack(
                children: [
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
                  // Favorite Icon Overlay
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _favoriteStatus[product.id.toString()] ?? false
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _favoriteStatus[product.id.toString()] ?? false
                            ? Colors.red
                            : Colors.grey.shade400,
                        size: 18,
                      ),
                    ),
                  ),
                ],
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
                        if (cartItem.selectedOptions != null &&
                            cartItem.selectedOptions!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              cartItem.selectedOptions!
                                  .map(
                                    (o) =>
                                        "${o['groupName']}: ${o['valueName']}",
                                  )
                                  .join(', '),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Semantics(
                          label:
                              '${localizations.fiyat}: ${CurrencyFormatter.format(cartItem.unitPrice, product.currency)}',
                          child: Text(
                            CurrencyFormatter.format(
                              cartItem.unitPrice,
                              product.currency,
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (cart.isItemDiscounted(
                          cartItem.backendId ?? product.id,
                        )) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.5),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_offer,
                                  size: 10,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  localizations.campaignApplied,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                                // Decrease Button
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
                                        size: 16,
                                        color: Colors.black,
                                      ),
                                      onPressed: () {
                                        if (cartItem.backendId != null) {
                                          cart.decreaseQuantity(
                                            cartItem.backendId!,
                                          );
                                        }
                                      },
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                // Quantity Text
                                Container(
                                  width: 32,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${cartItem.quantity}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Increase Button
                                Semantics(
                                  label: localizations.adediArtir,
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
                                        Icons.add,
                                        size: 16,
                                        color: Colors.black,
                                      ),
                                      onPressed: () {
                                        if (cartItem.backendId != null) {
                                          cart.increaseQuantity(
                                            cartItem.backendId!,
                                          );
                                        }
                                      },
                                      padding: EdgeInsets.zero,
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
                    if (product.rating != null && product.rating! > 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Semantics(
                          label:
                              '${product.rating!.toStringAsFixed(1)} ${localizations.yildiz}',
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
                                  product.rating!.toStringAsFixed(1),
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

  Widget _buildFreeDeliveryProgressBar(
    CartProvider cart,
    AppLocalizations localizations,
    Currency currency,
  ) {
    if (!cart.isFreeDeliveryEnabled) return const SizedBox.shrink();

    final progress = cart.freeDeliveryProgress;
    final isReached = cart.isFreeDeliveryReached;
    final remaining = cart.remainingForFreeDelivery;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isReached
                      ? localizations.freeDeliveryReached
                      : localizations.remainingForFreeDelivery(
                          CurrencyFormatter.format(remaining, currency),
                        ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isReached
                        ? Colors.green[700]
                        : AppTheme.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          if (!isReached) ...[
            const SizedBox(height: 2),
            Text(
              localizations.freeDeliveryDescription,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final iconSize = 24.0;
              final iconPosition = (maxWidth * progress) - (iconSize / 2);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background Bar
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // Progress Bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    height: 6,
                    width: maxWidth * progress,
                    decoration: BoxDecoration(
                      color: isReached ? Colors.green : AppTheme.primaryOrange,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        if (!isReached)
                          BoxShadow(
                            color: AppTheme.primaryOrange.withValues(
                              alpha: 0.2,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                  ),
                  // Moving Courier Icon
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    left: iconPosition.clamp(0.0, maxWidth - iconSize),
                    top: -12, // Position above the bar
                    child: Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: isReached
                              ? Colors.green.withValues(alpha: 0.2)
                              : AppTheme.primaryOrange.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        isReached ? Icons.check_circle : Icons.moped,
                        color: isReached
                            ? Colors.green
                            : AppTheme.primaryOrange,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsVertical(
    CartProvider cart,
    AppLocalizations localizations,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
          ),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.78,
              crossAxisSpacing: AppTheme.spacingSmall,
              mainAxisSpacing: 0,
            ),
            itemCount: cart.recommendations.length,
            itemBuilder: (context, index) {
              final product = cart.recommendations[index];
              return ProductCard(
                product: product,
                width: null, // Full width in grid cell
                heroTagPrefix: 'recommend_',
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
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

class _SlidableCartItem extends StatefulWidget {
  const _SlidableCartItem({
    required this.child,
    required this.onDelete,
    required this.onFavorite,
    required this.isFavorite,
    super.key,
  });

  final Widget child;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;
  final bool isFavorite;

  @override
  State<_SlidableCartItem> createState() => _SlidableCartItemState();
}

class _SlidableCartItemState extends State<_SlidableCartItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0;
  static const double _buttonWidth = 90.0;
  static const double _threshold = 150.0;
  static _SlidableCartItemState? _activeItem;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    if (_activeItem == this) _activeItem = null;
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_activeItem != null && _activeItem != this) {
      _activeItem!._collapse();
    }
    _activeItem = this;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta!;
      // Limit dragging: delete side (left swipe) and favorite side (right swipe)
      if (_dragExtent < -_threshold * 1.5) _dragExtent = -_threshold * 1.5;
      if (_dragExtent > _threshold * 1.5) _dragExtent = _threshold * 1.5;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragExtent < -_threshold) {
      _delete();
    } else if (_dragExtent > _threshold) {
      _favorite();
    } else if (_dragExtent < -_buttonWidth / 2) {
      _revealDelete();
    } else if (_dragExtent > _buttonWidth / 2) {
      _revealFavorite();
    } else {
      _collapse();
    }
  }

  void _revealDelete() {
    _animateTo(-_buttonWidth);
  }

  void _revealFavorite() {
    _animateTo(_buttonWidth);
  }

  void _favorite() {
    _animateTo(0).then((_) {
      widget.onFavorite();
    });
  }

  void _collapse() {
    _animateTo(0);
  }

  void _delete() {
    _animateTo(-MediaQuery.of(context).size.width).then((_) {
      widget.onDelete();
    });
  }

  Future<void> _animateTo(double target) async {
    final start = _dragExtent;
    _controller.reset();
    final animation = Tween<double>(
      begin: start,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    animation.addListener(() {
      setState(() {
        _dragExtent = animation.value;
      });
    });

    await _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Background Buttons (Delete and Favorite)
        if (_dragExtent < 0)
          Positioned.fill(
            child: ExcludeSemantics(
              child: Container(
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  label: Text(
                    localizations.delete,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_dragExtent > 0)
          Positioned.fill(
            child: ExcludeSemantics(
              child: Container(
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: widget.isFavorite
                      ? AppTheme.primaryOrange
                      : Colors.amber.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton.icon(
                  onPressed: _favorite,
                  icon: Icon(
                    widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.white,
                    size: 24,
                  ),
                  label: Text(
                    widget.isFavorite
                        ? localizations.removeFromFavorites
                        : localizations.addToFavorites,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Foreground Content
        Transform.translate(
          offset: Offset(_dragExtent, 0),
          child: GestureDetector(
            onHorizontalDragStart: _onHorizontalDragStart,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.white, child: widget.child),
          ),
        ),
      ],
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
