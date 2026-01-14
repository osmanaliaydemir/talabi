import 'package:flutter/material.dart';
import 'package:mobile/features/orders/data/models/order_calculation_models.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/services/analytics_service.dart';
import 'package:mobile/features/cart/data/models/cart_item.dart';

class CheckoutProvider extends ChangeNotifier {
  CheckoutProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  // State
  bool _isLoading = false;
  bool _isCalculating = false;
  OrderCalculationResult? _calculationResult;
  String? _calculationError;
  List<dynamic> _addresses = [];
  bool _isLoadingAddresses = true;
  Map<String, dynamic>? _selectedAddress;
  String _selectedPaymentMethod = 'Cash';
  bool _acceptedDistanceSales = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get isCalculating => _isCalculating;
  OrderCalculationResult? get calculationResult => _calculationResult;
  String? get calculationError => _calculationError;
  List<dynamic> get addresses => _addresses;
  bool get isLoadingAddresses => _isLoadingAddresses;
  Map<String, dynamic>? get selectedAddress => _selectedAddress;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  bool get acceptedDistanceSales => _acceptedDistanceSales;

  // Computed
  double? get totalAmount => _calculationResult?.totalAmount;

  // Setters
  void setPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  void setAcceptedDistanceSales(bool value) {
    _acceptedDistanceSales = value;
    notifyListeners();
  }

  void setSelectedAddress(Map<String, dynamic>? address) {
    _selectedAddress = address;
    notifyListeners();
    // Re-calculate when address changes
  }

  // Methods
  Future<void> init() async {
    await _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    _isLoadingAddresses = true;
    notifyListeners();

    try {
      final addresses = await _apiService.getAddresses();
      _addresses = addresses;

      // Auto-select default address
      if (_addresses.isNotEmpty) {
        Map<String, dynamic>? defaultAddress;
        try {
          defaultAddress =
              _addresses.firstWhere(
                    (addr) =>
                        addr['isDefault'] == true ||
                        addr['IsDefault'] == true ||
                        addr['isDefault'] == 'true' ||
                        addr['IsDefault'] == 'true',
                    orElse: () => _addresses.first,
                  )
                  as Map<String, dynamic>;
        } catch (_) {
          defaultAddress = _addresses.first as Map<String, dynamic>;
        }
        _selectedAddress = defaultAddress;
      }
    } catch (e) {
      LoggerService().error('Error loading addresses in CheckoutProvider', e);
    } finally {
      _isLoadingAddresses = false;
      notifyListeners();
    }
  }

  Future<void> calculateOrder({
    required String vendorId,
    required Map<String, CartItem> cartItems,
    String? couponCode,
    String? campaignId,
  }) async {
    _isCalculating = true;
    _calculationError = null;
    notifyListeners();

    try {
      final items = cartItems.entries
          .map(
            (e) => OrderItemDto(
              productId: e.value.product.id,
              quantity: e.value.quantity,
              selectedOptions: e.value.selectedOptions,
            ),
          )
          .toList();

      final request = CalculateOrderRequest(
        vendorId: vendorId,
        items: items,
        deliveryAddressId: _selectedAddress?['id']?.toString(),
        couponCode: couponCode,
        campaignId: campaignId,
      );

      final result = await _apiService.calculateOrder(request);
      _calculationResult = result;
    } catch (e) {
      LoggerService().error('Order calculation failed', e);
      _calculationError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isCalculating = false;
      notifyListeners();
    }
  }

  Future<dynamic> createOrder({
    required String vendorId,
    required Map<String, CartItem> items,
    required double defaultTotal, // Fallback total if calculation missing
    String? note,
    String? couponCode,
    String? campaignId,
    required String currencyCode,
  }) async {
    if (_selectedAddress == null) {
      throw Exception('Lütfen bir teslimat adresi seçin.');
    } // Localized strings should be handled in UI, throwing generic message here or specific exception

    if (!_acceptedDistanceSales) {
      throw Exception('Lütfen mesafeli satış sözleşmesini onaylayın.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final orderItems = <Map<String, dynamic>>[];
      for (final item in items.values) {
        final Map<String, dynamic> itemData = {
          'productId': item.product.id,
          'quantity': item.quantity,
        };
        if (item.selectedOptions != null) {
          itemData['selectedOptions'] = item.selectedOptions;
        }
        orderItems.add(itemData);
      }

      final addressId = _selectedAddress!['id']?.toString();

      final order = await _apiService.createOrder(
        vendorId,
        orderItems,
        deliveryAddressId: addressId,
        paymentMethod: _selectedPaymentMethod,
        note: note,
        couponCode: couponCode,
        campaignId: campaignId,
      );

      // Analytics
      await AnalyticsService.logPurchase(
        orderId: order.customerOrderId,
        totalAmount: _calculationResult?.totalAmount ?? defaultTotal,
        currency: currencyCode,
        cartItems: items.values.toList(),
        shippingAddress:
            '${_selectedAddress!['city']} / ${_selectedAddress!['district']}',
      );

      return order;
    } catch (e) {
      LoggerService().error('Error creating order', e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
