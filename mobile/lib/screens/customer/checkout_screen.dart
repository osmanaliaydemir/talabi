import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/cart_item.dart';
import 'package:mobile/models/currency.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/screens/customer/order_success_screen.dart';
import 'package:mobile/services/api_service.dart';
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
        final defaultAddress = addresses.firstWhere(
          (addr) => addr['isDefault'] == true,
          orElse: () => addresses.isNotEmpty ? addresses.first : null,
        );
        _selectedAddress = defaultAddress;
        _isLoadingAddresses = false;
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

                  // Estimated Delivery Time
                  _buildEstimatedDelivery(localizations),
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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryOrange.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and change button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.home, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    Text(
                      _selectedAddress?['title'] ?? '',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton.icon(
                    onPressed: () => _showAddressSelector(localizations),
                    icon: Icon(Icons.edit, size: 16, color: Colors.white),
                    label: Text(
                      localizations.changeAddress,
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade200,
                    Colors.orange.shade100,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            // Full Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Açık Adres',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        _selectedAddress?['addressLine1'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      if (_selectedAddress?['addressLine2'] != null &&
                          _selectedAddress!['addressLine2']
                              .toString()
                              .isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _selectedAddress!['addressLine2'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // City and District
            Row(
              children: [
                Icon(Icons.map, color: AppTheme.primaryOrange, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade100),
                    ),
                    child: Text(
                      '${_selectedAddress?['district'] ?? ''} / ${_selectedAddress?['city'] ?? ''}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
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
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localizations.selectAddress,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ..._addresses.map((address) {
              final isSelected = _selectedAddress?['id'] == address['id'];
              return ListTile(
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: AppTheme.primaryOrange,
                ),
                title: Text(address['title']),
                subtitle: Text(address['addressLine1']),
                onTap: () {
                  setState(() {
                    _selectedAddress = address;
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
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

    return Column(
      children: [
        // Horizontal tabs
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: paymentMethods.length,
            itemBuilder: (context, index) {
              final method = paymentMethods[index];
              final isSelected = _selectedPaymentMethod == method['value'];
              final isEnabled = method['enabled'] as bool;

              return GestureDetector(
                onTap: isEnabled
                    ? () {
                        setState(() {
                          _selectedPaymentMethod = method['value'] as String;
                        });
                      }
                    : null,
                child: Container(
                  width: 90,
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryOrange
                        : (isEnabled ? Colors.white : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryOrange
                          : (isEnabled ? Colors.grey[300]! : Colors.grey[200]!),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryOrange.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        method['icon'] as IconData,
                        size: 24,
                        color: isSelected
                            ? Colors.white
                            : (isEnabled
                                  ? AppTheme.primaryOrange
                                  : Colors.grey[400]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        method['label'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : (isEnabled ? Colors.black87 : Colors.grey[500]),
                        ),
                      ),
                      if (!isEnabled)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            localizations.comingSoon,
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 12),
        // Description card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryOrange, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  paymentMethods.firstWhere(
                        (m) => m['value'] == _selectedPaymentMethod,
                      )['description']
                      as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[800],
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEstimatedDelivery(AppLocalizations localizations) {
    return Card(
      elevation: 2,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.access_time, color: AppTheme.primaryOrange),
            SizedBox(width: 12),
            Text(
              '${localizations.estimatedDelivery}: 30-40 ${localizations.minutes}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                  CurrencyFormatter.format(
                    widget.subtotal,
                    displayCurrency,
                  ),
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
                  CurrencyFormatter.format(
                    widget.deliveryFee,
                    displayCurrency,
                  ),
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
