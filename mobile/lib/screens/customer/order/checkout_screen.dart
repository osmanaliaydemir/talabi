import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/cart_item.dart';
import 'package:mobile/models/currency.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/screens/customer/order/order_success_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/analytics_service.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, CartItem> cartItems;
  final String vendorId;
  final double subtotal;
  final double deliveryFee;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.vendorId,
    required this.subtotal,
    required this.deliveryFee,
  });

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
        print('Selected address: ${_selectedAddress?['title'] ?? 'null'}');
      });
    } catch (e) {
      print('Error loading addresses: $e');
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
      final orderItems = <String, int>{};
      for (var item in widget.cartItems.values) {
        orderItems[item.product.id] = item.quantity;
      }

      // Get delivery address ID as String (GUID)
      final addressId = _selectedAddress!['id'];
      final addressIdString = addressId?.toString();

      // Create order
      final order = await _apiService.createOrder(
        widget.vendorId,
        orderItems,
        deliveryAddressId: addressIdString,
        paymentMethod: _selectedPaymentMethod,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      // Log purchase
      await AnalyticsService.logPurchase(
        orderId: order.customerOrderId,
        totalAmount: widget.subtotal + widget.deliveryFee,
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
      print('Error creating order: $e');
      if (mounted) {
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.error_outline, color: Colors.red, size: 32),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sipariş Oluşturulamadı',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
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
                SizedBox(height: 12),
                Text(
                  'Lütfen bilgilerinizi kontrol edip tekrar deneyin.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Tamam',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
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

    // Get currency from first item, or default to TRY
    final Currency displayCurrency = widget.cartItems.isNotEmpty
        ? widget.cartItems.values.first.product.currency
        : Currency.try_;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(localizations.checkoutTitle),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingAddresses
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryOrange),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Address Section
                  _buildSectionTitle(
                    localizations.deliveryAddress,
                    Icons.location_on,
                  ),
                  SizedBox(height: 12),
                  _buildAddressCard(localizations),
                  SizedBox(height: 12),
                  _buildEstimatedDeliveryCard(localizations),
                  SizedBox(height: 24),

                  // Payment Method Section
                  _buildSectionTitle(
                    localizations.paymentMethod,
                    Icons.payment,
                  ),
                  SizedBox(height: 12),
                  _buildPaymentMethods(localizations),
                  SizedBox(height: 24),

                  // Order Note Section
                  _buildSectionTitle(localizations.orderNote, Icons.note),
                  SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: localizations.orderNotePlaceholder,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 24),

                  // Order Summary Section
                  _buildSectionTitle(localizations.orderSummary, Icons.receipt),
                  SizedBox(height: 12),
                  _buildOrderSummary(localizations, displayCurrency),
                  SizedBox(height: 24),

                  // Confirm Order Button
                  SizedBox(
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
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  localizations.confirmOrder,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  CurrencyFormatter.format(
                                    widget.subtotal + widget.deliveryFee,
                                    displayCurrency,
                                  ),
                                  style: TextStyle(
                                    fontSize: 18,
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
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryOrange, size: 24),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
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
              Icon(Icons.location_off, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                localizations.noAddressFound,
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  // Navigate to add address screen
                  await Navigator.pushNamed(context, '/customer/add-address');
                  _loadAddresses();
                },
                icon: Icon(Icons.add),
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
      return SizedBox.shrink();
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon, title and change button
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: AppTheme.primaryOrange,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.deliveryAddress,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        displayTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showAddressSelector(localizations),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppTheme.primaryOrange,
                      ),
                      SizedBox(width: 4),
                      Text(
                        localizations.changeAddress,
                        style: TextStyle(
                          color: AppTheme.primaryOrange,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Full Address
            if (fullAddress.isNotEmpty) ...[
              SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey[200]),
              SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.home_outlined, size: 18, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fullAddress,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // City and District bilgileri (varsa)
            if ((city.isNotEmpty || district.isNotEmpty) &&
                fullAddress.isNotEmpty)
              SizedBox(height: 8),
            if (city.isNotEmpty || district.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.location_city_outlined,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 8),
                  Text(
                    district.isNotEmpty && city.isNotEmpty
                        ? '$district / $city'
                        : district.isNotEmpty
                        ? district
                        : city,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
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
          decoration: BoxDecoration(
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
                margin: EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.selectAddress,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Address List
              if (_addresses.isEmpty)
                Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        localizations.noAddressesYet,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // AddressesScreen'e yönlendir (eğer route varsa)
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          localizations.addAddress,
                          style: TextStyle(
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
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          padding: EdgeInsets.all(16),
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
                              SizedBox(width: 16),
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
                                            padding: EdgeInsets.symmetric(
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
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    // Full Address
                                    if (addrFullAddress.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 4),
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
                                Icon(
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
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethods(AppLocalizations localizations) {
    final paymentMethods = [
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

    final selectedMethod = paymentMethods.firstWhere(
      (m) => m['value'] == _selectedPaymentMethod,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected payment method display
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    selectedMethod['icon'] as IconData,
                    color: AppTheme.primaryOrange,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.paymentMethod,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        selectedMethod['label'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Payment method options
            SizedBox(height: 16),
            ...paymentMethods.where((m) => m['enabled'] == true).map((method) {
              final isSelected = _selectedPaymentMethod == method['value'];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = method['value'] as String;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryOrange.withValues(alpha: 0.05)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryOrange
                          : Colors.grey[200]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        method['icon'] as IconData,
                        color: isSelected
                            ? AppTheme.primaryOrange
                            : Colors.grey[600],
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          method['label'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.primaryOrange
                                : Colors.black87,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryOrange,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),
            // Description (if available and enabled)
            if (selectedMethod['enabled'] == true &&
                selectedMethod['description'] != null)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedMethod['description'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimatedDeliveryCard(AppLocalizations localizations) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.access_time,
                color: AppTheme.primaryOrange,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.estimatedDelivery,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '30-40 ${localizations.minutes}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(
    AppLocalizations localizations,
    Currency displayCurrency,
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
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(
                        item.totalPrice,
                        item.product.currency,
                      ),
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }),
            Divider(height: 24),
            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(localizations.cartSubtotalLabel),
                Text(
                  CurrencyFormatter.format(widget.subtotal, displayCurrency),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Delivery Fee
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(localizations.cartDeliveryFeeLabel),
                Text(
                  CurrencyFormatter.format(widget.deliveryFee, displayCurrency),
                ),
              ],
            ),
            Divider(height: 24),
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.cartTotalAmountLabel,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  CurrencyFormatter.format(
                    widget.subtotal + widget.deliveryFee,
                    displayCurrency,
                  ),
                  style: TextStyle(
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
}
