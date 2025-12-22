import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/cart/data/models/cart_item.dart';
import 'package:mobile/features/settings/data/models/currency.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/features/orders/presentation/screens/customer/order_success_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/analytics_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/features/home/presentation/widgets/shared_header.dart';
import 'package:mobile/widgets/custom_confirmation_dialog.dart';
import 'package:mobile/features/campaigns/presentation/widgets/campaign_selection_bottom_sheet.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.vendorId,
    required this.subtotal,
    required this.deliveryFee,
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
  final ApiService _apiService = ApiService();
  final TextEditingController _noteController = TextEditingController();

  Map<String, dynamic>? _selectedAddress;
  String _selectedPaymentMethod = 'Cash';
  bool _isLoading = false;
  List<dynamic> _addresses = [];
  bool _isLoadingAddresses = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoadingAddresses = true;
    });

    try {
      final addresses = await _apiService.getAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = addresses;
        // Auto-select default address if available
        Map<String, dynamic>? defaultAddress;
        if (addresses.isNotEmpty) {
          try {
            // Try to find default address (check both lowercase and uppercase)
            final found = addresses.firstWhere(
              (addr) =>
                  addr['isDefault'] == true ||
                  addr['IsDefault'] == true ||
                  addr['isDefault'] == 'true' ||
                  addr['IsDefault'] == 'true',
            );
            defaultAddress = found as Map<String, dynamic>;
          } catch (e) {
            // No default address found, use first address
            defaultAddress = addresses.first as Map<String, dynamic>;
          }
        }
        _selectedAddress = defaultAddress;
        _isLoadingAddresses = false;
        LoggerService().debug(
          'Selected address: ${_selectedAddress?['title'] ?? 'null'}',
        );
      });
    } catch (e) {
      LoggerService().error('Error loading addresses: $e', e);
      setState(() {
        _isLoadingAddresses = false;
      });
    }
  }

  Future<void> _createOrder() async {
    final localizations = AppLocalizations.of(context)!;

    // Validation
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.pleaseSelectAddress),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare order items
      // Prepare order items
      final orderItems = <String, int>{};
      for (final item in widget.cartItems.values) {
        orderItems[item.product.id] = item.quantity;
      }

      // Get delivery address ID as String (GUID)
      final addressId = _selectedAddress!['id'];
      final addressIdString = addressId?.toString();

      // Get coupon code from CartProvider
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final couponCode = cartProvider.appliedCoupon?.code;

      // Create order
      final order = await _apiService.createOrder(
        widget.vendorId,
        orderItems,
        deliveryAddressId: addressIdString,
        paymentMethod: _selectedPaymentMethod,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        couponCode: couponCode,
      );

      // Log purchase
      await AnalyticsService.logPurchase(
        orderId: order.customerOrderId,
        totalAmount: cartProvider.totalAmount + widget.deliveryFee,
        currency: widget.cartItems.values.first.product.currency.code,
        cartItems: widget.cartItems.values.toList(),
        shippingAddress:
            '${_selectedAddress!['city']} / ${_selectedAddress!['district']}',
      );

      // Clear cart
      if (mounted) {
        final cart = Provider.of<CartProvider>(context, listen: false);
        await cart.clear();
      }

      // Navigate to success screen
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
      LoggerService().error('Error creating order: $e', e);
      if (mounted) {
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => CustomConfirmationDialog(
            title: 'Sipariş Oluşturulamadı',
            message: 'Lütfen bilgilerinizi kontrol edip tekrar deneyin.',
            confirmText: localizations.ok,
            cancelText: '', // Not shown when onCancel is null
            icon: Icons.error_outline,
            iconColor: Colors.red,
            confirmButtonColor: AppTheme
                .primaryOrange, // Or red? Keeping consistent with action or error? The original had TextButton 'OK'. Let's use Red for error.
            // Original had TextButton for OK. CustomConfirmationDialog uses ElevatedButton for confirm.
            // Let's use primaryOrange for 'OK' as it is a safe action (dismiss), or Red because it's an error state?
            // The icon is red.
            // Let's use primaryOrange for the button to acknowledge.
            onConfirm: () => Navigator.pop(context),
            content: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                e.toString().replaceAll('Exception: ', ''),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red.shade900,
                  height: 1.4,
                ),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final cart = Provider.of<CartProvider>(context);

    // Get currency from first item, or default to TRY
    final Currency displayCurrency = widget.cartItems.isNotEmpty
        ? widget.cartItems.values.first.product.currency
        : Currency.try_;

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
            child: _isLoadingAddresses
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
                        // Order Information Section Header
                        _buildSectionTitle(
                          localizations.orderInformation,
                          Icons.list_alt,
                        ),
                        const SizedBox(height: 12),

                        // Delivery Address Section
                        _buildAddressCard(localizations),
                        const SizedBox(height: 24),

                        // Payment Method Section
                        Semantics(
                          label: localizations.paymentMethod,
                          explicitChildNodes: true,
                          child: _buildPaymentMethods(localizations),
                        ),
                        const SizedBox(height: 24),

                        // Campaign & Coupon Section
                        _buildDiscountSection(localizations),
                        const SizedBox(height: 24),

                        // Order Note Section
                        _buildOrderNoteSection(localizations),
                        const SizedBox(height: 24),

                        // Order Summary Section
                        _buildSectionTitle(
                          localizations.orderSummary,
                          Icons.receipt,
                        ),
                        const SizedBox(height: 12),
                        _buildOrderSummary(
                          localizations,
                          displayCurrency,
                          cart,
                        ),
                        const SizedBox(height: 24),

                        Semantics(
                          label:
                              '${localizations.confirmOrder}, ${localizations.totalAmount}: ${CurrencyFormatter.format(cart.totalAmount + widget.deliveryFee, displayCurrency)}',
                          button: true,
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _createOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
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
                                              cart.totalAmount +
                                                  widget.deliveryFee,
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
          );
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
                    localizations.campaigns, // Or "Discounts" if available
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
    if (_addresses.isEmpty) {
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
                  // Navigate to add address screen
                  await Navigator.pushNamed(context, '/customer/add-address');
                  _loadAddresses();
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

    // Eğer adres seçilmemişse ve adres listesi varsa, ilk adresi seç
    if (_selectedAddress == null && _addresses.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedAddress = _addresses.first;
        });
      });
      // Geçici olarak ilk adresi göster
      final tempAddress = _addresses.first;
      final fullAddress =
          tempAddress['fullAddress']?.toString() ??
          tempAddress['FullAddress']?.toString() ??
          '';
      final displayTitle =
          tempAddress['title']?.toString() ??
          tempAddress['Title']?.toString() ??
          'Adres';
      final city =
          tempAddress['city']?.toString() ??
          tempAddress['City']?.toString() ??
          '';
      final district =
          tempAddress['district']?.toString() ??
          tempAddress['District']?.toString() ??
          '';
      return _buildAddressCardContent(
        localizations,
        displayTitle,
        fullAddress,
        city,
        district,
      );
    }

    if (_selectedAddress == null) {
      return const SizedBox.shrink();
    }

    final fullAddress =
        _selectedAddress?['fullAddress']?.toString() ??
        _selectedAddress?['FullAddress']?.toString() ??
        '';
    // Başlık için title kullan
    final displayTitle =
        _selectedAddress?['title']?.toString() ??
        _selectedAddress?['Title']?.toString() ??
        'Adres';
    final city =
        _selectedAddress?['city']?.toString() ??
        _selectedAddress?['City']?.toString() ??
        '';
    final district =
        _selectedAddress?['district']?.toString() ??
        _selectedAddress?['District']?.toString() ??
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
                    style: TextStyle(
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
              if (_addresses.isEmpty)
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
                          // AddressesScreen'e yönlendir (eğer route varsa)
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
                    itemCount: _addresses.length,
                    itemBuilder: (context, index) {
                      final address = _addresses[index];
                      final isSelected =
                          _selectedAddress?['id'] == address['id'];
                      final isDefault = address['isDefault'] == true;

                      // Adres bilgilerini çıkar
                      final addrFullAddress =
                          address['fullAddress']?.toString() ??
                          address['FullAddress']?.toString() ??
                          '';
                      // Başlık için title kullan
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
                          setState(() {
                            _selectedAddress = address;
                          });
                          Navigator.pop(context);
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
    final paymentMethods = _getPaymentMethods(localizations);
    final selectedMethod = paymentMethods.firstWhere(
      (m) => m['value'] == _selectedPaymentMethod,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...paymentMethods.map((method) {
              final isSelected = _selectedPaymentMethod == method['value'];
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
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
                        setState(() {
                          _selectedPaymentMethod = method['value'] as String;
                        });
                        Navigator.pop(context);
                      }
                    : null,
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(
    AppLocalizations localizations,
    Currency displayCurrency,
    CartProvider cart,
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
                      child: Text(
                        '${item.product.name} x${item.quantity}',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
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
                    cart.subtotalAmount,
                    displayCurrency,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Discount
            if (cart.discountAmount > 0 ||
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
                    '-${CurrencyFormatter.format(cart.discountAmount, displayCurrency)}',
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
                  CurrencyFormatter.format(widget.deliveryFee, displayCurrency),
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
                    cart.totalAmount + widget.deliveryFee,
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
