import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/features/home/presentation/widgets/shared_header.dart';
import 'package:mobile/widgets/custom_confirmation_dialog.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/features/cart/data/models/cart_item.dart';
import 'package:mobile/features/orders/data/models/order_calculation_models.dart';
import 'package:mobile/features/orders/presentation/screens/customer/order_success_screen.dart';
import 'package:mobile/features/campaigns/presentation/widgets/campaign_selection_bottom_sheet.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';

import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/orders/presentation/providers/checkout_provider.dart';
import 'package:mobile/features/settings/data/models/currency.dart';
import 'package:mobile/widgets/agreement_checkbox.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.vendorId,
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.discountAmount = 0.0,
  });

  final Map<String, CartItem> cartItems;
  final String vendorId;
  final double subtotal;
  final double deliveryFee;
  final double discountAmount;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _noteController = TextEditingController();
  late CartProvider _cartProvider;
  late CheckoutProvider _checkoutProvider;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _cartProvider = Provider.of<CartProvider>(context, listen: false);
    _checkoutProvider = Provider.of<CheckoutProvider>(context, listen: false);

    // Initialize provider logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkoutProvider.init().then((_) {
        if (mounted) _calculateOrder();
      });
    });

    // Listen to cart changes for coupon/campaign updates
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Clear any previously selected promotions when entering checkout
      try {
        await ApiService().clearCartPromotions();
        // Clear local state
        await _cartProvider.removeCampaign();
        await _cartProvider.removeCoupon();
      } catch (e) {
        LoggerService().error('Error clearing promotions on checkout entry', e);
      }

      // Add listener AFTER clearing initial promotions to avoid unnecessary calculations
      if (mounted) {
        _cartProvider.addListener(_onCartChanged);
        // Force calculation
        _calculateOrder();

        if (mounted) {
          setState(() {
            // UI state for initialization completeness
            _isInitializing = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    // Safely remove listener using the stored provider reference
    _cartProvider.removeListener(_onCartChanged);
    _noteController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    // Trigger calculation when cart changes (e.g. coupon added/removed)
    if (mounted) {
      _calculateOrder();
    }
  }

  Future<void> _calculateOrder() async {
    if (!mounted) return;
    await _checkoutProvider.calculateOrder(
      vendorId: widget.vendorId,
      cartItems: widget.cartItems,
      couponCode: _cartProvider.appliedCoupon?.code,
      campaignId: _cartProvider.selectedCampaign?.id,
    );
  }

  Future<void> _createOrder() async {
    final localizations = AppLocalizations.of(context)!;

    try {
      final order = await _checkoutProvider.createOrder(
        vendorId: widget.vendorId,
        items: widget.cartItems,
        defaultTotal: _cartProvider.totalAmount + widget.deliveryFee,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        couponCode: _cartProvider.appliedCoupon?.code,
        campaignId: _cartProvider.selectedCampaign?.id,
        currencyCode: widget.cartItems.values.first.product.currency.code,
      );

      // Clear cart
      if (mounted) {
        await _cartProvider.clear();
      }

      // Iterate
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OrderSuccessScreen(orderId: order.customerOrderId),
          ),
        );
      }
    } catch (e) {
      // Error handling handled by provider rethrow hopefully, or we catch here to show dialog
      // The provider rethrows so we can show dialog here.
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => CustomConfirmationDialog(
            title: 'Sipariş Oluşturulamadı',
            message:
                'Lütfen bilgilerinizi kontrol edip tekrar deneyin.\nHata: ${e.toString().replaceAll('Exception: ', '')}',
            confirmText: localizations.ok,
            cancelText: '',
            icon: Icons.error_outline,
            iconColor: Colors.red,
            confirmButtonColor: AppTheme.primaryOrange,
            onConfirm: () => Navigator.pop(context),
            content: null,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final cart = Provider.of<CartProvider>(context);
    final checkout = Provider.of<CheckoutProvider>(context);

    final Currency displayCurrency = widget.cartItems.isNotEmpty
        ? widget.cartItems.values.first.product.currency
        : Currency.try_;

    final double? totalAmount = checkout.calculationResult?.totalAmount;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SharedHeader(
            title: localizations.checkoutTitle,
            subtitle: localizations.checkoutSubtitle,
            showBackButton: true,
            action: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: checkout.isLoadingAddresses
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryOrange,
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFreeDeliveryProgressBar(
                          cart,
                          localizations,
                          displayCurrency,
                        ),
                        _buildSectionTitle(
                          localizations.orderInformation,
                          Icons.list_alt,
                        ),
                        const SizedBox(height: 12),

                        _buildAddressCard(localizations),
                        const SizedBox(height: 24),

                        Semantics(
                          label: localizations.paymentMethod,
                          explicitChildNodes: true,
                          child: _buildPaymentMethods(localizations),
                        ),
                        const SizedBox(height: 24),

                        _buildDiscountSection(localizations),
                        const SizedBox(height: 24),

                        _buildOrderNoteSection(localizations),
                        const SizedBox(height: 24),

                        _buildSectionTitle(
                          localizations.orderSummary,
                          Icons.receipt,
                        ),
                        const SizedBox(height: 12),

                        // Error handling for calculation
                        if (checkout.calculationError != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.red.shade50,
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Fiyat hesaplanamadı: ${checkout.calculationError}',
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: _calculateOrder,
                                ),
                              ],
                            ),
                          ),

                        _isInitializing
                            ? const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _buildOrderSummary(
                                localizations,
                                displayCurrency,
                                cart,
                                checkout.calculationResult,
                              ),
                        const SizedBox(height: 16),

                        AgreementCheckbox(
                          value: checkout.acceptedDistanceSales,
                          onChanged: (val) {
                            checkout.setAcceptedDistanceSales(val ?? false);
                          },
                          agreementKey: 'DistanceSalesAgreement',
                          agreementTitle: localizations.distanceSalesAgreement,
                          linkText: localizations.distanceSalesAgreement,
                          suffixText: localizations.iReadAndAccept,
                          validator: (val) {
                            if (val != true) {
                              return localizations.pleaseAcceptDistanceSales;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        Semantics(
                          label:
                              '${localizations.confirmOrder}, ${localizations.totalAmount}: ${CurrencyFormatter.format(totalAmount ?? 0, displayCurrency)}',
                          button: true,
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed:
                                  (checkout.isLoading ||
                                      checkout.isCalculating ||
                                      checkout.calculationResult == null)
                                  ? null
                                  : _createOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  (checkout.isLoading || checkout.isCalculating)
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            localizations.confirmOrder,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            CurrencyFormatter.format(
                                              totalAmount ?? 0,
                                              displayCurrency,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReached
            ? Colors.green.withValues(alpha: 0.05)
            : AppTheme.primaryOrange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReached
              ? Colors.green.withValues(alpha: 0.2)
              : AppTheme.primaryOrange.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isReached
                      ? Colors.green.withValues(alpha: 0.1)
                      : AppTheme.primaryOrange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isReached ? Icons.check_circle : Icons.delivery_dining,
                  color: isReached ? Colors.green : AppTheme.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isReached
                          ? localizations.freeDeliveryReached
                          : localizations.remainingForFreeDelivery(
                              CurrencyFormatter.format(remaining, currency),
                            ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isReached
                            ? Colors.green[800]
                            : AppTheme.primaryOrange,
                        fontSize: 14,
                      ),
                    ),
                    if (!isReached)
                      Text(
                        localizations.freeDeliveryDescription,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final iconSize = 32.0;
              final iconPosition = (maxWidth * progress) - (iconSize / 2);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background Bar
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Progress Bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    height: 8,
                    width: maxWidth * progress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isReached
                            ? [Colors.green, Colors.greenAccent]
                            : [
                                AppTheme.primaryOrange,
                                AppTheme.primaryOrange.withValues(alpha: 0.7),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isReached
                                      ? Colors.green
                                      : AppTheme.primaryOrange)
                                  .withValues(alpha: 0.3),
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
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: isReached
                              ? Colors.green.withValues(alpha: 0.2)
                              : AppTheme.primaryOrange.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        isReached ? Icons.check_circle : Icons.moped,
                        color: isReached
                            ? Colors.green
                            : AppTheme.primaryOrange,
                        size: 20,
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryOrange, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountSection(AppLocalizations localizations) {
    final cart = Provider.of<CartProvider>(context);
    final hasDiscount =
        cart.selectedCampaign != null || cart.appliedCoupon != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDiscount ? Colors.green : Colors.grey[300]!,
          width: hasDiscount ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const CampaignSelectionBottomSheet(),
          ).then((_) => _calculateOrder());
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hasDiscount
                    ? Colors.green.withValues(alpha: 0.1)
                    : AppTheme.primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasDiscount ? Icons.local_offer : Icons.campaign,
                color: hasDiscount ? Colors.green : AppTheme.primaryOrange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.campaigns,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (cart.selectedCampaign != null)
                    Text(
                      cart.selectedCampaign!.title,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (cart.appliedCoupon != null)
                    Text(
                      '${localizations.couponApplied}: ${cart.appliedCoupon!.code}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      'Mevcut kampanyaları ve kuponları gör',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                ],
              ),
            ),
            if (hasDiscount)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  if (cart.selectedCampaign != null) {
                    cart.removeCampaign();
                  } else {
                    cart.removeCoupon();
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('İndirim kaldırıldı'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  _calculateOrder();
                },
              )
            else
              const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(AppLocalizations localizations) {
    final checkout = Provider.of<CheckoutProvider>(context);
    // If selected address is null but addresses exist, provider should handle it or we show selector
    // Provider init usually handles default selection.

    if (checkout.addresses.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.location_off, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                localizations.noAddressFound,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.pushNamed(context, '/customer/add-address');
                  _checkoutProvider.init();
                },
                icon: const Icon(Icons.add),
                label: Text(localizations.addNewAddress),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (checkout.selectedAddress == null) {
      // If addresses exist but none selected (shouldn't happen with init logic usually)
      // We can show "Select Address" card
      return InkWell(
        onTap: () => _showAddressSelector(localizations),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.add_location),
                const SizedBox(width: 8),
                Text(localizations.selectAddress),
              ],
            ),
          ),
        ),
      );
    }

    final fullAddress =
        checkout.selectedAddress?['fullAddress']?.toString() ??
        checkout.selectedAddress?['FullAddress']?.toString() ??
        '';
    final displayTitle =
        checkout.selectedAddress?['title']?.toString() ??
        checkout.selectedAddress?['Title']?.toString() ??
        'Adres';
    final city =
        checkout.selectedAddress?['city']?.toString() ??
        checkout.selectedAddress?['City']?.toString() ??
        '';
    final district =
        checkout.selectedAddress?['district']?.toString() ??
        checkout.selectedAddress?['District']?.toString() ??
        '';

    return _buildAddressCardContent(
      localizations,
      displayTitle,
      fullAddress,
      city,
      district,
    );
  }

  Widget _buildAddressCardContent(
    AppLocalizations localizations,
    String displayTitle,
    String fullAddress,
    String city,
    String district,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showAddressSelector(localizations),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: AppTheme.primaryOrange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        localizations.deliveryAddress,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 10,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '30-45dk',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$displayTitle ${fullAddress.isNotEmpty ? '- $fullAddress' : ''}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showAddressSelector(AppLocalizations localizations) {
    final checkout = Provider.of<CheckoutProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
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
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.selectAddress,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Address List
              if (checkout.addresses.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.noAddressesYet,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          localizations.addAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: checkout.addresses.length,
                    itemBuilder: (context, index) {
                      final address = checkout.addresses[index];
                      final isSelected =
                          checkout.selectedAddress?['id'] == address['id'];
                      final isDefault = address['isDefault'] == true;

                      // Adres bilgilerini çıkar
                      final addrFullAddress =
                          address['fullAddress']?.toString() ??
                          address['FullAddress']?.toString() ??
                          '';
                      final addrDisplayTitle =
                          address['title']?.toString() ??
                          address['Title']?.toString() ??
                          localizations.address;
                      final addrCity =
                          address['city']?.toString() ??
                          address['City']?.toString() ??
                          '';
                      final addrDistrict =
                          address['district']?.toString() ??
                          address['District']?.toString() ??
                          '';

                      return InkWell(
                        onTap: () {
                          checkout.setSelectedAddress(address);
                          Navigator.pop(context);
                          _calculateOrder();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryOrange.withValues(alpha: 0.1)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryOrange
                                  : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Address Icon
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryOrange.withValues(
                                          alpha: 0.2,
                                        )
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: isSelected
                                      ? AppTheme.primaryOrange
                                      : Colors.grey[600],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Address Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            addrDisplayTitle,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? AppTheme.primaryOrange
                                                  : Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isDefault)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              localizations.defaultLabel,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Full Address
                                    if (addrFullAddress.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          addrFullAddress,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    // District / City
                                    if (addrCity.isNotEmpty ||
                                        addrDistrict.isNotEmpty)
                                      Text(
                                        addrDistrict.isNotEmpty &&
                                                addrCity.isNotEmpty
                                            ? '$addrDistrict / $addrCity'
                                            : addrDistrict.isNotEmpty
                                            ? addrDistrict
                                            : addrCity,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Check Icon
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primaryOrange,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethods(AppLocalizations localizations) {
    final checkout = Provider.of<CheckoutProvider>(context);
    final paymentMethods = _getPaymentMethods(localizations);
    final selectedMethod = paymentMethods.firstWhere(
      (m) => m['value'] == checkout.selectedPaymentMethod,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () =>
            _showPaymentMethodSelector(context, paymentMethods, localizations),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                selectedMethod['icon'] as IconData,
                color: AppTheme.primaryOrange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.paymentMethod,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    selectedMethod['label'] as String,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getPaymentMethods(
    AppLocalizations localizations,
  ) {
    return [
      {
        'value': 'Cash',
        'label': localizations.cash,
        'icon': Icons.money,
        'enabled': true,
        'description': 'Nakit olarak kapıda kuryeye teslim edebilirsiniz.',
      },
      {
        'value': 'CreditCard',
        'label': localizations.creditCard,
        'icon': Icons.credit_card,
        'enabled': false,
        'description': 'Yakında hizmete geçecektir.',
      },
      {
        'value': 'MobilePayment',
        'label': localizations.mobilePayment,
        'icon': Icons.phone_android,
        'enabled': false,
        'description': 'Yakında hizmete geçecektir.',
      },
    ];
  }

  void _showPaymentMethodSelector(
    BuildContext context,
    List<Map<String, dynamic>> paymentMethods,
    AppLocalizations localizations,
  ) {
    // Need listen: false because we are in a callback/dialog building but
    // if it rebuilds its fine. But we access current state.
    // Actually we can pass checkout from parent. Or use context.read in callbacks.
    // But for "isSelected" check inside builder we need valid state.
    // Context here is from builder so we can look up provider.

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Redefine checkout here to listen to changes if selector stays open (unlikely to change from outside)
        // or just read.
        final checkout = Provider.of<CheckoutProvider>(context);

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                localizations.paymentMethod,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...paymentMethods.map((method) {
                final isSelected =
                    checkout.selectedPaymentMethod == method['value'];
                final isEnabled = method['enabled'] as bool;

                return ListTile(
                  enabled: isEnabled,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryOrange.withValues(alpha: 0.1)
                          : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      method['icon'] as IconData,
                      color: isEnabled
                          ? (isSelected
                                ? AppTheme.primaryOrange
                                : Colors.grey[600])
                          : Colors.grey[400],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    method['label'] as String,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isEnabled ? Colors.black87 : Colors.grey[400],
                    ),
                  ),
                  subtitle: method['description'] != null
                      ? Text(
                          method['description'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        )
                      : null,
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryOrange,
                        )
                      : null,
                  onTap: isEnabled
                      ? () {
                          checkout.setPaymentMethod(method['value'] as String);
                          Navigator.pop(context);
                        }
                      : null,
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderSummary(
    AppLocalizations localizations,
    Currency displayCurrency,
    CartProvider cart,
    OrderCalculationResult? calculationResult,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Products
            ...widget.cartItems.values.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.product.name} x${item.quantity}',
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.selectedOptions != null &&
                              item.selectedOptions!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                item.selectedOptions!
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.format(
                        item.totalPrice,
                        item.product.currency,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 24),
            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(localizations.cartSubtotalLabel)),
                Text(
                  CurrencyFormatter.format(
                    calculationResult?.subtotal ?? cart.subtotalAmount,
                    displayCurrency,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Discount
            if (cart.discountAmount > 0 ||
                (calculationResult?.discountAmount ?? 0) > 0 ||
                cart.selectedCampaign != null ||
                cart.appliedCoupon != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      cart.selectedCampaign != null
                          ? cart.selectedCampaign!.title
                          : (cart.appliedCoupon != null
                                ? '${localizations.discountTitle} (${cart.appliedCoupon!.code})'
                                : localizations.discountTitle),
                      style: const TextStyle(color: Colors.green),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '-${CurrencyFormatter.format(calculationResult?.discountAmount ?? cart.discountAmount, displayCurrency)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            // Delivery Fee
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(localizations.cartDeliveryFeeLabel)),
                Text(
                  (calculationResult?.deliveryFee ?? widget.deliveryFee) == 0
                      ? localizations.free
                      : CurrencyFormatter.format(
                          calculationResult?.deliveryFee ?? widget.deliveryFee,
                          displayCurrency,
                        ),
                  style:
                      (calculationResult?.deliveryFee ?? widget.deliveryFee) ==
                          0
                      ? const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        )
                      : null,
                ),
              ],
            ),
            const Divider(height: 24),
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    localizations.cartTotalAmountLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  CurrencyFormatter.format(
                    calculationResult?.totalAmount ??
                        (cart.totalAmount + widget.deliveryFee),
                    displayCurrency,
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderNoteSection(AppLocalizations localizations) {
    final hasNote = _noteController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasNote ? AppTheme.primaryOrange : Colors.grey[300]!,
          width: hasNote ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showOrderNoteBottomSheet(localizations),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.note_alt_outlined,
                color: AppTheme.primaryOrange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.orderNote,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    hasNote
                        ? _noteController.text.trim()
                        : localizations.addOrderNote,
                    style: TextStyle(
                      color: hasNote ? Colors.black87 : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: hasNote ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasNote)
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
                onPressed: () => _showOrderNoteBottomSheet(localizations),
              )
            else
              const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showOrderNoteBottomSheet(AppLocalizations localizations) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final TextEditingController tempController = TextEditingController(
          text: _noteController.text,
        );

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.note_alt_outlined,
                          color: AppTheme.primaryOrange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        localizations.orderNote,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Text Field
                  TextField(
                    controller: tempController,
                    maxLines: 4,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: localizations.enterOrderNoteHint,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _noteController.text = tempController.text;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        localizations.save,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
